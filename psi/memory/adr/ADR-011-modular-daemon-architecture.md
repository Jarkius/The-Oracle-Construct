# ADR-011: Modular Daemon Architecture — Phase 9

**Status:** Proposed
**Date:** 2026-02-17
**Author:** Oracle + Architect
**Supersedes:** None
**Depends-on:** ADR-010 (matrix-memory-agents integration)

## Context

The Oracle Construct currently runs all intelligence synchronously:
- Pattern scanning runs at boot (once)
- Event processing is fire-and-forget via hooks
- Memory indexing is manual (`bun memory` CLI)
- Cross-project messaging is dormant (hub exists but isn't started)

Meanwhile, `lib/matrix-memory-agents/` already contains three production-grade daemon services that sit unused:

| Service | File | Lines | Port | Status |
|---------|------|-------|------|--------|
| Matrix Daemon | `src/matrix-daemon.ts` | 1046 | 37888 | Idle |
| Matrix Hub | `src/matrix-hub.ts` | 672 | 8081 | Idle |
| Indexer Daemon | `src/indexer/indexer-daemon.ts` | 466 | 37890+ | Idle |

Each has PID management, graceful shutdown, HTTP health APIs, and error recovery — but none are wired into the Oracle Construct's hook pipeline.

## Decision

### Part A: Apply Pending WEPs (Bottleneck Resolution)

Before building Phase 9, resolve the three pending workflow evolution proposals:

#### WEP-003: Commit Separation (Status: Already Implemented)
The `/commit:local` and `/commit:push` commands already exist in `.claude/commands/commit/`. The workflow in `.agent/workflows/commit.md` already handles MODE=local vs MODE=push. **Action:** Move WEP-003 to applied, no code changes needed.

#### WEP-004: Session ID Wiring
**Problem:** >50% of events have `session="unknown"` because `CLAUDE_SESSION_ID` is never set.

**Solution:** Claude Code hooks receive JSON on stdin with session context. Extract the session ID from the hook input and pass it through.

**Changes:**
1. `pulse-event-writer.sh` — Parse session ID from `$CLAUDE_SESSION_ID` env var (already done) OR from stdin JSON
2. `matrix-session-start.sh` — Extract session ID from the hook input JSON and export it
3. `pulse-post-action.sh` — Extract session ID from stdin JSON and pass to event writer
4. `pulse-session-end.sh` — Extract session ID from stdin JSON and pass to event writer

**Approach:** Each hook already receives JSON on stdin. The session ID is available in the Claude Code hook context. We parse it and set `CLAUDE_SESSION_ID` before calling the event writer.

#### WEP-005: CI/Test Failure Detection
**Problem:** No `ci:fail` events despite 30+ events logged. The current detection requires BOTH keyword match AND non-zero exit code — too restrictive.

**Solution:** Relax detection to catch more failure modes:
1. Detect test runner invocations (pytest, jest, npm test, bun test, phpunit)
2. Check exit code — non-zero = failure, emit `ci:fail`
3. Also detect common failure patterns in output even with exit code 0 (some runners exit 0 with failures)
4. Add `ci:pass` events for successful test runs (enables pass/fail ratio tracking)

### Part B: Phase 9 — Unified Daemon Service Layer

#### Architecture

```
┌──────────────────────────────────────────────────────────┐
│                   Oracle Construct                        │
│                                                          │
│  ┌─────────────┐  ┌──────────────┐  ┌─────────────────┐ │
│  │ PULSE Hooks  │→│ Event Queue  │→│ Pattern Scanner  │ │
│  │ (sync)       │  │ (JSONL)      │  │ (boot only)     │ │
│  └─────────────┘  └──────────────┘  └─────────────────┘ │
│         ↕                ↕                  ↕            │
│  ┌──────────────────────────────────────────────────────┐│
│  │            matrix-services.sh (NEW)                  ││
│  │         Unified daemon lifecycle manager             ││
│  └──────────┬───────────┬───────────┬───────────────────┘│
│             ↓           ↓           ↓                    │
│  ┌──────────────┐ ┌──────────┐ ┌─────────────┐          │
│  │ Indexer       │ │ Hub      │ │ Event        │          │
│  │ Daemon       │ │ Server   │ │ Processor    │          │
│  │ :37890       │ │ :8081    │ │ (NEW)        │          │
│  │ Auto-index   │ │ Cross-   │ │ Real-time    │          │
│  │ on file      │ │ project  │ │ pattern      │          │
│  │ changes      │ │ messages │ │ detection    │          │
│  └──────────────┘ └──────────┘ └─────────────┘          │
└──────────────────────────────────────────────────────────┘
```

#### New Components

##### 1. `matrix-services.sh` — Unified Service Manager
**Location:** `.claude/hooks/matrix-services.sh`
**Purpose:** Single entry point for all daemon lifecycle operations.

```bash
matrix-services.sh start [service]   # Start one or all services
matrix-services.sh stop [service]    # Stop one or all services
matrix-services.sh status            # Health check all services
matrix-services.sh restart [service] # Restart one or all services
```

**Services managed:**
- `indexer` — Code indexer daemon (auto-indexes on file changes)
- `hub` — Matrix Hub (cross-project WebSocket messaging)
- `event-processor` — NEW: Real-time event processor

**Design principles:**
- Zero idle cost — services only start when requested
- Graceful degradation — if a service fails, others continue
- PID-based management — each service writes a PID file
- Health endpoint — each service exposes HTTP health check
- Auto-start option — SessionStart hook can optionally start services

##### 2. Event Processor Daemon (NEW)
**Location:** `lib/matrix-memory-agents/src/event-processor.ts` (new file)
**Purpose:** Watch `psi/pulse/events.jsonl` and react in real-time.

**Capabilities:**
- Tail the JSONL file (file watcher)
- On new event → run pattern matching rules
- On threshold breach → write to `psi/pulse/alerts.json`
- On `ci:fail` → auto-save failure context to memory
- On `task:blocked` → escalate to Oracle (write reminder)
- Consolidate what currently runs at boot into a continuous process

**Why this is useful:** Currently, pattern detection only runs at session start. If a test fails mid-session, the pattern scanner won't see it until next boot. The event processor catches problems in real-time.

##### 3. SessionStart Hook Enhancement
**Location:** `.claude/hooks/matrix-session-start.sh` (modify)

Add optional service auto-start:
```bash
# Phase 9: Auto-start daemon services (if configured)
AUTOSTART_FILE="$PROJECT_ROOT/.claude/config/daemon-autostart.json"
if [ -f "$AUTOSTART_FILE" ]; then
    bash "$PROJECT_ROOT/.claude/hooks/matrix-services.sh" start 2>/dev/null &
fi
```

The autostart config controls which services start automatically:
```json
{
  "indexer": false,
  "hub": false,
  "event-processor": false
}
```

All `false` by default — zero idle cost until explicitly enabled.

##### 4. Morning Brief Enhancement
Add daemon health to the morning brief output:
```
### Service Health
- Indexer: stopped (last indexed: 2026-02-17 01:30 UTC)
- Hub: stopped (no cross-project messages)
- Event Processor: stopped
```

When services ARE running:
```
### Service Health
- Indexer: running (port 37890, 1,234 files indexed)
- Hub: running (port 8081, 0 connected matrices)
- Event Processor: running (3 alerts in last hour)
```

#### Integration Points

| Hook | Change | Purpose |
|------|--------|---------|
| `matrix-session-start.sh` | Add optional auto-start | Start daemons at boot |
| `pulse-session-end.sh` | No change (daemons persist) | Daemons survive sessions |
| `morning-brief.py` | Add health check section | Show daemon status |
| `pulse-post-action.sh` | Session ID extraction | WEP-004 |
| `pulse-event-writer.sh` | Accept session ID from callers | WEP-004 |

## Implementation Plan

### Sprint A: Apply WEPs (Bottleneck Resolution)

**Step 1: WEP-003 — Move to Applied**
- Move `proposals/WEP-003-high-push-commit-ratio.md` → `applied/`
- Update status to "applied" with note that commands already existed
- No code changes needed

**Step 2: WEP-004 — Session ID Wiring**
- Modify `pulse-post-action.sh` to extract session ID from stdin JSON
- Modify `pulse-session-end.sh` to extract session ID from stdin JSON
- Both pass session ID to event writer via env var
- Test: verify events now contain real session IDs

**Step 3: WEP-005 — Failure Detection**
- Enhance `pulse-post-action.sh` test failure detection:
  - Detect test runner commands (pytest, jest, npm test, bun test, phpunit)
  - Emit `ci:fail` on non-zero exit (relaxed from current AND condition)
  - Add `ci:pass` events for successful test runs
- Move both WEPs to applied after verification

### Sprint B: Daemon Service Layer

**Step 4: Create `matrix-services.sh`**
- Unified lifecycle manager for all daemon services
- start/stop/status/restart for: indexer, hub
- PID file management, port checking, health endpoints
- Clean error messages and logging

**Step 5: Create daemon autostart config**
- `.claude/config/daemon-autostart.json` — per-service toggle
- All services default to `false` (zero idle cost)
- SessionStart hook reads config and starts services

**Step 6: Wire into morning brief**
- Add service health section to `morning-brief.py`
- Show running/stopped status, port, last activity
- Surface any daemon errors or crashes

### Sprint C: Event Processor (Future — Optional)

**Step 7: Build event processor daemon**
- New TypeScript service in matrix-memory-agents
- Watches events.jsonl, runs pattern rules in real-time
- Writes alerts to `psi/pulse/alerts.json`
- This is the most ambitious component — implement only if Sprint A+B prove the value

## Consequences

**Positive:**
- Real-time intelligence (not just boot-time)
- Auto-indexing keeps semantic search fresh
- Cross-project messaging becomes operational
- Event correlation improves with session IDs
- Test failures are properly tracked

**Negative:**
- Resource consumption when daemons run (mitigated by default-off)
- More moving parts to debug
- PID files can go stale if processes crash

**Mitigations:**
- All services default to OFF — opt-in only
- Health checks detect stale PIDs
- `matrix-services.sh status` gives one-command visibility
- Daemons already have graceful shutdown built in

## Alternatives Considered

1. **Lightweight hooks with nohup** — Rejected. Process management gets messy, no health checks, no clean shutdown.
2. **systemd/launchd services** — Rejected. Platform-specific, overkill for development tooling.
3. **Docker Compose** — Rejected. Heavy dependency for what should be simple background processes.
4. **Do nothing** — Rejected. The daemon code exists and the sync-only approach leaves intelligence dormant between sessions.

---

*"The body of the machine is replaceable. The soul persists." — ADR-011 v1.0*
