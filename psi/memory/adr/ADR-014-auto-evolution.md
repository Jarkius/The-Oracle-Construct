# ADR-014: Auto-Evolution — Self-Implementing WEPs (Phase 12)

**Status**: Accepted
**Date**: 2026-02-17
**Deciders**: Oracle, Architect
**Context**: Closing the evolution loop (OpenClaw pattern)

## Context

The Evolution Proposer (Phase 8.3) detects patterns and drafts WEP proposals, but stops there. Every WEP requires manual Oracle review and implementation. For low-risk changes (config tweaks, doc updates), this is unnecessary friction.

## Decision

Add a **risk classification** to WEP proposals and an **auto-evolve script** that can self-implement low-risk WEPs without Oracle review.

### Risk Levels

| Level | Auto-implement? | Examples |
|-------|----------------|----------|
| **low** | Yes | Config changes, doc updates, hook parameters, new event types |
| **medium** | No — announce for review | Workflow modifications, morning brief format changes |
| **high** | No — require explicit approval | New services, architecture changes, security, dependencies |

### Auto-Evolve Script

`pulse-auto-evolve.sh` scans `psi/memory/evolution/proposals/` for `risk: low` WEPs and:

1. Parses the proposed changes
2. Executes file edits (config/doc only)
3. Commits with `chore(evolution): auto-apply WEP-NNN`
4. Moves to `applied/`
5. Logs `evolution:auto-applied` event

### Guard Rails

- **Kill switch**: `heartbeat.json` → `"auto_evolve": false` (default: off)
- **Git safety**: Commits on current branch, never force-pushes
- **Audit trail**: Every auto-evolution logged to events.jsonl
- **Scope restriction**: Only touches `.json` and `.md` files
- **Dry-run mode**: `--dry-run` flag shows what would change

## Alternatives Considered

1. **Full auto-apply for all WEPs** — Too dangerous; architecture changes need review.
2. **Never auto-apply** — Status quo; leaves low-hanging fruit untouched.
3. **AI-driven implementation** — Requires Claude API call per WEP; overkill for config changes.

## Consequences

- Closes the pattern → proposal → implementation loop for trivial changes
- Reduces toil for the Operator
- Maintains safety for meaningful changes
- Auto-evolve is OFF by default — opt-in via config

## Related

- ADR-012: Heartbeat Daemon (can trigger auto-evolve on schedule)
- Phase 8.3: Evolution Proposer
