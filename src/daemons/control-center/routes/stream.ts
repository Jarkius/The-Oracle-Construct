/**
 * SSE Streaming Routes
 *
 * Real-time daemon status, event tailing, and per-daemon log streams.
 */

import { Hono } from "hono";
import { streamSSE } from "hono/streaming";
import { readFile, stat } from "node:fs/promises";
import { join } from "node:path";
import { DAEMONS } from "./daemons";
import { PROJECT_ROOT } from "../../../core/paths";

const CWD = PROJECT_ROOT;
const EVENTS_PATH = join(CWD, "psi/state/pulse/events.jsonl");
const DAEMON_LOGS_DIR = join(CWD, "psi/state/pulse/daemon-logs");

const STATUS_POLL_MS = 5000;
const EVENTS_POLL_MS = 2000;
const LOGS_POLL_MS = 2000;

async function checkAllDaemons() {
  const statuses: Record<string, { running: boolean; port: number }> = {};
  for (const d of DAEMONS) {
    if (d.hasHttp && d.port > 0) {
      try {
        const res = await fetch(`http://localhost:${d.port}/status`, {
          signal: AbortSignal.timeout(3000),
        });
        statuses[d.name] = { running: res.ok, port: d.port };
      } catch {
        statuses[d.name] = { running: false, port: d.port };
      }
    } else {
      statuses[d.name] = { running: false, port: d.port };
    }
  }
  return statuses;
}

async function getFileSize(path: string): Promise<number> {
  try {
    const s = await stat(path);
    return s.size;
  } catch {
    return 0;
  }
}

const app = new Hono();

// GET /status — SSE stream of daemon health, polled every 5s
app.get("/status", (c) => {
  return streamSSE(c, async (stream) => {
    let id = 0;
    while (true) {
      try {
        const statuses = await checkAllDaemons();
        await stream.writeSSE({
          data: JSON.stringify(statuses),
          event: "daemon-update",
          id: String(id++),
        });
      } catch {
        // Connection may have closed
        break;
      }
      await stream.sleep(STATUS_POLL_MS);
    }
  });
});

// GET /events — SSE stream watching events.jsonl for new lines
app.get("/events", (c) => {
  return streamSSE(c, async (stream) => {
    let lastSize = await getFileSize(EVENTS_PATH);
    let id = 0;

    while (true) {
      try {
        const currentSize = await getFileSize(EVENTS_PATH);

        if (currentSize > lastSize) {
          // Read the full file and extract new content
          const text = await readFile(EVENTS_PATH, "utf-8");
          const allBytes = Buffer.byteLength(text, "utf-8");
          // Approximate: read from lastSize offset
          const newContent = text.substring(
            text.length - (allBytes - lastSize > 0 ? Math.ceil((allBytes - lastSize) / 1) : 0),
          );
          const newLines = newContent.trim().split("\n").filter(Boolean);

          for (const line of newLines) {
            try {
              JSON.parse(line); // Validate it's JSON
              await stream.writeSSE({
                data: line,
                event: "new-event",
                id: String(id++),
              });
            } catch {
              // Skip malformed
            }
          }
          lastSize = currentSize;
        } else if (currentSize < lastSize) {
          // File was truncated/rotated
          lastSize = currentSize;
        }
      } catch {
        break;
      }
      await stream.sleep(EVENTS_POLL_MS);
    }
  });
});

// GET /logs/:name — SSE stream for live daemon log tailing
app.get("/logs/:name", (c) => {
  const name = c.req.param("name");

  // Validate name to prevent path traversal
  if (!/^[a-z0-9_-]+$/i.test(name)) {
    return c.json({ error: "Invalid daemon name" }, 400);
  }

  const logFile = join(DAEMON_LOGS_DIR, `${name}.log`);

  return streamSSE(c, async (stream) => {
    let lastSize = await getFileSize(logFile);
    let id = 0;

    while (true) {
      try {
        const currentSize = await getFileSize(logFile);

        if (currentSize > lastSize) {
          const text = await readFile(logFile, "utf-8");
          const allBytes = Buffer.byteLength(text, "utf-8");
          const diff = allBytes - lastSize;
          if (diff > 0) {
            const newContent = text.substring(text.length - Math.ceil(diff));
            const newLines = newContent.trim().split("\n").filter(Boolean);
            for (const line of newLines) {
              await stream.writeSSE({
                data: line,
                event: "log-line",
                id: String(id++),
              });
            }
          }
          lastSize = currentSize;
        } else if (currentSize < lastSize) {
          lastSize = currentSize;
        }
      } catch {
        break;
      }
      await stream.sleep(LOGS_POLL_MS);
    }
  });
});

export default app;
