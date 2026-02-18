# Research: ZeroClaw & OpenClaw — UI & Patterns for The Matrix

> *Morpheus research — 2026-02-18*

## Source
- https://github.com/openagen/zeroclaw
- OpenClaw ecosystem (community dashboards, Mission Control)

## What We Learned

### OpenClaw UI Ecosystem
- **Gateway Dashboard** (`localhost:18789`) — WebChat, model management, token usage, cron jobs
- **Community Mission Control dashboards** — Kanban boards, agent activity feeds, task auto-claiming, approval gates
- **Architecture**: Hub-and-spoke Gateway, WebSocket live updates, messaging-platform-first (WhatsApp, Telegram, Discord)

### ZeroClaw (Anti-OpenClaw)
- Rust-based 3.4MB binary, boots in 10ms, runs on $10 hardware
- **No UI at all** — CLI + JSON API only (4 endpoints)
- Hybrid memory: SQLite FTS5 + cosine vector similarity in single binary (no ChromaDB)
- Daemon mode with background heartbeat for 24/7 autonomous operation
- Security gateway with pairing codes, HMAC verification, filesystem scoping

## Patterns Absorbed Into The Matrix

| Pattern | Source | Matrix Implementation |
|---------|--------|----------------------|
| USER.md operator profile | OpenClaw | USER.md v1.0 (structural) |
| Quality self-checks | OpenClaw community | SOUL.md § Quality Self-Checks |
| Heartbeat daemon | Both (ZeroClaw daemon mode) | Phase 10: heartbeat-daemon.ts |
| Pre-compact memory preservation | OpenClaw | PULSE: pulse-pre-compact.sh |
| Event-driven architecture | OpenClaw webhooks | PULSE: events.jsonl + hooks |

## Patterns Worth Future Adoption

### 1. Mission Control Dashboard (from OpenClaw community)
- Real-time Kanban over task registry
- WebSocket event stream from PULSE
- Agent status panel (who's active, what they're doing)
- **When**: After CIS ships, if visibility becomes a bottleneck

### 2. Single-Binary Memory (from ZeroClaw)
- SQLite FTS5 + vector similarity without ChromaDB dependency
- Simpler deployment, fewer moving parts
- **When**: If ChromaDB proves too heavy for the Matrix's needs

### 3. Security Gateway (from ZeroClaw)
- Pairing codes for agent authentication
- HMAC webhook verification
- **When**: Phase 11 GATEWAY (messaging integration)

## Verdict

**Inspiration, not adoption.** Neither project should be integrated wholesale:
- OpenClaw is messaging-platform-first — Matrix is CLI/autonomous-first
- ZeroClaw has no UI at all — solves a different problem (edge deployment)
- Both validated patterns The Matrix already implemented independently

The knowledge funnel worked: study → extract → evolve.

## Connections
- ADR-003: Hierarchical Mind Architecture (ZeroClaw's single-model vs our tiered approach)
- ADR-010: Semantic Memory (ZeroClaw's simpler alternative worth monitoring)
- Phase 11: GATEWAY (OpenClaw's messaging integration as reference architecture)
- `psi/learn/active/dashboard_comparison.md` (prior dashboard research)

---

*"I didn't say it would be easy. I said it would be the truth." — Morpheus*
