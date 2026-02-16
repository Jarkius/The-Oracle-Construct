# WEP-002: Agent Definition Quality Gate

**Status**: proposed
**Detected**: 2026-02-16
**Pattern**: Agent definitions vary from 600 bytes (Scribe) to 2500+ bytes (Trinity). Inconsistent structure causes weak agent embodiment.
**Confidence**: 0.85

## Problem

Agent definition quality directly impacts how well agents are embodied. When Scribe's definition was 23 lines with no skills, triggers, or critical actions, sessions that invoked Scribe got generic behavior instead of the Historian personality.

Trinity (5/5) proves that a complete definition with Menu, Auto-Triggers, Critical Actions, Philosophy, and Does NOT Do sections produces sharp, differentiated agents.

## Proposed Change

Establish a **minimum structure** for agent definitions. Every `.claude/agents/*.md` must include:

1. **Frontmatter** — name, role, voice, skills list
2. **Nature** — 3 bullet points: identity, role, boundary
3. **Function** — what the agent does (not what it is)
4. **Menu** — trigger table mapping skills to descriptions
5. **Auto-Trigger** — natural language → skill mapping
6. **Critical Actions** — ALWAYS/NEVER rules
7. **Does NOT Do** — explicit boundaries
8. **Voice** — Piper voice config + persona description

## Quality Scores (Audit)

| Agent | Score | Status |
|-------|-------|--------|
| Trinity | 5.0/5 | Gold standard |
| Oracle | 4.5/5 | Missing auto-triggers |
| Smith | 4.5/5 | Missing review rubric |
| Morpheus | 4.5/5 | MCP refs need verification |
| Tank | 4.5/5 | context-finder vague |
| Architect | 4.0/5 | Missing readiness criteria |
| Neo | 4.0/5 | Thin personality, no code philosophy |
| Scribe | 1.5/5 | Rebuilt to ~4.5 (2026-02-16) |

## Affected Workflows

- `.claude/agents/*.md` (all 8 agent definitions)
- `/health` workflow (could include agent quality check)

## Evidence

- Scribe was 600 bytes with no skills, triggers, or actions
- Trinity at 2500+ bytes with full structure produces the best embodiment
- Agent Teams (Issue #24316) will eventually use these definitions as teammate configs
- Investment now pays dividends when agents become spawnable teammates

## Risk Assessment

**Risk**: low
**Reversibility**: easy — definitions are markdown files
**Impact**: All 8 agents; most critical for Scribe (fixed), Neo, Architect
