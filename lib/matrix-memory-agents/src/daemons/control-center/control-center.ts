#!/usr/bin/env bun
/**
 * Matrix Control Center — System Dashboard
 *
 * Hono HTTP dashboard for monitoring Matrix daemons, PULSE events,
 * Nerve escalation state, and known fixes.
 *
 * Migrated from Oracle Nerve (trackattendance) and adapted for The Matrix.
 *
 * http://localhost:8100 (configurable via CONTROL_PORT)
 */

import { Hono } from "hono";
import { readFile } from "node:fs/promises";
import { join } from "node:path";

const PORT = Number(process.env.CONTROL_PORT) || 8100;
const CWD = process.env.MATRIX_ROOT || join(import.meta.dir, "../../../..");

// Paths
const EVENTS_PATH = join(CWD, "psi/pulse/events.jsonl");
const HEARTBEAT_PATH = join(CWD, "psi/pulse/heartbeat.json");
const KNOWN_FIXES_PATH = join(CWD, "psi/pulse/known-fixes.json");
const DAEMON_LOGS_DIR = join(CWD, "psi/pulse/daemon-logs");
const TASKS_PATH = join(CWD, "psi/memory/tasks/active.json");
const SERVICES_SCRIPT = join(CWD, ".claude/hooks/matrix-services.sh");

// Matrix daemons (port-based health check)
const DAEMONS = [
  { name: "heartbeat", port: 37892 },
  { name: "gateway", port: 8082 },
  { name: "hub", port: 8081 },
  { name: "indexer", port: 37890 },
];

const app = new Hono();

// Security: validate daemon names to prevent injection
const VALID_DAEMON_NAMES = new Set(DAEMONS.map(d => d.name));
function isValidDaemon(name: string): boolean {
  return VALID_DAEMON_NAMES.has(name);
}

// ─── Helper ─────────────────────────────────────────────────────────────────

async function readFileOr<T>(path: string, fallback: T): Promise<T | string> {
  try { return await readFile(path, "utf-8"); } catch { return fallback; }
}

async function readJsonOr<T>(path: string, fallback: T): Promise<T> {
  try { return JSON.parse(await readFile(path, "utf-8")); } catch { return fallback; }
}

// ─── API Routes ─────────────────────────────────────────────────────────────

app.get("/api/status", async (c) => {
  // Check each daemon via HTTP port
  const statuses: Record<string, any> = {};
  for (const d of DAEMONS) {
    try {
      const res = await fetch(`http://localhost:${d.port}/status`, {
        signal: AbortSignal.timeout(3000),
      });
      statuses[d.name] = { running: res.ok, port: d.port };
    } catch {
      statuses[d.name] = { running: false, port: d.port };
    }
  }

  // Heartbeat data
  const heartbeat = await readJsonOr(HEARTBEAT_PATH, null);

  // Events count
  let eventCount = 0;
  try {
    const text = await readFile(EVENTS_PATH, "utf-8");
    eventCount = text.trim().split("\n").filter(Boolean).length;
  } catch {}

  // Tasks
  const tasks = await readJsonOr<any>(TASKS_PATH, { tasks: [] });
  const pendingTasks = tasks.tasks?.filter((t: any) => t.status === "pending").length ?? 0;

  // tmux sessions
  let tmuxSessions: string[] = [];
  try {
    const proc = Bun.spawn(["tmux", "list-sessions", "-F", "#{session_name}: #{session_windows} windows"], { stdout: "pipe" });
    const out = await new Response(proc.stdout).text();
    await proc.exited;
    tmuxSessions = out.trim().split("\n").filter(Boolean);
  } catch {}

  return c.json({
    timestamp: new Date().toISOString(),
    matrix: "The Oracle Construct",
    daemons: statuses,
    heartbeat,
    events: eventCount,
    tasks: { pending: pendingTasks, total: tasks.tasks?.length ?? 0 },
    tmux: tmuxSessions,
  });
});

app.get("/api/logs/:daemon", async (c) => {
  const daemon = c.req.param("daemon");
  const logFile = join(DAEMON_LOGS_DIR, `${daemon}.log`);
  try {
    const text = await readFile(logFile, "utf-8");
    const lines = text.trim().split("\n").slice(-50);
    return c.json({ daemon, lines });
  } catch {
    return c.json({ daemon, lines: ["(no log file)"] });
  }
});

app.get("/api/events", async (c) => {
  try {
    const text = await readFile(EVENTS_PATH, "utf-8");
    const lines = text.trim().split("\n").filter(Boolean).slice(-30);
    const events = lines.map(l => { try { return JSON.parse(l); } catch { return null; } }).filter(Boolean);
    return c.json(events);
  } catch {
    return c.json([]);
  }
});

