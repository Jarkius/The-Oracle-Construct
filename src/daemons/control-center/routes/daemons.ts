/**
 * Daemon Management Routes
 *
 * Health checks, start/stop/restart, and orphan cleanup for Matrix daemons.
 */

import { Hono } from "hono";
import { join } from "node:path";
import { PROJECT_ROOT } from "../../../core/paths";

const CWD = PROJECT_ROOT;
const SERVICES_SCRIPT = join(CWD, ".claude/hooks/matrix-services.sh");

export const DAEMONS = [
  { name: "heartbeat", port: 37892, hasHttp: true },
  { name: "gateway", port: 8082, hasHttp: true },
  { name: "hub", port: 8081, hasHttp: true },
  { name: "indexer", port: 37890, hasHttp: true },
  { name: "cdp-proxy", port: 9222, hasHttp: false },
  { name: "matrix-daemon", port: 37888, hasHttp: true },
  { name: "watcher", port: 0, hasHttp: false },
] as const;

export const VALID_DAEMON_NAMES = new Set(DAEMONS.map((d) => d.name));

function getDaemon(name: string) {
  return DAEMONS.find((d) => d.name === name);
}

export async function checkDaemonStatus(daemon: (typeof DAEMONS)[number]) {
  if (daemon.hasHttp && daemon.port > 0) {
    try {
      const res = await fetch(`http://localhost:${daemon.port}/status`, {
        signal: AbortSignal.timeout(3000),
      });
      return { name: daemon.name, port: daemon.port, running: res.ok, hasHttp: daemon.hasHttp };
    } catch {
      return { name: daemon.name, port: daemon.port, running: false, hasHttp: daemon.hasHttp };
    }
  }

  // Process-based check for non-HTTP daemons
  try {
    const cmd =
      process.platform === "win32"
        ? ["tasklist", "/FI", `IMAGENAME eq ${daemon.name}*`]
        : ["pgrep", "-f", daemon.name];
    const proc = Bun.spawn(cmd, { stdout: "pipe", stderr: "pipe" });
    const out = await new Response(proc.stdout).text();
    const code = await proc.exited;
    const running = process.platform === "win32" ? !out.includes("No tasks") : code === 0;
    return { name: daemon.name, port: daemon.port, running, hasHttp: daemon.hasHttp };
  } catch {
    return { name: daemon.name, port: daemon.port, running: false, hasHttp: daemon.hasHttp };
  }
}

const app = new Hono();

// GET / — all daemon statuses
app.get("/", async (c) => {
  try {
    const statuses = await Promise.all(DAEMONS.map(checkDaemonStatus));
    return c.json({ daemons: statuses, timestamp: new Date().toISOString() });
  } catch (e) {
    return c.json({ error: String(e) }, 500);
  }
});

// GET /:name — single daemon detail
app.get("/:name", async (c) => {
  const name = c.req.param("name");
  const daemon = getDaemon(name);
  if (!daemon) {
    return c.json({ error: `Unknown daemon: ${name}` }, 404);
  }
  try {
    const status = await checkDaemonStatus(daemon);
    return c.json(status);
  } catch (e) {
    return c.json({ error: String(e) }, 500);
  }
});

// POST /:name/start
app.post("/:name/start", async (c) => {
  const name = c.req.param("name");
  if (!VALID_DAEMON_NAMES.has(name)) {
    return c.json({ error: `Invalid daemon: ${name}` }, 400);
  }
  try {
    const proc = Bun.spawn(["bash", SERVICES_SCRIPT, "start", name], {
      stdout: "pipe",
      stderr: "pipe",
    });
    const [stdout, stderr] = await Promise.all([
      new Response(proc.stdout).text(),
      new Response(proc.stderr).text(),
    ]);
    const exitCode = await proc.exited;
    return c.json({ action: "start", daemon: name, exitCode, stdout: stdout.trim(), stderr: stderr.trim() });
  } catch (e) {
    return c.json({ error: String(e) }, 500);
  }
});

// POST /:name/stop
app.post("/:name/stop", async (c) => {
  const name = c.req.param("name");
  if (!VALID_DAEMON_NAMES.has(name)) {
    return c.json({ error: `Invalid daemon: ${name}` }, 400);
  }
  try {
    const proc = Bun.spawn(["bash", SERVICES_SCRIPT, "stop", name], {
      stdout: "pipe",
      stderr: "pipe",
    });
    const [stdout, stderr] = await Promise.all([
      new Response(proc.stdout).text(),
      new Response(proc.stderr).text(),
    ]);
    const exitCode = await proc.exited;
    return c.json({ action: "stop", daemon: name, exitCode, stdout: stdout.trim(), stderr: stderr.trim() });
  } catch (e) {
    return c.json({ error: String(e) }, 500);
  }
});

// POST /:name/restart
app.post("/:name/restart", async (c) => {
  const name = c.req.param("name");
  if (!VALID_DAEMON_NAMES.has(name)) {
    return c.json({ error: `Invalid daemon: ${name}` }, 400);
  }
  try {
    const proc = Bun.spawn(["bash", SERVICES_SCRIPT, "restart", name], {
      stdout: "pipe",
      stderr: "pipe",
    });
    const [stdout, stderr] = await Promise.all([
      new Response(proc.stdout).text(),
      new Response(proc.stderr).text(),
    ]);
    const exitCode = await proc.exited;
    return c.json({ action: "restart", daemon: name, exitCode, stdout: stdout.trim(), stderr: stderr.trim() });
  } catch (e) {
    return c.json({ error: String(e) }, 500);
  }
});

// POST /kill-orphans — find and kill orphan claude processes
app.post("/kill-orphans", async (c) => {
  const killed: string[] = [];
  try {
    if (process.platform === "win32") {
      const proc = Bun.spawn(
        ["tasklist", "/FI", "IMAGENAME eq claude*", "/FO", "CSV", "/NH"],
        { stdout: "pipe" },
      );
      const out = await new Response(proc.stdout).text();
      await proc.exited;
      const lines = out.trim().split("\n").filter(Boolean);
      for (const line of lines) {
        const match = line.match(/"[^"]+","(\d+)"/);
        if (match) {
          const pid = Number(match[1]);
          try {
            Bun.spawn(["taskkill", "/PID", String(pid), "/F"], { stdout: "pipe", stderr: "pipe" });
            killed.push(`claude:${pid}`);
          } catch {}
        }
      }
    } else {
      const proc = Bun.spawn(["bash", "-c", "pgrep -f 'claude.*-p' | head -20"], {
        stdout: "pipe",
      });
      const pids = (await new Response(proc.stdout).text()).trim().split("\n").filter(Boolean);
      await proc.exited;
      for (const pid of pids) {
        try {
          process.kill(Number(pid), 9);
          killed.push(`claude-p:${pid}`);
        } catch {}
      }
    }
  } catch {}
  return c.json({ killed, timestamp: new Date().toISOString() });
});

export default app;
