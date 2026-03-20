/**
 * Log Viewing Routes
 *
 * Read error logs, PULSE events, and per-daemon log files.
 */

import { Hono } from "hono";
import { readFile } from "node:fs/promises";
import { join } from "node:path";
import { PROJECT_ROOT } from "../../../core/paths";

const CWD = PROJECT_ROOT;
const ERRORS_PATH = join(CWD, "psi/state/pulse/memory-errors.log");
const EVENTS_PATH = join(CWD, "psi/state/pulse/events.jsonl");
const DAEMON_LOGS_DIR = join(CWD, "psi/state/pulse/daemon-logs");

/**
 * Tail the last N lines from text content.
 */
function tailLines(text: string, n: number): string[] {
  const lines = text.split("\n").filter(Boolean);
  return lines.slice(-n);
}

/**
 * Match a glob-style pattern (supports trailing * only, e.g. "nerve:*").
 */
function globMatch(pattern: string, value: string): boolean {
  if (pattern.endsWith("*")) {
    return value.startsWith(pattern.slice(0, -1));
  }
  return value === pattern;
}

const app = new Hono();

// GET /errors — Memory error log, tailed
app.get("/errors", async (c) => {
  const limit = Math.min(Number(c.req.query("lines")) || 100, 1000);
  const search = c.req.query("search")?.toLowerCase();

  try {
    const text = await readFile(ERRORS_PATH, "utf-8");
    let lines = tailLines(text, limit);
    if (search) {
      lines = lines.filter((l) => l.toLowerCase().includes(search));
    }
    return c.json({ file: ERRORS_PATH, lines, count: lines.length });
  } catch (e: any) {
    if (e?.code === "ENOENT") {
      return c.json({ file: ERRORS_PATH, lines: [], count: 0, note: "Log file not found" });
    }
    return c.json({ error: String(e) }, 500);
  }
});

// GET /events — PULSE events, parsed JSONL
app.get("/events", async (c) => {
  const limit = Math.min(Number(c.req.query("limit")) || 50, 500);
  const typeFilter = c.req.query("type");

  try {
    const text = await readFile(EVENTS_PATH, "utf-8");
    const rawLines = text.trim().split("\n").filter(Boolean);

    let events: any[] = [];
    for (const line of rawLines) {
      try {
        const parsed = JSON.parse(line);
        if (typeFilter && !globMatch(typeFilter, parsed.type ?? "")) {
          continue;
        }
        events.push(parsed);
      } catch {
        // Skip malformed lines
      }
    }

    // Most recent first, limited
    events = events.slice(-limit).reverse();

    return c.json({ events, count: events.length });
  } catch (e: any) {
    if (e?.code === "ENOENT") {
      return c.json({ events: [], count: 0, note: "Events file not found" });
    }
    return c.json({ error: String(e) }, 500);
  }
});

// GET /daemon/:name — Per-daemon log file
app.get("/daemon/:name", async (c) => {
  const name = c.req.param("name");
  const limit = Math.min(Number(c.req.query("lines")) || 100, 1000);

  // Validate name to prevent path traversal
  if (!/^[a-z0-9_-]+$/i.test(name)) {
    return c.json({ error: "Invalid daemon name" }, 400);
  }

  const logFile = join(DAEMON_LOGS_DIR, `${name}.log`);

  try {
    const text = await readFile(logFile, "utf-8");
    const lines = tailLines(text, limit);
    return c.json({ daemon: name, lines, count: lines.length });
  } catch (e: any) {
    if (e?.code === "ENOENT") {
      return c.json({ daemon: name, lines: [], count: 0, note: "No log file" });
    }
    return c.json({ error: String(e) }, 500);
  }
});

export default app;
