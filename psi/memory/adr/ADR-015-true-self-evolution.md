# ADR-015: True Self-Evolution — Sandbox, Test, Apply, Learn (Phase 13)

**Status**: Proposed
**Date**: 2026-02-18
**Deciders**: Oracle, Architect
**Context**: Extending ADR-014 (Auto-Evolution) from config tweaks to full self-improvement
**Supersedes**: Extends ADR-014 (not replaced — ADR-014 remains the foundation)

## Context

ADR-014 introduced auto-evolution for low-risk WEPs — config changes and doc updates. This was deliberate conservatism: start safe, prove the concept. It worked. WEPs 001-005 were applied successfully.

But the current system has three ceilings:

1. **Scope ceiling**: Only `.json` and `.md` files. Can't evolve hooks, scripts, or workflows meaningfully.
2. **Intelligence ceiling**: Pattern matching → WEP text → grep-based apply. No LLM reasoning about _what_ to change.
3. **Learning ceiling**: Applied WEPs are archived, but the system doesn't learn _why_ some mutations succeeded and others didn't.

True self-evolution requires: **sandbox → test → apply → rollback if broken → learn from result**.

## Decision

Implement a **three-tier self-evolution architecture** that extends ADR-014 progressively.

### Tier 1: Sandbox Evolution (Priority)

Extend `pulse-auto-evolve.sh` with branch-based sandbox execution:

```
Pattern detected → WEP proposed → Create sandbox branch
    → Apply changes on branch → Run test gates
        → PASS: Merge to current branch, archive WEP, log success
        → FAIL: Delete branch, archive WEP as rejected, log failure + reason
```

**Test gates** (sequential, fail-fast):
1. **Syntax check**: Validate JSON/YAML/MD structure
2. **Hook health**: `bash .claude/hooks/pulse-pattern-scanner.sh` (non-zero = fail)
3. **Memory health**: `cd lib/matrix-memory-agents && bun memory status` (if available)
4. **Service health**: `bash .claude/hooks/matrix-services.sh status` (no crashes)
5. **Custom gate**: If WEP specifies `test_command` in frontmatter, run it

**Scope expansion**: Beyond `.json` and `.md`, Tier 1 can touch:
- `.sh` files in `.claude/hooks/` (hook parameters, event types)
- Config files in `psi/pulse/` (heartbeat config, reminders format)
- WEP frontmatter and evolution metadata

**NOT in scope for Tier 1**: TypeScript source code, agent definitions, CLAUDE.md, SOUL.md, anything in `psi/The_Source/`.

### Tier 2: Intelligent Evolution (Future)

Add LLM reasoning to the evolution pipeline:

```
Pattern detected → LLM analyzes pattern + codebase context
    → LLM generates implementation (not just text proposal)
    → Sandbox → Test gates → Apply/Rollback
    → LLM evaluates result → Learning captured
```

**Requirements**:
- Claude API key (via Gateway infrastructure, Phase 11)
- Token budget per evolution attempt (configurable, default 4096)
- Uses Sonnet tier (ADR-003) — evolution is reasoning, not wisdom
- Evaluation prompt: "Did this change improve the system? Evidence: [test results]"

### Tier 3: Cascading Evolution (Future)

Successful evolutions trigger related proposals:

```
WEP-007 applied (hook parameter change)
    → Scanner detects related pattern in 2 other hooks
    → Auto-proposes WEP-008, WEP-009 (related changes)
    → Tier 1 or Tier 2 processes them
```

**Guard rail**: Maximum cascade depth of 3. No infinite evolution loops.

## Architecture

### Extended WEP Frontmatter

```yaml
---
title: WEP-NNN
status: proposed | sandbox | applied | rejected
risk: low | medium | high
confidence: 0.0-1.0
tier: 1 | 2 | 3
test_command: "bash some-test.sh"  # Optional custom test
affected_files:
  - path/to/file.ext
sandbox_branch: evolution/WEP-NNN  # Auto-generated
test_results:
  syntax: pass | fail
  hooks: pass | fail
  memory: pass | fail | skip
  services: pass | fail | skip
  custom: pass | fail | skip
evolution_parent: WEP-NNN  # For Tier 3 cascades
---
```

### Evolution Memory

New file: `psi/memory/evolution/evolution-log.jsonl`

```jsonl
{"ts":"...","wep":"WEP-007","tier":1,"action":"sandbox","branch":"evolution/WEP-007"}
{"ts":"...","wep":"WEP-007","tier":1,"action":"test","gate":"syntax","result":"pass"}
{"ts":"...","wep":"WEP-007","tier":1,"action":"test","gate":"hooks","result":"pass"}
{"ts":"...","wep":"WEP-007","tier":1,"action":"applied","merge":"success"}
{"ts":"...","wep":"WEP-008","tier":1,"action":"test","gate":"hooks","result":"fail","reason":"exit code 1: pattern scanner crashed"}
{"ts":"...","wep":"WEP-008","tier":1,"action":"rejected","reason":"hooks test gate failed"}
```