app.get("/api/nerve", async (c) => {
  // Nerve status — read from supervisor if running
  // For now, return static data from events
  try {
    const text = await readFile(EVENTS_PATH, "utf-8");
    const lines = text.trim().split("\n").filter(Boolean);
    const nerveEvents = lines
      .map(l => { try { return JSON.parse(l); } catch { return null; } })
      .filter((e: any) => e?.type?.startsWith("nerve:"))
      .slice(-20);
    return c.json({ events: nerveEvents });
  } catch {
    return c.json({ events: [] });
  }
});

app.get("/api/known-fixes", async (c) => {
  const registry = await readJsonOr(KNOWN_FIXES_PATH, { fixes: [] });
  return c.json(registry);
});

app.post("/api/restart/:daemon", async (c) => {
  const daemon = c.req.param("daemon");
  if (!isValidDaemon(daemon)) {
    return c.json({ error: "Invalid daemon name" }, 400);
  }
  try {
    const proc = Bun.spawn(["bash", SERVICES_SCRIPT, "restart", daemon], { stdout: "pipe", stderr: "pipe" });
    await proc.exited;
    return c.json({ restarted: daemon });
  } catch (e) {
    return c.json({ error: String(e) }, 500);
  }
});

app.post("/api/kill-orphans", async (c) => {
  const killed: string[] = [];
  try {
    const proc = Bun.spawn(["bash", "-c", "pgrep -f 'claude.*-p' | head -20"], { stdout: "pipe" });
    const pids = (await new Response(proc.stdout).text()).trim().split("\n").filter(Boolean);
    for (const pid of pids) {
      try { process.kill(Number(pid), 9); killed.push(`claude-p:${pid}`); } catch {}
    }
  } catch {}
  return c.json({ killed });
});

// ─── Dashboard HTML ─────────────────────────────────────────────────────────

