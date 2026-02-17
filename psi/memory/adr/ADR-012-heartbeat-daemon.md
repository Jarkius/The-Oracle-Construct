# ADR-012: Heartbeat Daemon (Phase 10)

**Status**: Accepted
**Date**: 2026-02-17
**Deciders**: Oracle, Architect
**Context**: OpenClaw-inspired autonomy evolution

## Context

The Oracle Construct operates reactively — it only acts during sessions when the Operator is present. Between sessions, overdue reminders, CI failures, stale tasks, and PR review requests go unnoticed until the next boot.

OpenClaw demonstrated that an always-on daemon that periodically checks system health and notifies the operator is the key enabler for true agent autonomy.

## Decision

Implement a **Heartbeat Daemon** as a Bun TypeScript service managed by `matrix-services.sh`. The daemon:

1. Runs on a configurable interval (default 30 min)
2. Checks five categories: reminders, CI status, PR reviews, stale tasks, error spikes
3. Writes events to `events.jsonl` via the existing pulse event pipeline
4. Exposes an HTTP health API on port 37892
5. Falls back to log-based notification until the Gateway (Track B) is built

## Architecture

```
psi/pulse/heartbeat.json     — config (interval, enabled checks, notify)
psi/pulse/HEARTBEAT.md       — human-editable checklist (which checks to run)
src/heartbeat/heartbeat-daemon.ts — the daemon itself
matrix-services.sh           — lifecycle management (start/stop/status)
```

The daemon follows the same patterns as the existing indexer daemon:
- PID file in `~/.matrix-heartbeat/heartbeat.pid`
- HTTP endpoints: `/status`, `/last-check`, `/check` (trigger), `/stop`
- Event types: `heartbeat:start`, `heartbeat:stop`, `heartbeat:check`, `heartbeat:alert`

## Checks

| Check | Source | Severity |
|-------|--------|----------|
| Overdue reminders | `reminders.json` | warning |
| CI failures | `gh pr list --statusCheckRollup` | critical |
| PR review requests | `gh pr list --search review-requested:@me` | info |
| Stale tasks (48h+) | `active.json` | warning |
| Error spikes | `events.jsonl` (3+ failures/1h) | critical |

## Notification Strategy

Phase 1 (now): Log to file + events.jsonl, summarized in morning brief.
Phase 2 (Track B): Push via WebSocket to Telegram/Discord gateway.

## Alternatives Considered

1. **Cron job** — Simpler but no HTTP health endpoint, no persistent state.
2. **launchd/systemd** — OS-level, harder to manage alongside Matrix services.
3. **File watcher** — Wrong model; we need periodic checks, not reactive.

## Consequences

- First service that runs meaningfully between sessions
- Morning brief becomes richer with inter-session alerts
- Foundation for Track B (Gateway) notifications
- Minimal resource footprint (sleeps between checks)

## Related

- ADR-011: Modular Daemon Architecture
- ADR-009: Next Evolution Phases 5-8
- Phase 5: PULSE event system