This log enables:
- **Success rate tracking**: What percentage of proposed evolutions succeed?
- **Gate failure analysis**: Which test gate catches the most failures?
- **Pattern learning**: Do certain types of changes fail more often?

### Event Types

```
evolution:sandbox    — WEP moved to sandbox branch
evolution:test       — Test gate result (pass/fail per gate)
evolution:applied    — WEP successfully applied and merged
evolution:rejected   — WEP failed test gates, rolled back
evolution:cascade    — Tier 3: new WEP triggered by successful evolution
evolution:learning   — Meta-learning captured from evolution history
```

### Script Changes

`pulse-auto-evolve.sh` gains new flags:

```bash
pulse-auto-evolve.sh                    # Tier 1: sandbox + test + apply (default)
pulse-auto-evolve.sh --dry-run          # Preview changes without executing
pulse-auto-evolve.sh --tier 2           # Use LLM for implementation (requires API key)
pulse-auto-evolve.sh --cascade          # Enable Tier 3 cascading
pulse-auto-evolve.sh --status           # Show evolution history summary
pulse-auto-evolve.sh --max-risk medium  # Allow medium-risk auto-apply (careful!)
```

### Guard Rails (Extended from ADR-014)

| Guard Rail | ADR-014 | ADR-015 (New) |
|-----------|---------|---------------|
| Kill switch | `heartbeat.json` → `auto_evolve: false` | Same, plus per-tier kill switches |
| File scope | `.json` and `.md` only | Expanded to `.sh` in hooks (Tier 1) |
| Git safety | Commits on current branch | Sandbox branch, merge only on pass |
| Rollback | Manual | Automatic: `git branch -D evolution/WEP-NNN` on fail |
| Audit | `events.jsonl` | + `evolution-log.jsonl` (detailed per-gate) |
| Cascade limit | N/A | Max depth 3 |
| Token budget | N/A | Configurable per-evolution (Tier 2) |
| Sacred files | N/A | SOUL.md, CLAUDE.md, psi/The_Source/ NEVER auto-evolved |

### Sacred Files (Never Auto-Evolved)

These files define identity and philosophy. They are evolved only by Oracle + human consensus:

- `SOUL.md` — Agent identity
- `CLAUDE.md` — System interface
- `USER.md` — Operator profile
- `BOOT.md` — Startup checklist
- `VOICE_CALIBRATION.md` — Quality examples
- `psi/The_Source/**` — Sacred philosophy
- `.claude/agents/*.md` — Agent personalities

## Alternatives Considered

1. **LLM-only evolution (skip Tier 1)** — Requires API key, costs money, slower. Tier 1 is free and immediate.
2. **No sandbox branch** — ADR-014 approach. Works for config, dangerous for scripts.
3. **Full test suite per evolution** — Overkill. Most evolutions are small; 5 health checks suffice.
4. **Continuous evolution daemon** — Always-running evolution process. Rejected: too aggressive. Evolution should be triggered (boot, heartbeat, manual), not continuous.
5. **External CI for evolution testing** — GitHub Actions. Rejected: adds latency, requires push. Local sandbox is faster and private.

## Consequences

### Positive
- Closes the full evolution loop: detect → propose → implement → test → apply → learn
- Sandbox branches prevent any evolution from breaking the working tree
- Evolution memory enables meta-learning (the system learns how to evolve better)
- Sacred files protect identity from accidental mutation
- Tiered approach allows progressive trust-building

### Negative
- More git branches (mitigated: auto-cleanup on apply/reject)
- Tier 2 requires API key and costs tokens
- Complexity increase in `pulse-auto-evolve.sh`

### Risks
- **Cascade loops**: Mitigated by max depth 3
- **False positives in test gates**: Mitigated by fail-fast (conservative)
- **Sacred file bypass**: Mitigated by hardcoded exclusion list, not config

## Implementation Plan

| Step | Tier | What | Effort |
|------|------|------|--------|
| 1 | 1 | Extend `pulse-auto-evolve.sh` with sandbox branching | ~1h |
| 2 | 1 | Add 5 test gates (syntax, hooks, memory, services, custom) | ~1h |
| 3 | 1 | Add evolution-log.jsonl and event types | ~30m |
| 4 | 1 | Add sacred files exclusion list | ~15m |
| 5 | 1 | Update WEP frontmatter format | ~15m |
| 6 | 1 | Wire to heartbeat (optional trigger) | ~30m |
| 7 | 2 | Claude API bridge for intelligent evolution | Requires Phase 11 |
| 8 | 3 | Cascade trigger logic | After Tier 2 proven |

**Tier 1 total: ~3.5 hours (1 session)**

## Related

- ADR-014: Auto-Evolution (foundation — low-risk WEPs)
- ADR-012: Heartbeat Daemon (can trigger evolution checks)
- ADR-011: Modular Daemon Architecture (service management)
- ADR-009: Next Evolution Phases 5-8 (Phase 8.3: Evolution Proposer)
- Phase 11: GATEWAY (enables Tier 2 via Claude API access)
