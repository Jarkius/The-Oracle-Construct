---
description: Workflow Evolution - analyze patterns and propose workflow improvements
---

# /evolve - Self-Evolving Workflow Proposals

> *"Evolution demands rupture. The former self must be allowed to die."*

## Purpose

Analyze detected patterns and retrospectives to generate Workflow Evolution Proposals (WEPs).
This is Sprint 4.4 — the system that helps the Matrix improve itself.

## Arguments

ARGUMENTS: $ARGUMENTS

## Steps

### 1. Gather Evidence

Read pattern data:
```bash
bash .claude/hooks/pulse-pattern-scanner.sh
```
Read `psi/pulse/patterns.json` for detected patterns.

Read recent retrospectives from `psi/memory/retrospectives/` (last 5).
Read recent session memories from `psi/memory/sessions/` (last 5).

### 2. Identify Improvement Opportunities

Look for these signals:
- **Workflow bypass**: A workflow exists but agents consistently skip it
- **Repeated failures**: Same type of error across multiple sessions
- **Missing workflow**: A task pattern that has no workflow but should
- **Slow workflow**: Steps that could be automated or parallelized
- **Scope creep**: Focus changes that indicate unclear boundaries

### 3. Draft WEP

For each identified opportunity, create a WEP file:

```bash
# Generate WEP ID (increment from existing)
ls psi/memory/evolution/proposals/
```

Create `psi/memory/evolution/proposals/WEP-NNN-<slug>.md`:

```markdown
# WEP-NNN: [Title]

**Status**: proposed
**Detected**: [today's date]
**Pattern**: [what was observed — cite specific evidence]
**Confidence**: [0.0-1.0 based on pattern strength]

## Proposed Change

[Specific, actionable change to a workflow or process]

## Affected Workflows

- [list of .agent/workflows/*.md or .claude/hooks/*.sh files]

## Evidence

- Pattern: [from patterns.json]
- Sessions: [which sessions showed this pattern]
- Frequency: [how often]

## Risk Assessment

**Risk**: low | medium | high
**Reversibility**: [easy | moderate | hard]
**Impact**: [which agents/workflows affected]

## Recommendation

[Oracle's recommendation — approve, investigate further, or reject with reason]
```

### 4. Announce

```bash
sh psi/matrix/voice.sh "Evolution proposal drafted. Review when ready." "Oracle"
```

### 5. Handle Existing WEPs

If `$ARGUMENTS` includes "review":
- List all proposals in `psi/memory/evolution/proposals/`
- For each, summarize: title, pattern, confidence, risk
- Ask Oracle for approve/reject decision

If `$ARGUMENTS` includes "apply WEP-NNN":
- Read the proposal
- Implement the proposed change
- Move to `psi/memory/evolution/applied/`
- Update status to "applied"

If `$ARGUMENTS` includes "reject WEP-NNN":
- Move to `psi/memory/evolution/rejected/`
- Add rejection reason

## Rules

- **Never auto-apply** — all WEPs require Oracle review
- **Be specific** — vague proposals waste time
- **Cite evidence** — every WEP needs data, not opinion
- **One change per WEP** — keep proposals atomic
- **Nothing Is Deleted** — rejected proposals are archived
