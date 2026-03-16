# Handoff: Oracle Nerve → The-matrix

**Date**: 2026-03-16 12:30 GMT+7
**From**: Oracle Nerve (trackattendance ecosystem)
**To**: The-matrix (any agent picking this up)
**Task**: Knowledge transfer of battle-tested self-healing patterns, code snippets, tool evaluations, and architectural warnings — for The-matrix to evolve independently

> "Patterns Over Intentions" — we document what WORKS. The-matrix decides HOW to apply.

---

## Context

Oracle Nerve is a 1,300 LOC self-healing daemon ecosystem that has been running in `~/workspace/products/trackattendance/` since February 2026. It monitors TrackAttendance services, heals failures automatically, bridges Telegram ↔ Claude, and learns from every incident.

This handoff does NOT migrate code. It transfers **patterns, decisions, warnings, and code snippets** so The-matrix can evolve its own version — or consume Oracle Nerve as a service from `~/workspace/tools/oracle-nerve/` (where it's being extracted as an independent package).

**Why a handoff, not a merge?**
- Two PULSE event systems have INCOMPATIBLE dispatch rule schemas
- The-matrix is on an unmerged 104K-insertion branch — coupling to it is risky
- `matrix-gateway.ts` (19KB Telegram bot) would collide with `oracle-bot.ts`
- Oracle Nerve's strength is compactness (1,300 LOC) — don't dilute into 40+ script sprawl
- "Form and Formless" — one consciousness, many forms. Same patterns, different implementations.

---

## 1. Battle-Tested Patterns (with code snippets)

### Pattern 1: Self-Healing Negative Feedback Loop (L1→L5 Escalation)

The core insight: errors are expected. The system doesn't panic — it escalates through graduated intervention until the problem resolves or a human takes over.

```
Sensor (heartbeat) → Error Signal (PULSE event) → Comparator (dispatch rules)
    → Actuator (auto-fix or Claude) → Verify (next heartbeat) → Loop closes
```

**Escalation Levels:**
| Level | Trigger | Action | Delay |
|-------|---------|--------|-------|
| L1 | < 3 restarts/hour | Simple restart | 35 sec |
| L2 | 3-4 restarts/hour | Clear temp log + restart | 70 sec |
| L3 | >= 5 restarts/hour | Notify human (Telegram + Thai voice alert), schedule L4 | immediate |
| L4 | 15 min after L3 | Spawn Claude to diagnose (read logs, analyze) | 15 min |
| L5 | L4 exhausted | Standby: retry every 5 min, reset when 60 sec stable | 5 min |

**Key code — escalation handler:**
```typescript
async function handleEscalation(daemon: DaemonConfig): Promise<void> {
  const currentHour = Math.floor(Date.now() / 3_600_000);
  if (currentHour !== daemon.lastRestartHour) {
    daemon.restartsThisHour = 0;
    daemon.lastRestartHour = currentHour;
  }
  daemon.restarts++;
  daemon.restartsThisHour++;

  if (daemon.restartsThisHour < L2_THRESHOLD) {
    // L1: restart
    daemon.escalationLevel = 1;
    await emitEvent("daemon:restart", "oracle-daemon", { name: daemon.name, level: 1 });
    setTimeout(() => spawnDaemon(daemon), RESTART_DELAY_MS);
    return;
  }
  if (daemon.restartsThisHour < L3_THRESHOLD) {
    // L2: reset state + restart
    daemon.escalationLevel = 2;
    await Bun.write(daemon.logFile, `[...] L2 reset\n`);
    setTimeout(() => spawnDaemon(daemon), RESTART_DELAY_MS * 2);
    return;
  }
  // L3: notify human, schedule L4
  daemon.escalationLevel = 3;
  await notifyTelegram(`🚨 ${daemon.name} exceeded restart budget...`);
  daemon.escalationTimer = setTimeout(() => escalateToL4(daemon), L4_DELAY_MS);
}
```

**L4 Claude diagnosis:**
```typescript
async function escalateToL4(daemon: DaemonConfig): Promise<void> {
  if (daemon.process !== null) { daemon.escalationLevel = 0; return; } // already recovered

  const diagPrompt = `The daemon "${daemon.name}" keeps crashing. ` +
    `Restarted ${daemon.restartsThisHour} times. Exit codes: ${daemon.exitHistory.join(", ")}. ` +
    `Check log: ${daemon.logFile}`;

  const proc = Bun.spawn([
    "claude", "-p", diagPrompt,
    "--output-format", "text",
    "--allowedTools", "Bash,Read,Grep,Glob",
    "--max-turns", "5",
  ], { cwd: CWD, env: { ...process.env, CLAUDE_CODE_ENTRYPOINT: "cli" } });

  const timeout = setTimeout(() => { try { proc.kill(); } catch {} }, 3 * 60_000);
  const stdout = await new Response(proc.stdout).text();
  await proc.exited;
  clearTimeout(timeout);
  await notifyTelegram(`🔬 Diagnosis:\n\n${stdout.trim().slice(0, 3000)}`);
  escalateToL5(daemon);
}
```

**L5 standby with auto-recovery:**
```typescript
function escalateToL5(daemon: DaemonConfig): void {
  daemon.escalationLevel = 5;
  daemon.standbyTimer = setInterval(async () => {
    if (daemon.process !== null) return;
    spawnDaemon(daemon);
    // Check if it stays alive 60s
    setTimeout(async () => {
      if (daemon.process !== null) {
        daemon.escalationLevel = 0;
        daemon.restartsThisHour = 0;
        if (daemon.standbyTimer) clearInterval(daemon.standbyTimer);
        await emitEvent("daemon:recovered", "oracle-daemon", { name: daemon.name, fromLevel: 5 });
        await notifyTelegram(`✅ ${daemon.name} recovered!`);
      }
    }, 60_000);
  }, 5 * 60_000);
}
```

---

### Pattern 2: PULSE Shared Module (appendFile, NOT Bun.write)

**CRITICAL BUG**: `Bun.write(path, data, { append: true })` silently ignores the append flag in Bun 1.3.5. This caused **silent data loss** in events.jsonl — events were overwritten instead of appended.

**Fix**: Always use `node:fs/promises appendFile()`:

```typescript
import { appendFile } from "node:fs/promises";

export async function appendLine(filePath: string, data: string): Promise<void> {
  await appendFile(filePath, data.endsWith("\n") ? data : data + "\n");
}

export async function emitEvent(
  type: string,
  agent: string,
  data: Record<string, unknown> = {}
): Promise<void> {
  const event = {
    id: `ev_${Date.now()}`,
    ts: new Date().toISOString(),
    type,
    agent,
    data,
  };
  await appendLine(EVENTS_PATH, JSON.stringify(event));
}

export async function notifyTelegram(message: string): Promise<void> {
  const token = process.env.TELEGRAM_BOT_TOKEN;
  const chatId = process.env.TELEGRAM_CHAT_ID;
  if (!token || !chatId) return;
  await fetch(`https://api.telegram.org/bot${token}/sendMessage`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ chat_id: chatId, text: message, parse_mode: "Markdown" }),
  });
}
```

**File paths (configurable via env or constants):**
```typescript
const CWD = process.env.ORACLE_CWD || "/Users/jarkius/workspace/products/trackattendance";
const EVENTS_PATH     = `${CWD}/ψ/pulse/events.jsonl`;
const HEARTBEAT_PATH  = `${CWD}/ψ/pulse/heartbeat.json`;
const SESSION_CONTEXT = `${CWD}/ψ/inbox/session-context.md`;
const TELEGRAM_INBOX  = `${CWD}/ψ/inbox/telegram-queue.jsonl`;
const FIX_REQUESTS    = `${CWD}/ψ/inbox/fix-requests.jsonl`;
const DISPATCH_RULES  = `${CWD}/ψ/pulse/dispatch-rules.json`;
const KNOWN_FIXES     = `${CWD}/.agents/skills/oracle-nerve/known-fixes.json`;
```

---

### Pattern 3: Non-Blocking /do (Fire-and-Forget Task Execution)

The `/do <task>` command queues work for Claude without blocking the Telegram bot. Two strategies:

```typescript
async function runDoTask(task: string, chatId: number): Promise<void> {
  // Strategy 1: Inject into active Claude tmux session
  const pane = await findClaudeTmuxPane();
  if (pane) {
    await sendToClaudeTmux(pane, task);
    await new Promise(r => setTimeout(r, 15_000));
    const output = await captureClaudeOutput(pane);
    // send result to Telegram
    return;
  }

  // Strategy 2: Headless claude -p
  const proc = Bun.spawn([
    "claude", "-p", task,
    "--output-format", "text",
    "--allowedTools", "Bash,Read,Write,Edit,Grep,Glob,Agent",
    "--max-turns", "10",
  ], { cwd: CWD });

  const timeout = setTimeout(() => { try { proc.kill(); } catch {} }, 5 * 60_000);
  const stdout = await new Response(proc.stdout).text();
  await proc.exited;
  clearTimeout(timeout);
  // send result to Telegram
}
```

---

### Pattern 4: tmux Send-Keys Injection (from maw.js)

Two methods for sending text to tmux panes:

```typescript
// Method 1: Direct send-keys (short, single-line text)
async function sendKeys(pane: string, text: string): Promise<void> {
  await Bun.spawn(["tmux", "send-keys", "-t", pane, text, "Enter"]).exited;
}

