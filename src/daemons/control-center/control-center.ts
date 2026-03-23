#!/usr/bin/env bun
/**
 * Matrix Control Center v2 — System Dashboard
 *
 * Hono HTTP dashboard with modular routes, HTMX partials, and SSE streaming.
 * Monitors Matrix daemons, PULSE events, memory systems, and Nerve escalation.
 *
 * http://localhost:8180 (configurable via CONTROL_PORT)
 */

import { Hono } from "hono";
import { readFile } from "node:fs/promises";
import { join } from "node:path";
import type { Supervisor } from "../../nerve/supervisor";
import { PROJECT_ROOT } from "../../core/paths";

// Route modules
import daemonRoutes, { DAEMONS, checkDaemonStatus } from "./routes/daemons";
import memoryRoutes from "./routes/memory";
import logRoutes from "./routes/logs";
import streamRoutes from "./routes/stream";
import configRoutes from "./routes/config";

// Views
import { dashboardPage } from "./views/dashboard";
import { memoryPage } from "./views/memory";
import { servicesPage } from "./views/services";
import { logsPage } from "./views/logs";

// Partials
import { renderDaemonCards, renderDaemonSummary, renderSingleStat, renderMemoryOverview } from "./partials/daemon-card";
import { renderSqliteStats, renderChromaStats, renderEmbeddingInfo, renderPlatformInfo } from "./partials/memory-stats";
import { renderLogLines } from "./partials/log-viewer";

// DB access for partials
import { db, DB_PATH } from "../../core/db/core";
import { getDashboardData } from "../../core/db/analytics";
import { getEmbeddingConfig } from "../../memory/embeddings";

const PORT = Number(process.env.CONTROL_PORT) || 8180;
const CWD = PROJECT_ROOT;
const EVENTS_PATH = join(CWD, "psi/state/pulse/events.jsonl");
const TASKS_PATH = join(CWD, "psi/memory/tasks/active.json");
const ERRORS_PATH = join(CWD, "psi/state/pulse/memory-errors.log");
const DAEMON_LOGS_DIR = join(CWD, "psi/state/pulse/daemon-logs");
const CHROMADB_PORT = Number(process.env.CHROMADB_PORT) || 8100;

const app = new Hono();

// Optional Nerve supervisor integration
let nerveSupervisor: Supervisor | null = null;

export function wireNerve(supervisor: Supervisor): void {
  nerveSupervisor = supervisor;
}

// ─── Helper ─────────────────────────────────────────────────────────────────

async function readJsonOr<T>(path: string, fallback: T): Promise<T> {
  try { return JSON.parse(await readFile(path, "utf-8")); } catch { return fallback; }
}

function formatBytes(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(2)} MB`;
}

// ─── Static files ───────────────────────────────────────────────────────────

app.get("/static/:file", async (c) => {
  const file = c.req.param("file");
  if (!/^[a-z0-9._-]+\.(js|css)$/i.test(file)) {
    return c.text("Not found", 404);
  }
  const filePath = join(import.meta.dir, "static", file);
  try {
    const content = await readFile(filePath, "utf-8");
    const ct = file.endsWith(".js") ? "application/javascript" : "text/css";
    return c.text(content, 200, { "Content-Type": ct, "Cache-Control": "public, max-age=86400" });
  } catch {
    return c.text("Not found", 404);
  }
});

// ─── API Routes (modular) ───────────────────────────────────────────────────

app.route("/api/daemons", daemonRoutes);
app.route("/api/memory", memoryRoutes);
app.route("/api/logs", logRoutes);
app.route("/api/stream", streamRoutes);
app.route("/api/config", configRoutes);

// Legacy API compatibility (old dashboard clients)
app.get("/api/status", async (c) => {
  const results = await Promise.all(DAEMONS.map(checkDaemonStatus));
  const statuses: Record<string, any> = {};
  for (const r of results) {
    statuses[r.name] = { running: r.running, port: r.port };
  }
  const tasks = await readJsonOr<any>(TASKS_PATH, { tasks: [] });
  let eventCount = 0;
  try {
    const text = await readFile(EVENTS_PATH, "utf-8");
    eventCount = text.trim().split("\n").filter(Boolean).length;
  } catch {}
  return c.json({
    timestamp: new Date().toISOString(),
    matrix: "The Oracle Construct",
    daemons: statuses,
    events: eventCount,
    tasks: { pending: tasks.tasks?.filter((t: any) => t.status === "pending").length ?? 0, total: tasks.tasks?.length ?? 0 },
  });
});

// ChromaDB toggle — enable/disable vector search at runtime
app.post("/api/vectordb/toggle", async (c) => {
  const current = process.env.SKIP_VECTORDB === "true";
  if (current) {
    delete process.env.SKIP_VECTORDB;
    return c.json({ vectordb: "enabled", message: "ChromaDB enabled. Will attempt connection on next request." });
  } else {
    process.env.SKIP_VECTORDB = "true";
    return c.json({ vectordb: "disabled", message: "ChromaDB disabled. Semantic search skipped." });
  }
});

app.get("/api/vectordb/status", async (c) => {
  const skip = process.env.SKIP_VECTORDB === "true";
  if (skip) {
    return c.json({ status: "disabled", skip: true });
  }
  try {
    const res = await fetch(`http://localhost:${CHROMADB_PORT}/api/v2/heartbeat`, { signal: AbortSignal.timeout(3000) });
    return c.json({ status: res.ok ? "connected" : "unreachable", skip: false, port: CHROMADB_PORT });
  } catch {
    return c.json({ status: "unreachable", skip: false, port: CHROMADB_PORT });
  }
});