app.get("/", (c) => {
  return c.html(`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Matrix Control Center</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: 'SF Mono', 'Menlo', monospace; background: #0a0a0a; color: #e0e0e0; padding: 20px; }
    h1 { font-size: 18px; color: #00ff88; margin-bottom: 20px; }
    .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 16px; }
    .card { background: #1a1a1a; border: 1px solid #333; border-radius: 8px; padding: 16px; }
    .card h2 { font-size: 13px; color: #888; text-transform: uppercase; margin-bottom: 12px; }
    .service { display: flex; justify-content: space-between; align-items: center; padding: 6px 0; border-bottom: 1px solid #222; }
    .service:last-child { border-bottom: none; }
    .dot { width: 8px; height: 8px; border-radius: 50%; display: inline-block; margin-right: 8px; }
    .dot.on { background: #00ff88; }
    .dot.off { background: #ff4444; }
    .name { font-size: 13px; }
    .stat { font-size: 24px; font-weight: bold; color: #00ff88; }
    .stat.warn { color: #ffaa00; }
    .stat.bad { color: #ff4444; }
    .label { font-size: 11px; color: #666; margin-top: 4px; }
    .health { display: flex; gap: 8px; flex-wrap: wrap; }
    .check { font-size: 12px; padding: 4px 8px; border-radius: 4px; background: #1e3a1e; color: #00ff88; }
    .check.fail { background: #3a1e1e; color: #ff4444; }
    .tmux { font-size: 12px; color: #aaa; padding: 4px 0; }
    .events { font-size: 11px; color: #aaa; max-height: 200px; overflow-y: auto; }
    .events div { padding: 2px 0; border-bottom: 1px solid #1a1a1a; }
    .nerve-event { font-size: 11px; padding: 4px; margin: 2px 0; border-radius: 4px; }
    .nerve-event.l1 { background: #1e2e1e; }
    .nerve-event.l2 { background: #2e2e1e; }
    .nerve-event.l3 { background: #3e2e1e; color: #ffaa00; }
    .nerve-event.l4 { background: #3e1e1e; color: #ff6644; }
    .nerve-event.l5 { background: #4e1e1e; color: #ff4444; }
    .btn { background: #333; color: #ddd; border: 1px solid #555; padding: 6px 12px; border-radius: 4px; cursor: pointer; font-size: 12px; font-family: inherit; }
    .btn:hover { background: #444; }
    .time { font-size: 11px; color: #555; }
    #updated { font-size: 11px; color: #444; margin-top: 16px; }
  </style>
</head>
<body>
  <h1>Matrix Control Center</h1>
  <div class="grid">
    <div class="card" style="grid-column: span 2;">
      <h2>Daemons <button class="btn" onclick="killOrphans()" style="float:right;background:#3a1a1a;border-color:#633;font-size:11px;">Kill Orphans</button></h2>
      <div id="services">Loading...</div>
    </div>
    <div class="card">
      <h2>Health</h2>
      <div id="health" class="health">Loading...</div>
    </div>
    <div class="card">
      <h2>Stats</h2>
      <div style="display:flex;gap:24px;">
        <div><div id="events" class="stat">-</div><div class="label">Events</div></div>
        <div><div id="tasks" class="stat">-</div><div class="label">Tasks</div></div>
      </div>
    </div>
    <div class="card">
      <h2>Nerve Escalation</h2>
      <div id="nerve">No nerve events</div>
    </div>
    <div class="card">
      <h2>Known Fixes</h2>
      <div id="fixes">Loading...</div>
    </div>
    <div class="card">
      <h2>tmux</h2>
      <div id="tmux">Loading...</div>
    </div>
    <div class="card" style="grid-column: span 2;">
      <h2>Recent Events <button class="btn" onclick="refresh()" style="float:right;">Refresh</button></h2>
      <div id="eventlog" class="events">Loading...</div>
    </div>
  </div>
  <div id="updated"></div>

  <script>
    function esc(s) { const d = document.createElement('div'); d.textContent = s; return d.innerHTML; }
    async function refresh() {
      try {
        const [status, events, nerve, fixes] = await Promise.all([
          fetch('/api/status').then(r => r.json()),
          fetch('/api/events').then(r => r.json()),
          fetch('/api/nerve').then(r => r.json()),
          fetch('/api/known-fixes').then(r => r.json()),
        ]);

        // Services
        document.getElementById('services').innerHTML = Object.entries(status.daemons).map(([name, d]) =>
          '<div class="service"><span><span class="dot ' + (d.running ? 'on' : 'off') + '"></span><span class="name">' + esc(name) + '</span> <span class="time">:' + d.port + '</span></span><span><button class="btn" onclick="restartDaemon(\\'' + esc(name) + '\\')" style="font-size:10px;padding:2px 8px;">Restart</button></span></div>'
        ).join('');

        // Health
        if (status.heartbeat?.checks) {
          document.getElementById('health').innerHTML = status.heartbeat.checks.map(c =>
            '<span class="check ' + (c.ok ? '' : 'fail') + '">' + (c.ok ? 'OK' : 'FAIL') + ' ' + c.name + '</span>'
          ).join('');
        }

        // Stats
        document.getElementById('events').textContent = status.events;
        document.getElementById('tasks').textContent = status.tasks.pending + '/' + status.tasks.total;

        // Nerve
        if (nerve.events?.length > 0) {
          document.getElementById('nerve').innerHTML = nerve.events.slice(-5).reverse().map(e => {
            const level = e.data?.level || 0;
            return '<div class="nerve-event l' + level + '">' + esc(e.type) + ' — ' + esc(e.data?.daemon || '') + ' L' + level + '</div>';
          }).join('');
        }

        // Known Fixes
        if (fixes.fixes?.length > 0) {
          document.getElementById('fixes').innerHTML = fixes.fixes.map(f =>
            '<div style="font-size:11px;padding:2px 0;"><span style="color:' + (f.auto ? '#00ff88' : '#ffaa00') + ';">' + (f.auto ? 'AUTO' : 'MANUAL') + '</span> ' + f.description + ' <span class="time">(' + f.successCount + '/' + (f.successCount + f.failCount) + ')</span></div>'
          ).join('');
        }

        // tmux
        document.getElementById('tmux').innerHTML = status.tmux.map(s => '<div class="tmux">' + s + '</div>').join('') || 'No sessions';

        // Events
        document.getElementById('eventlog').innerHTML = events.reverse().map(e => {
          const t = e.ts?.slice(11,19) || '';
          return '<div><span class="time">' + t + '</span> ' + esc(e.type) + ' <span class="time">' + esc(e.agent || '') + '</span></div>';
        }).join('');

        document.getElementById('updated').textContent = 'Updated: ' + new Date().toLocaleTimeString();
      } catch(e) {
        document.getElementById('services').textContent = 'Error: ' + e.message;
      }
    }

    async function killOrphans() {
      const r = await fetch('/api/kill-orphans', {method:'POST'});
      const d = await r.json();
      alert('Killed: ' + (d.killed.length > 0 ? d.killed.join(', ') : 'none found'));
      refresh();
    }
    async function restartDaemon(name) {
      if (!confirm('Restart ' + name + '?')) return;
      await fetch('/api/restart/' + name, {method:'POST'});
      setTimeout(refresh, 3000);
    }

    refresh();
    setInterval(refresh, 5000);
  </script>
</body>
</html>`);
});

// ─── Start ──────────────────────────────────────────────────────────────────

export default {
  port: PORT,
  fetch: app.fetch,
};

console.log(`Matrix Control Center running at http://localhost:${PORT}`);
