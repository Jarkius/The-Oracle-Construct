/**
 * Memory System Routes
 *
 * SQLite stats, ChromaDB health, embedding config, and dashboard overview.
 */

import { Hono } from "hono";
import { db, DB_PATH } from "../../../core/db/core";
import { getEmbeddingConfig } from "../../../memory/embeddings";
import { getDashboardData } from "../../../core/db/analytics";

const CHROMADB_PORT = Number(process.env.CHROMADB_PORT) || 8100;

const app = new Hono();

// GET /sqlite — SQLite database stats
app.get("/sqlite", async (c) => {
  try {
    const tables = db
      .query<{ name: string }, []>("SELECT name FROM sqlite_master WHERE type='table'")
      .all();

    const tableStats: Record<string, number> = {};
    for (const { name } of tables) {
      // Safety: table names from sqlite_master are safe, but avoid injection via parameterized queries
      const row = db.query<{ count: number }, []>(`SELECT COUNT(*) as count FROM "${name}"`).get();
      tableStats[name] = row?.count ?? 0;
    }

    let fileSize = 0;
    try {
      fileSize = Bun.file(DB_PATH).size;
    } catch {}

    const pageCount = db.query<{ page_count: number }, []>("PRAGMA page_count").get();
    const pageSize = db.query<{ page_size: number }, []>("PRAGMA page_size").get();

    return c.json({
      path: DB_PATH,
      fileSize,
      pageCount: pageCount?.page_count ?? 0,
      pageSize: pageSize?.page_size ?? 0,
      tables: tableStats,
    });
  } catch (e) {
    return c.json({ error: String(e) }, 500);
  }
});

// GET /chromadb — ChromaDB vector database health
app.get("/chromadb", async (c) => {
  if (process.env.SKIP_VECTORDB) {
    return c.json({ status: "disabled" });
  }
  try {
    const res = await fetch(`http://localhost:${CHROMADB_PORT}/api/v2/heartbeat`, {
      signal: AbortSignal.timeout(3000),
    });
    if (!res.ok) {
      return c.json({ status: "unhealthy", code: res.status });
    }
    const data = await res.json();
    return c.json({ status: "healthy", port: CHROMADB_PORT, ...data });
  } catch (e) {
    return c.json({ status: "unreachable", port: CHROMADB_PORT, error: String(e) });
  }
});

// GET /embeddings — Embedding model configuration
app.get("/embeddings", async (c) => {
  try {
    const cfg = getEmbeddingConfig();
    return c.json(cfg);
  } catch (e) {
    return c.json({ error: String(e) }, 500);
  }
});

// GET /overview — Full dashboard data
app.get("/overview", async (c) => {
  try {
    const data = getDashboardData();
    return c.json(data);
  } catch (e) {
    return c.json({ error: String(e) }, 500);
  }
});

// POST /reindex — Trigger memory reindex
app.post("/reindex", async (c) => {
  try {
    const proc = Bun.spawn(["bun", "memory", "reindex"], {
      stdout: "pipe", stderr: "pipe", cwd: process.cwd(),
    });
    const [stdout, stderr] = await Promise.all([
      new Response(proc.stdout).text(),
      new Response(proc.stderr).text(),
    ]);
    const exitCode = await proc.exited;
    return c.json({ action: "reindex", exitCode, stdout: stdout.trim(), stderr: stderr.trim() });
  } catch (e) {
    return c.json({ error: String(e) }, 500);
  }
});

// POST /export — Export memory database
app.post("/export", async (c) => {
  try {
    const proc = Bun.spawn(["bun", "memory", "export-md"], {
      stdout: "pipe", stderr: "pipe", cwd: process.cwd(),
    });
    const [stdout, stderr] = await Promise.all([
      new Response(proc.stdout).text(),
      new Response(proc.stderr).text(),
    ]);
    const exitCode = await proc.exited;
    return c.json({ action: "export", exitCode, stdout: stdout.trim(), stderr: stderr.trim() });
  } catch (e) {
    return c.json({ error: String(e) }, 500);
  }
});

// POST /vacuum — Vacuum SQLite database
app.post("/vacuum", async (c) => {
  try {
    db.run("VACUUM");
    let fileSize = 0;
    try { fileSize = Bun.file(DB_PATH).size; } catch {}
    return c.json({ action: "vacuum", success: true, newSize: fileSize });
  } catch (e) {
    return c.json({ error: String(e) }, 500);
  }
});

export default app;