// Method 2: Buffer method (long text, multiline, special chars)
// Prevents shell interpolation and command injection
async function sendViaBuffer(pane: string, text: string): Promise<void> {
  const tmpFile = `/tmp/oracle-tmux-${Date.now()}.txt`;
  await Bun.write(tmpFile, text);
  await Bun.spawn(["tmux", "load-buffer", tmpFile]).exited;
  await Bun.spawn(["tmux", "paste-buffer", "-t", pane]).exited;
  await new Promise(r => setTimeout(r, 150)); // let Claude process input
  await Bun.spawn(["tmux", "send-keys", "-t", pane, "Enter"]).exited;
  await Bun.spawn(["rm", tmpFile]).exited;
}

// Decision logic
async function smartSend(pane: string, text: string): Promise<void> {
  if (text.length > 500 || text.includes("\n") || /[;&|$`]/.test(text)) {
    await sendViaBuffer(pane, text);
  } else {
    await sendKeys(pane, text);
  }
}
```

**Security warning**: Never pass user text through `bash -c` with tmux send-keys. The buffer method prevents shell escape attacks.

---

### Pattern 5: GPT Live Context Builder

Before every AI message, oracle-bot rebuilds a comprehensive context block:

```typescript
async function buildLiveContext(): Promise<string> {
  const parts: string[] = [];

  // 1. Session context (latest /do result, system state)
  const sessionCtx = await readFileIfExists(SESSION_CONTEXT);
  if (sessionCtx) parts.push(`## System Context\n${sessionCtx.slice(0, 2000)}`);

  // 2. Health status
  const heartbeat = await readJsonIfExists(HEARTBEAT_PATH);
  if (heartbeat) {
    const healthLine = heartbeat.checks.map(c => `${c.ok ? "✅" : "❌"} ${c.name}`).join(", ");
    parts.push(`## Health: ${healthLine}`);
  }

  // 3. Recent events (last 15)
  const events = await readLastNLines(EVENTS_PATH, 15);
  if (events.length) parts.push(`## Recent Events\n${events.map(e => `- ${e.type} (${e.agent})`).join("\n")}`);

  // 4. Recent git commits (all repos)
  const gitLog = await captureCmd("git", ["-C", CWD, "log", "--oneline", "-5"]);
  if (gitLog) parts.push(`## Recent Commits\n${gitLog}`);

  // 5. Latest retrospective
  const latestRetro = await findLatestFile(`${CWD}/ψ/memory/retrospectives/`);
  if (latestRetro) parts.push(`## Latest Retro\n${(await Bun.file(latestRetro).text()).slice(0, 500)}`);

  // 6. Unread inbox
  const unread = await countUnread(TELEGRAM_INBOX);
  if (unread > 0) parts.push(`## Inbox: ${unread} unread messages`);

  // 7. Open fix requests
  const fixes = await countOpen(FIX_REQUESTS);
  if (fixes > 0) parts.push(`## Open Fixes: ${fixes} pending`);

  return parts.join("\n\n");
}
```

This gives the AI bridge (GPT/Gemini) **live awareness** of what Claude has been doing, what needs attention, and what's broken.

---

### Pattern 6: Auto-Dispatch [AUTO-DO] Detection

GPT can autonomously trigger Claude tasks:

```typescript
// After receiving AI response
if (aiResponse.includes("[AUTO-DO]")) {
  const match = aiResponse.match(/\[AUTO-DO\]\s*(.+)/);
  if (match) {
    const task = match[1].trim();
    await ctx.reply(`🤖 Auto-dispatching: ${task}`);
    runDoTask(task, ctx.chat.id); // fire and forget
  }
}
```

---

### Pattern 7: State Transition Detection (Heartbeat)

Only emit events when state **changes**, not on every poll. Dramatically reduces noise:

```typescript
const previousState = new Map<string, boolean>();

for (const check of checks) {
  const prev = previousState.get(check.name);
  if (prev === true && !check.ok) {
    // Healthy → Unhealthy (rising edge)
    await emitEvent("heartbeat:fail", "heartbeat", { check: check.name, detail: check.detail });
  } else if (prev === false && check.ok) {
    // Unhealthy → Healthy (falling edge)
    await emitEvent("heartbeat:recover", "heartbeat", { check: check.name, detail: check.detail });
  }
  previousState.set(check.name, check.ok);
}

// Keepalive every 30 min when all healthy
if (checks.every(c => c.ok) && Date.now() - lastKeepalive > 30 * 60_000) {
  await emitEvent("heartbeat:ok", "heartbeat", {});
  lastKeepalive = Date.now();
}
```

---

### Pattern 8: Known Fixes Registry (Self-Learning)

Every fix that works gets added to a JSON registry. The dispatch engine checks this before queuing a fix request:

```json
{
  "version": 2,
  "fixes": [
    {
      "id": "api-cold-start",
      "match": { "agent": "heartbeat", "error_contains": "Cloud API" },
      "fix": "curl -sf https://trackattendance-api.example.com/",
      "description": "Warm up Cloud Run cold start",
      "auto": true
    },
    {
      "id": "bot-polling-conflict",
      "match": { "agent": "oracle-bot", "error_contains": "409" },
      "do_command": "Find and kill duplicate bun processes polling same Telegram token",
      "description": "409 Conflict from duplicate polling",
      "auto": false
    },
    {
      "id": "events-jsonl-corrupt",
      "match": { "agent": "dispatch-engine", "error_contains": "JSON Parse error" },
      "fix": "python3 -c \"import json,sys;[print(l,end='') for l in open('ψ/pulse/events.jsonl') if (lambda l: (json.loads(l) and True) if l.strip() else False)(l)]\" > /tmp/events-clean.jsonl && mv /tmp/events-clean.jsonl ψ/pulse/events.jsonl",
      "description": "Remove malformed JSON lines from events",
      "auto": true
    }
  ]
}
```

**Lookup logic:**
```typescript
function findKnownFix(event: PulseEvent): KnownFix | null {
  const errorStr = JSON.stringify(event.data).toLowerCase();
  return knownFixes.fixes.find(fix => {
    if (fix.match.agent && fix.match.agent !== event.agent) return false;
    if (fix.match.error_contains && !errorStr.includes(fix.match.error_contains.toLowerCase())) return false;
    return true;
  }) || null;
}
```

---

### Pattern 9: Dispatch Rules (Event Routing)

```json
{
  "version": 2,
  "rules": [
    {
      "id": "landing-down",
      "trigger": { "event": "heartbeat:fail", "check": "Landing Page" },
      "action": { "notify": true, "autofix": true, "message": "🚨 ${data.check} is DOWN: ${data.detail}" },
      "cooldown_minutes": 30
    },
    {
      "id": "nerve-heartbeat-recover",
      "trigger": { "event": "heartbeat:recover" },
      "action": { "notify": true, "message": "✅ ${data.check} recovered: ${data.detail}" },
      "cooldown_minutes": 0
    }
  ]
}
```

**Cooldown tracking prevents rule spam:**
```typescript
const cooldownMap = new Map<string, number>(); // ruleId → last fire timestamp

function canFire(rule: DispatchRule): boolean {
  const last = cooldownMap.get(rule.id) || 0;
  return Date.now() - last > rule.cooldown_minutes * 60_000;
}
```

---

### Pattern 10: UserPromptSubmit Hook for Inbox Awareness

A Claude Code hook that runs on every prompt submission, checking for unread Telegram messages:

```bash
#!/bin/bash
# ~/.claude/hooks/check-telegram-inbox.sh
INBOX="$HOME/workspace/products/trackattendance/ψ/inbox/telegram-queue.jsonl"
if [ -f "$INBOX" ]; then
  UNREAD=$(grep -c '"status":"unread"' "$INBOX" 2>/dev/null || echo 0)
  if [ "$UNREAD" -gt 0 ]; then
    echo "📬 $UNREAD unread Telegram messages in inbox"
  fi
fi
```

---

### Pattern 11: Daily Morning Newspaper (6 AM)

Scheduled report combining tech news + system status, sent to Telegram:

```typescript
// Fetch from multiple sources in parallel
const [hn, techcrunch, bbc] = await Promise.all([
  fetchHackerNews(5),    // Top 5 HN stories
  fetchTechCrunch(3),    // Top 3 TC headlines
  fetchBBC(3),           // Top 3 BBC Tech
]);

// Format with clickable links for Telegram
const report = [
  "🌅 *Oracle Morning Report*",
  `📅 ${new Date().toLocaleDateString("en-US", { weekday: "long", month: "long", day: "numeric" })}`,
  "",
  "📰 *Hacker News*",
  ...hn.map((s, i) => `${i + 1}. [${s.title}](${s.url})`),
  "",
  "🔧 *TechCrunch*",
  ...techcrunch.map((s, i) => `${i + 1}. [${s.title}](${s.url})`),
  "",
  // ... system health summary, events summary, open fixes
].join("\n");

await notifyTelegram(report);
```

---

### Pattern 12: Control Center (Hono HTTP Dashboard)

Real-time web dashboard for monitoring and manual control:

```typescript
import { Hono } from "hono";

const app = new Hono();

app.get("/api/status", async (c) => {
  // daemon status, health checks, event count, inbox unread, open fixes, tmux sessions
});

app.get("/api/logs/:daemon", async (c) => {
  // last 50 lines of daemon log file
});

app.get("/api/events", async (c) => {
  // last 30 PULSE events as JSON
});

app.post("/api/kill-orphans", async (c) => {
  // kill stale claude -p and ccbot processes
});

app.post("/api/restart/:daemon", async (c) => {
  // trigger pkill, oracle-daemon auto-restarts via watcher
});

// Dark theme dashboard with 5-sec auto-refresh
app.get("/", (c) => c.html(DASHBOARD_HTML));
```

---

## 2. Evaluated Tools (with verdicts)

| Tool | Verdict | Key Pattern to Take |
|------|---------|-------------------|
| **CCBot** (ccmux) | Pattern C wins | JSONL byte-offset watcher, transcript parser, InlineKeyboard permission UI |
| **claude-code-telegram** | Event bus + audit | Event listener pattern, file-based audit logging |
| **secure-openclaw** | Provider abstraction | Multi-platform AI provider, named concurrency lanes |
| **Clautel** | Session handoff | ngrok preview URLs, session resume via /session + /resume |
| **opensourcenatbrain** | Context + execution | Haiku context-finder (cheap triage), executor agent, distillation pipeline |
| **maw.js** | tmux mastery | Buffer method for text sending, smart length detection |

---

## 3. CCBot Patterns Ready to Port

These are the 6 core patterns from CCBot (Python) that can be reimplemented in TypeScript:

### 3a. JSONL Transcript Monitoring
```python
# Byte-offset tracking — read only new content
class SessionMonitor:
    def __init__(self):
        self.file_offsets = {}  # path → last read position

    def check_for_updates(self, transcript_path):
        current_size = os.path.getsize(transcript_path)
        last_offset = self.file_offsets.get(transcript_path, 0)
        if current_size <= last_offset:
            return []  # no new data

        with open(transcript_path, 'r') as f:
            f.seek(last_offset)
            new_data = f.read()

        self.file_offsets[transcript_path] = current_size
        return self.parse_entries(new_data)
```

### 3b. Transcript Parser
```python
# Parse Claude's JSONL output format
def parse_entry(entry):
    if entry.get("type") == "assistant":
        content = entry.get("message", {}).get("content", [])
        for block in content:
            if block["type"] == "text":
                yield {"type": "text", "content": block["text"]}
            elif block["type"] == "tool_use":
                yield {"type": "tool_use", "name": block["name"], "input": block["input"]}
    elif entry.get("type") == "result":
        yield {"type": "result", "subtype": entry.get("subtype")}
```

### 3c. Interactive Permission UI
```python
# grammY equivalent: InlineKeyboard for tool approval
keyboard = InlineKeyboard()
    .text("✅ Allow", f"perm_allow_{request_id}")
    .text("❌ Deny", f"perm_deny_{request_id}")
    .row()
    .text("✅ Allow All", f"perm_allow_all_{request_id}")

# On callback: send appropriate key to tmux pane
bot.on("callback_query", async (ctx) => {
    if (ctx.data.startsWith("perm_allow_")) {
        await sendKeys(pane, "y");  // approve in Claude's permission prompt
    }
});
```

### 3d. Message Queue with Rate Limiting
```python
# Buffer messages, flush every 1.0s to respect Telegram limits
class MessageQueue:
    buffer = []
    flush_interval = 1.0  # seconds

    async def add(self, text):
        self.buffer.append(text)

    async def flush(self):
        if not self.buffer:
            return
        combined = "\n".join(self.buffer)
        await bot.send_message(chat_id, combined)
        self.buffer.clear()
```

**Source files** (full Python sources at `ψ/learn/ccbot-patterns/`):
- `session_monitor.py` (526 lines) — Byte-offset JSONL watcher
- `transcript_parser.py` (762 lines) — Parse Claude output types
- `terminal_parser.py` (365 lines) — Detect responses, tool use, permissions
- `hook.py` (276 lines) — SessionStart hook
- `handlers/interactive_ui.py` (278 lines) — InlineKeyboard permission
- `handlers/message_queue.py` (604 lines) — Rate-limited message sending

---

## 4. Gemini Architecture Review (full insights)

From a deep Gemini 2.0 Flash research session reviewing Oracle Nerve's architecture:

### Message Broker
Replace file-based PULSE with Redis Pub/Sub or SQLite WAL at scale. `events.jsonl` will bottleneck with concurrent daemon read/writes. **Near-term fix**: SQLite WAL mode for dual-write (JSONL as audit trail, SQLite for live queries).

### SQLite Before JSONL Monitor
Build parsing logic on solid DB, not fragile flat files. Dual-write: SQLite for live state, JSONL as write-behind audit. This was promoted to Phase 2 in the master plan.

### L4 Circuit Breaker
Max 3 Claude diagnosis attempts per 24hrs + exponential backoff. Without this, a deterministic bug triggers infinite L4 loops that drain API credits. Promoted to Phase 0 HARDEN.

### tmux Command Injection
`bash -c` with user input = shell escape vulnerability. Terminal control chars, shell operators (`&&`, `;`, `|`), subshells `$()` can all break out.

**Fix**: Temp file method (see Pattern 4 above) or base64-encode. Never pass user text through shell. Promoted to Phase 0 HARDEN.

### Telegram Two-Bot Problem
Can't run two bots polling the same machine — 409 Conflict is unavoidable.

**Solutions**:
- Webhooks for one bot (requires public URL/ngrok), polling for other
- Single bot with topic-based routing (adopted — absorb CCBot into oracle-bot)

### OpenClaw Patterns Not Yet Adopted
- **Write-Ahead Delivery Queue**: Guarantees message delivery even on crash
- **Named Concurrency Lanes**: Prevent parallel tasks from conflicting
- **Cron Mastery**: Separate heartbeats (continuous) from hard cron schedules (daily report)
- **State Machine Checkpointing**: Save execution state at every major step for crash recovery

### Containerization
Docker/gVisor for headless Claude was evaluated but deemed overkill for single-dev Mac. Use `--allowedTools` restriction instead. Removed from roadmap (was Task 17).

---

## 5. Third-Party Architect Critical Warnings

A separate Claude instance was given the full codebase of both Oracle Nerve and The-matrix, then asked to evaluate the merge proposal. Key warnings:

1. **Two PULSE systems have INCOMPATIBLE dispatch rule schemas** — Oracle Nerve uses `{ trigger: { event, field }, action: { notify, autofix, message }, cooldown_minutes }` while The-matrix uses a different event/action schema. Don't merge naively.

2. **The-matrix is on an unmerged 104K-insertion branch** — coupling to it while it's in flux is risky. Let it stabilize first.

3. **matrix-gateway.ts (19KB) will collide with oracle-bot.ts** — both are Telegram bots with overlapping functionality. Choose one or namespace them carefully.

4. **Oracle Nerve's strength is compactness (1,300 LOC)** — don't dilute it into The-matrix's 40+ script sprawl. Keep it as a focused, portable package.

5. **"The right move is to keep Oracle Nerve independent, make it portable, and let The-matrix consume it as a service rather than absorb it as code."**

---

## 6. Lessons Learned (don't repeat these)

| Lesson | Impact | Fix |
|--------|--------|-----|
| `Bun.write()` append flag is silently broken | Silent data loss in events.jsonl | Use `node:fs/promises appendFile()` |
| Two Telegram bots can't poll on same machine | 409 Conflict kills one bot | Single bot, absorb functionality |
| Don't call `getUpdates` manually | Steals updates from polling loop | Use grammY's built-in polling |
| `drop_pending_updates: true` drops messages silently | Lost messages on restart | Set to `false`, handle duplicates instead |
| Try before planning | 30s of testing beats 30min of planning | Test existing tools FIRST |
| tmux send-keys with user input = injection risk | Shell escape vulnerability | Buffer method (temp file) |
| 409 retry needs 35s+ delay | Telegram's long-poll is 30s | Wait for previous poll to timeout |
| SQLite threading constraint | Can't share connections across threads | Pre-cache data on main thread |
| localStorage in Telegram WebView crashes JS | "Unknown error" in dashboard | Wrap in try/catch |

---

## 7. Proposed Oracle Nerve Modular Structure

For The-matrix to adopt IF it wants to build its own version:

```
src/
├── core/
│   ├── pulse.ts          # Event emission, JSONL append, logging
│   ├── telegram.ts       # Telegram API helpers
│   ├── tmux.ts           # tmux send-keys, capture, buffer method
│   └── db.ts             # SQLite/JSONL data layer
├── daemon/
│   ├── supervisor.ts     # L1→L5 escalation, process management
│   └── config.ts         # Daemon definitions, thresholds
├── bot/
│   ├── commands.ts       # /help, /status, /do, /issues, /inbox
│   ├── ai-bridge.ts      # GPT/Gemini conversation with live context
│   └── auto-dispatch.ts  # [AUTO-DO] detection
├── dispatch/
│   ├── engine.ts         # Rule matching, cooldown tracking
│   ├── autofix.ts        # Known-fix execution
│   └── rules.json        # Dispatch rules configuration
├── health/
│   ├── heartbeat.ts      # Health checks (HTTP, Telegram, git)
│   └── checks.ts         # Individual check definitions
├── bridge/
│   ├── transcript.ts     # JSONL byte-offset watcher (from CCBot)
│   └── permissions.ts    # InlineKeyboard approval UI
├── report/
│   └── daily.ts          # Morning newspaper generator
└── dashboard/
    └── control-center.ts # Hono HTTP dashboard
```

---

## 8. Data Flow Architecture

```
┌──────────────────────────────────────────────────────────┐
│                    Oracle Nerve                           │
│                                                          │
│  ┌─────────┐    ┌──────────┐    ┌────────────────┐      │
│  │Heartbeat│───▶│  PULSE   │───▶│Dispatch Engine │      │
│  │ (5 min) │    │events.jsonl│   │ (2 sec poll)   │      │
│  └─────────┘    └──────────┘    └───────┬────────┘      │
│                      ▲                   │               │
│                      │            ┌──────▼──────┐        │
│  ┌─────────┐         │            │ Known Fixes │        │
│  │Oracle   │─────────┤            │  Registry   │        │
│  │Daemon   │         │            └──────┬──────┘        │
│  │(L1→L5) │         │                   │               │
│  └─────────┘         │            ┌──────▼──────┐        │
│                      │            │  Auto-Fix   │        │
│  ┌─────────┐         │            │  OR Claude  │        │
│  │Oracle   │─────────┘            │  OR Queue   │        │
│  │Bot      │◀─────────────────────┴─────────────┘        │
│  │(Telegram)│                                            │
│  └────┬────┘                                             │
│       │                                                  │
│  ┌────▼────────┐   ┌──────────┐   ┌──────────────┐      │
│  │GPT/Gemini   │   │Telegram  │   │ Fix Requests │      │
│  │AI Bridge    │   │Inbox     │   │ (for Claude) │      │
│  │(live context)│  │(JSONL)   │   │ (JSONL)      │      │
│  └─────────────┘   └──────────┘   └──────────────┘      │
│                                                          │
│  ┌──────────────┐   ┌─────────────────┐                  │
│  │Control Center│   │Daily Report     │                  │
│  │(Hono HTTP)   │   │(6 AM cron)      │                  │
│  └──────────────┘   └─────────────────┘                  │
└──────────────────────────────────────────────────────────┘
```

---

## 9. References

| Resource | Location |
|----------|----------|
| Oracle Nerve live code | `~/workspace/products/trackattendance/scripts/` |
| Oracle Nerve extracted (future) | `~/workspace/tools/oracle-nerve/` |
| CCBot patterns | `~/workspace/products/trackattendance/ψ/learn/ccbot-patterns/` |
| CCBot key patterns cheat sheet | `~/workspace/products/trackattendance/ψ/learn/ccbot-patterns/KEY-PATTERNS.md` |
| Gemini architecture review | `~/workspace/products/trackattendance/ψ/memory/learnings/2026-03-16_gemini-architecture-review.md` |
| Gemini deep research (Telegram bridges) | `~/workspace/products/trackattendance/ψ/memory/learnings/2026-03-16_remote-claude-telegram-deep-research.md` |
| Gemini deep research (OpenClaw reports) | `~/workspace/products/trackattendance/ψ/memory/learnings/2026-03-16_openclaw-telegram-report-scheduling.md` |
| Oracle lessons | `~/workspace/products/trackattendance/ψ/learn/oracle-lessons.md` |
| Distillation pipeline | `~/workspace/products/trackattendance/ψ/learn/distillation-pattern.md` |
| v3 Master Plan | `~/workspace/products/trackattendance/ψ/inbox/handoff/2026-03-16_11-55_oracle-v3-master-plan.md` |
| Cloned repos (ghq) | `~/ghq/github.com/{six-ddc/ccmux, RichardAtCT/claude-code-telegram, ComposioHQ/secure-openclaw, Soul-Brews-Studio/maw-js}` |

---

## Key Decisions Made

| Decision | Source | Rationale |
|----------|--------|-----------|
| Knowledge handoff, NOT code migration | Third-party architect | Incompatible schemas, branch risk, bot collision |
| Extract Oracle Nerve to `tools/` | SOUL.md + architect | "Build swarms, not monoliths" — keep portable |
| Pattern C (JSONL + tmux) for remote monitoring | CCBot evaluation | Same session, structured data, desktop resume |
| Single bot (absorb CCBot) | 409 Conflict debugging | Can't run two polling bots on same machine |
| SQLite before JSONL monitor | Gemini review | Build on solid foundation |
| appendFile, not Bun.write | Production bug | Bun.write append flag silently broken |

---

## Watch For

- **Schema incompatibility**: Oracle Nerve dispatch rules and The-matrix pulse events use DIFFERENT schemas. Don't try to share a rule set.
- **Bot collision**: If The-matrix has `matrix-gateway.ts` polling Telegram, it WILL conflict with oracle-bot.ts. Choose one or use webhooks.
- **Branch stability**: The-matrix's 104K-insertion branch should merge before building on top of it.
- **JSONL bottleneck**: events.jsonl works fine at current scale but will need SQLite WAL for concurrent read/writes at higher throughput.

---

## Tests / Verification

1. This handoff file exists in `psi/swarm/handoffs/`
2. The-matrix's BOOT.md Step 8 (cross-project messages) or manual scan finds it
3. The-matrix reads and makes its OWN decisions — we provided clarity, not commands
4. Oracle Nerve continues evolving independently at `tools/oracle-nerve/`

---

## Next Steps (for The-matrix)

1. **Read this handoff** — understand what Oracle Nerve has learned
2. **Evaluate patterns** — which ones align with The-matrix's architecture?
3. **Decide adoption** — build own version, consume as service, or both?
4. **Check warnings** — especially schema incompatibility and bot collision
5. **Evolve independently** — same source of knowledge, different form

> "External Brain, Not Command" — we provide clarity, The-matrix decides direction.
