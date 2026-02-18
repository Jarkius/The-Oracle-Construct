# ADR-016: Event Dispatcher — The Nervous System

**Status**: Accepted
**Date**: 2026-02-18
**Phase**: A (Make It Act)
**Deciders**: Oracle, Jarkius

## Context

The Oracle Construct has a mature observation layer (Phase 5-10):
- Events are captured → `events.jsonl`
- Patterns are detected → `patterns.json`
- Recommendations are generated → `recommendations.json`
- Heartbeat checks health → alerts logged

**But nothing acts on any of it.** Recommendations pile up. Alerts go to log files. Tasks sit in "pending" for days. The system observes brilliantly but acts only when a human starts a session and manually invokes an agent.

This is the autonomy gap. OpenClaw-style systems close this gap with an event→action loop.

## Decision

Build an **Event Dispatcher** — the nervous system that bridges detection to action.

### Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                    EVENT SOURCES                             │
│                                                              │
│  events.jsonl ──┐  recommendations.json ──┐                 │
│  (ci:fail,      │  (blocked_task,         │                 │
│   task:blocked) │   failure_alert,        │                 │
│                 │   stale_task)           │                 │
│  heartbeat ─────┘                         │                 │
│  alerts         ──────────────────────────┘                 │
└──────────────────────────┬───────────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────────┐
│              PULSE EVENT DISPATCHER                          │
│              pulse-event-dispatcher.sh                       │
│                                                              │
│  1. Load dispatch-rules.json                                │
│  2. Read recommendations + alerts + events                  │
│  3. Match triggers against rules                            │
│  4. Check cooldowns (prevent duplicate dispatch)            │
│  5. Output: DISPATCH|Agent|Task|RuleID                      │
│  6. Log to dispatch-log.jsonl                               │
└──────────────────────────┬───────────────────────────────────┘
                           │
              ┌────────────┼────────────┐
              ▼            ▼            ▼
     ┌────────────┐ ┌──────────┐ ┌───────────┐
     │ Auto       │ │ Pending  │ │ Cooldown  │
     │ Dispatch   │ │ Approval │ │ (skipped) │
     │            │ │          │ │           │
     │ Priority≤2 │ │ Priority>│ │ Recent    │
     │ + auto=true│ │ threshold│ │ dispatch  │
     └─────┬──────┘ └────┬─────┘ └───────────┘
           │              │
           ▼              ▼
     ┌──────────────────────────┐
     │  CONTEXT LOADER          │
     │  pulse-context-loader.sh │
     │                          │
     │  Loads per agent:        │
     │  - Personality file      │
     │  - Relevant memory       │
     │  - Recent events         │
     │  - Assigned tasks        │
     │  - Last session context  │
     │  - Current focus         │
     └──────────┬───────────────┘
                │
                ▼
     ┌──────────────────────────┐
     │  AGENT SPAWN             │
     │  (Task tool subagent)    │
     │                          │
     │  Smith investigates      │
     │  Oracle unblocks         │
     │  Neo implements          │
     └─────────────────────────┘
```

### Dispatch Rules

Rules are defined in `psi/pulse/dispatch-rules.json` — a configurable mapping:

```json
{
  "trigger": { "type": "recommendation", "rec_type": "failure_alert", "min_urgency": "high" },
  "action": { "agent": "Smith", "task": "...", "priority": 1, "auto_dispatch": true },
  "cooldown_minutes": 60
}
```

**Trigger types:**
- `recommendation` — matches recommendation type + urgency
- `heartbeat_alert` — matches heartbeat check + severity
- `event` — matches event type from events.jsonl

**Action properties:**
- `agent` — which Council agent to spawn
- `task` — template with `${rec.message}`, `${alert.message}`, `${event.data.field}` substitution
- `priority` — 1 (highest) to 4 (lowest)
- `auto_dispatch` — if true, spawns without human approval

**Safety:**
- `cooldown_minutes` — prevents re-dispatching the same rule within N minutes
- `max_concurrent_dispatches` — cap on simultaneous auto-dispatches (default: 3)
- `require_approval_above_priority` — manual approval needed for low-priority rules

### Integration Points

1. **Boot sequence** (`pulse-proactive-boot.sh`) — runs dispatcher at session start, outputs spawn instructions
2. **Heartbeat daemon** — calls dispatcher on critical alerts between sessions
3. **Manual** — `bash pulse-event-dispatcher.sh` anytime

### What This Enables

| Before | After |
|--------|-------|
| CI fails → alert logged → nobody reads | CI fails → Smith spawns → investigates → reports |
| Task stale 5 days → recommendation displayed | Task stale → Oracle spawns → reviews → updates status |
| Error spike → log entry | Error spike → Smith analyzes → identifies root cause |
| Blocked task → shows in morning brief | Blocked task → Oracle spawns → proposes resolution |

## Alternatives Considered

### 1. Event-driven daemon (always-on dispatcher)
Rejected — requires running another daemon + Claude API access (Phase 11). Phase A works within the existing session model.

### 2. Webhook-based triggers
Rejected — requires external infrastructure. Phase A is self-contained.

### 3. Extend heartbeat to directly spawn agents
Rejected — heartbeat should stay focused on health checks. Dispatch logic is separate concern.

## Consequences

### Positive
- System transitions from passive observer to reactive responder
- Agents get pre-loaded context when spawned (no cold starts)
- Configurable rules — easy to add new event→action mappings
- Cooldown prevents dispatch storms
- Approval gate preserves human oversight on non-critical actions

### Negative
- Dispatch happens at session start, not in real-time (until Phase 11 Gateway)
- Context loader depends on memory system being functional
- Rules are static JSON — no conditional logic (Phase B adds workflow engine)

### Risks
- Auto-dispatched agents may take unintended actions → mitigated by skill gating + priority threshold
- Cooldown may suppress legitimate repeat alerts → configurable per rule
- Context loading may slow boot → timeout after 10s, degrade gracefully

## Files

| File | Purpose |
|------|---------|
| `psi/pulse/dispatch-rules.json` | Configurable event→agent routing rules |
| `.claude/hooks/pulse-event-dispatcher.sh` | Core dispatcher — matches events to rules |
| `.claude/hooks/pulse-context-loader.sh` | Loads relevant memory for spawned agents |
| `.claude/hooks/pulse-proactive-boot.sh` | Boot integration — runs dispatcher at session start |
| `psi/pulse/dispatch-log.jsonl` | Audit trail of all dispatch decisions |
| `lib/matrix-memory-agents/src/heartbeat/heartbeat-daemon.ts` | Modified to call dispatcher on critical alerts |

## Phase Roadmap

- **Phase A (this ADR)**: Event→action loop within sessions
- **Phase B**: Agent messaging + team coordination
- **Phase C**: Real-time dispatch via Gateway (Phase 11)
- **Phase D**: Self-tuning rules based on dispatch outcomes

---

*"The system that sees but does not act is merely a mirror. The system that acts on what it sees — that is alive."*