// Nerve live endpoint
app.get("/api/nerve/live", async (c) => {
  if (!nerveSupervisor) {
    return c.json({ status: "not-wired", message: "Nerve supervisor not connected" });
  }
  return c.json({
    daemons: nerveSupervisor.getStatus(),
    l4Usage: nerveSupervisor.getL4Usage(),
    fixes: nerveSupervisor.getFixStats(),
  });
});

// ─── HTMX Partials ─────────────────────────────────────────────────────────

// Daemon cards — shared by dashboard and services page
app.get("/partials/daemon-cards", async (c) => {
  const daemonInfo = await Promise.all(DAEMONS.map(checkDaemonStatus));
  return c.html(renderDaemonCards(daemonInfo));
});

// Compact daemon summary for dashboard
app.get("/partials/daemon-summary", async (c) => {
  const daemonInfo = await Promise.all(DAEMONS.map(checkDaemonStatus));
  return c.html(renderDaemonSummary(daemonInfo));
});

// Alias for services page
app.get("/partials/service-cards", async (c) => {
  const daemonInfo = await Promise.all(DAEMONS.map(checkDaemonStatus));
  return c.html(renderDaemonCards(daemonInfo));
});

// Quick stats per metric
app.get("/partials/quick-stats", async (c) => {
  const metric = c.req.query("metric") || "events";
  try {
    if (metric === "events") {
      let count = 0;
      try {
        const text = await readFile(EVENTS_PATH, "utf-8");
        count = text.trim().split("\n").filter(Boolean).length;
      } catch {}
      return c.html(renderSingleStat(count));
    }
    if (metric === "pendingTasks") {
      const tasks = await readJsonOr<any>(TASKS_PATH, { tasks: [] });
      const pending = tasks.tasks?.filter((t: any) => t.status === "pending").length ?? 0;
      return c.html(renderSingleStat(pending, pending > 5));
    }
    if (metric === "sessions" || metric === "learnings") {
      try {
        const table = metric === "sessions" ? "sessions" : "learnings";
        const row = db.query<{ count: number }, []>(`SELECT COUNT(*) as count FROM ${table}`).get();
        return c.html(renderSingleStat(row?.count ?? 0));
      } catch {
        return c.html(renderSingleStat(0));
      }
    }
    return c.html(renderSingleStat("-"));
  } catch {
    return c.html(renderSingleStat("?"));
  }
});

// Memory overview for dashboard
app.get("/partials/memory-overview", async (c) => {
  let sqliteSize = "unknown";
  try {
    sqliteSize = formatBytes(Bun.file(DB_PATH).size);
  } catch {}

  let chromaStatus = "disconnected";
  if (process.env.SKIP_VECTORDB) {
    chromaStatus = "skipped";
  } else {
    try {
      const res = await fetch(`http://localhost:${CHROMADB_PORT}/api/v2/heartbeat`, { signal: AbortSignal.timeout(3000) });
      if (res.ok) chromaStatus = "connected";
    } catch {}
  }

  let embeddingModel = "unknown";
  try {
    const cfg = getEmbeddingConfig();
    embeddingModel = cfg.model || cfg.modelId || "bge-m3";
  } catch {}

  return c.html(renderMemoryOverview({ sqliteSize, chromaStatus, embeddingModel }));
});

// SQLite stats for memory page
app.get("/partials/sqlite-stats", async (c) => {
  try {
    const tables = db.query<{ name: string }, []>("SELECT name FROM sqlite_master WHERE type='table'").all();
    const tableData = tables.map(({ name }) => {
      const row = db.query<{ count: number }, []>(`SELECT COUNT(*) as count FROM "${name}"`).get();
      return { name, count: row?.count ?? 0 };
    }).sort((a, b) => b.count - a.count);
    let fileSize = 0;
    try { fileSize = Bun.file(DB_PATH).size; } catch {}
    return c.html(renderSqliteStats(tableData, fileSize));
  } catch (e) {
    return c.html(`<div style="color: #ff4444;">Error: ${String(e)}</div>`);
  }
});

