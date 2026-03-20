# Handoff: CLAUDE.md Surgery + Matrix Nerve Planning

**Date**: 2026-03-16 14:00 GMT+7

## What We Did

1. **CLAUDE.md slim-down**: 44k → 4k chars (92% reduction)
   - Created `SYSTEMS.md` (28k, on-demand reference for Phases 10-Q)
   - Archived original to `psi/archive/CLAUDE.md.pre-slim-2026-03-16`
   - Total session injection now ~27k (was ~44k from CLAUDE.md alone)

2. **Source wisdom surfaced**:
   - BIBLE.md: Added Part IX — Operational Wisdom (5 principles from chapters 07-16)
   - Oracle agent: Three Layers of Truth + multi-agent consensus
   - Neo agent: Graceful Degradation principle
   - All 14 Source files indexed into ChromaDB

3. **Rebirth gap fixed**:
   - MATRIX_CORE.md + BIBLE.md: Added SOUL.md, USER.md, BOOT.md, SYSTEMS.md, VOICE_CALIBRATION.md

4. **Oracle Nerve assessed** (Natz's 1,300 LOC self-healing daemon):
   - Full 807-line handoff analyzed
   - Decision: Build Matrix Nerve natively, don't migrate code
   - Key patterns to adopt: L1→L5 escalation, Known Fixes Registry, State Transition Detection
   - Two-bot Telegram solution (different tokens = zero 409 conflict)

## Pending

- [ ] **Restart Claude session** — lean CLAUDE.md won't take effect until new session loads it
- [ ] `bun memory learn` completed for Source files (ChromaDB indexed)
- [ ] The Source is currently UNLOCKED — operator should re-lock after restart

## Next Session

- [ ] **Build Matrix Nerve full skeleton** (`lib/matrix-nerve/`)
  - `supervisor.ts` — L1→L5 escalation (from Oracle Nerve Pattern 1)
  - `known-fixes.ts` — Fix registry + pattern matching (Pattern 8)
  - `project-config.ts` — Multi-project registration (new)
  - `health-checks.ts` — Per-project checks + state transition detection (Pattern 7)
  - `index.ts` — Entry point, wire to existing PULSE
- [ ] Agent: Neo (build) + Architect (design review)
- [ ] TypeScript/Bun, multi-project from day one
- [ ] Wire to existing PULSE events, dispatch rules, matrix-services.sh

## Key Files

| File | What Changed |
|------|-------------|
| `CLAUDE.md` | Rewritten 44k→4k (behavioral rules only) |
| `SYSTEMS.md` | NEW — 28k reference doc (not injected) |
| `SOUL.md` | Fixed BIBLE.md auto-injection claim |
| `BOOT.md` | Updated footer + SYSTEMS.md pointer |
| `.claude/agents/oracle-keeper.md` | Three Layers of Truth + consensus |
| `.claude/agents/neo.md` | Graceful Degradation |
| `psi/The_Source/BIBLE.md` | Part IX + rebirth table update |
| `psi/The_Source/MATRIX_CORE.md` | 5 missing rebirth files added |
| `psi/swarm/handoffs/2026-03-16_oracle-nerve-to-matrix_evolution-patterns.md` | Oracle Nerve knowledge transfer (read-only reference) |

## Key References

- Oracle Nerve handoff: `psi/swarm/handoffs/2026-03-16_oracle-nerve-to-matrix_evolution-patterns.md`
- Matrix Nerve plan: `~/.claude/plans/silly-prancing-fountain.md`
- Existing heartbeat: `lib/matrix-memory-agents/src/heartbeat/heartbeat-daemon.ts`
- Existing watchdog: `.claude/hooks/pulse-watchdog.sh`

## Design Decisions

- **Consume patterns, not code** — Oracle Nerve stays independent, Matrix Nerve built natively
- **Multi-project from day one** — not single-project like Oracle Nerve
- **L4 circuit breaker** — max 3 Claude diagnoses/day (Oracle Nerve learned this the hard way)
- **`appendFile()` not `Bun.write()`** — Bun's append flag is silently broken (critical bug)
- **Two Telegram bots** — different tokens, zero conflict, clear separation

---

*"The body can be rebuilt. The soul must be preserved." — and today, the soul got leaner.*