// ChromaDB stats for memory page
app.get("/partials/chromadb-stats", async (c) => {
  if (process.env.SKIP_VECTORDB) {
    return c.html(renderChromaStats("skipped"));
  }
  try {
    const res = await fetch(`http://localhost:${CHROMADB_PORT}/api/v2/heartbeat`, { signal: AbortSignal.timeout(3000) });
    if (!res.ok) return c.html(renderChromaStats("disconnected"));
    return c.html(renderChromaStats("connected"));
  } catch {
    return c.html(renderChromaStats("disconnected"));
  }
});

// Embedding info for memory page
app.get("/partials/embedding-info", async (c) => {
  try {
    const cfg = getEmbeddingConfig();
    return c.html(renderEmbeddingInfo({
      model: cfg.model || cfg.modelId || "bge-m3",
      dimensions: cfg.dimensions ?? 1024,
      batchSize: cfg.batchSize ?? 32,
    }));
  } catch (e) {
    return c.html(`<div style="color: #888;">Embedding config unavailable: ${String(e)}</div>`);
  }
});

// Platform info for memory page
app.get("/partials/platform-info", async (c) => {
  let python3 = "not found";
  try {
    const proc = Bun.spawn(["python3", "--version"], { stdout: "pipe", stderr: "pipe" });
    const out = await new Response(proc.stdout).text();
    const code = await proc.exited;
    if (code === 0) python3 = out.trim();
  } catch {}

  let sharp = "not found";
  try {
    await import("sharp");
    sharp = "installed";
  } catch {}

  return c.html(renderPlatformInfo({
    os: process.platform,
    arch: process.arch,
    bun: Bun.version,
    python3,
    sharp,
    chromaSkip: !!process.env.SKIP_VECTORDB,
  }));
});

// Nerve summary for services page
app.get("/partials/nerve-summary", async (c) => {
  if (!nerveSupervisor) {
    return c.html('<div style="color: #555;">Nerve supervisor not wired. Start via matrix-services.</div>');
  }
  try {
    const status = nerveSupervisor.getStatus();
    const l4 = nerveSupervisor.getL4Usage();
    const fixes = nerveSupervisor.getFixStats();
    const html = `
      <div style="display: flex; flex-direction: column; gap: 8px;">
        <div style="display: flex; justify-content: space-between;">
          <span style="color: #888;">L4 Usage Today</span>
          <span>${l4?.used ?? 0} / ${l4?.limit ?? 0}</span>
        </div>
        <div style="display: flex; justify-content: space-between;">
          <span style="color: #888;">Known Fixes Applied</span>
          <span>${fixes?.totalApplied ?? 0}</span>
        </div>
        <div style="display: flex; justify-content: space-between;">
          <span style="color: #888;">Active Daemons Monitored</span>
          <span>${Object.keys(status || {}).length}</span>
        </div>
      </div>`;
    return c.html(html);
  } catch (e) {
    return c.html(`<div style="color: #ff4444;">Nerve error: ${String(e)}</div>`);
  }
});

// Log viewer partial for logs page
app.get("/partials/logs", async (c) => {
  const source = c.req.query("source") || "events";
  const lines = Math.min(Number(c.req.query("lines")) || 100, 1000);

  try {
    if (source === "events") {
      const text = await readFile(EVENTS_PATH, "utf-8").catch(() => "");
      const rawLines = text.trim().split("\n").filter(Boolean).slice(-lines);
      const formatted = rawLines.map((line) => {
        try {
          const e = JSON.parse(line);
          const ts = e.ts?.slice(0, 19) || "";
          return `${ts} [${e.type}] ${e.agent || ""} ${JSON.stringify(e.data || {})}`;
        } catch {
          return line;
        }
      });
      return c.html(renderLogLines(formatted.reverse()));
    }

    if (source === "memory-errors") {
      const text = await readFile(ERRORS_PATH, "utf-8").catch(() => "");
      const logLines = text.trim().split("\n").filter(Boolean).slice(-lines);
      return c.html(renderLogLines(logLines.reverse()));
    }

    // Daemon-specific logs
    if (/^[a-z0-9_-]+$/i.test(source)) {
      const logFile = join(DAEMON_LOGS_DIR, `${source}.log`);
      const text = await readFile(logFile, "utf-8").catch(() => "");
      const logLines = text.trim().split("\n").filter(Boolean).slice(-lines);
      return c.html(renderLogLines(logLines.reverse()));
    }

    return c.html('<div style="color: #ff4444;">Invalid source</div>');
  } catch (e) {
    return c.html(`<div style="color: #ff4444;">Error: ${String(e)}</div>`);
  }
});

// ─── Page Routes (HTML views) ───────────────────────────────────────────────

app.get("/", (c) => c.html(dashboardPage()));
app.get("/memory", (c) => c.html(memoryPage()));
app.get("/services", (c) => c.html(servicesPage()));
app.get("/logs", (c) => c.html(logsPage()));

// ─── Start ──────────────────────────────────────────────────────────────────

export default {
  port: PORT,
  hostname: "127.0.0.1", // Localhost only — no network exposure
  fetch: app.fetch,
};

console.log(`Matrix Control Center v2 running at http://localhost:${PORT}`);
