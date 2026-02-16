# Workflow Evolution Proposals (WEPs)

> *"Everything that has a beginning has an end. But evolution persists."*

## Purpose

This directory holds **Workflow Evolution Proposals** (WEPs) — automatically generated
suggestions for improving workflows based on pattern analysis.

## How It Works

1. **Detection**: After `/rrr` retrospectives, Scribe analyzes workflow success rates
2. **Pattern Match**: The pattern scanner identifies recurring issues (e.g., workflow bypassed, repeated failures)
3. **Proposal**: A WEP is drafted in `proposals/` with the detected pattern and proposed change
4. **Review**: Oracle reviews before any proposal is applied
5. **Archive**: Applied proposals move to `applied/`, rejected to `rejected/`

## WEP Format

```markdown
# WEP-NNN: [Title]

**Status**: proposed | approved | applied | rejected
**Detected**: [date]
**Pattern**: [what was observed]
**Confidence**: [0-1]
**Proposed Change**: [what should change]
**Affected Workflows**: [list of workflow files]
**Risk**: low | medium | high
```

## Directories

- `proposals/` — New proposals awaiting review
- `applied/` — Proposals that were implemented
- `rejected/` — Proposals that were rejected (with reason)

## Rules

- **Oracle approves all WEPs** — no auto-apply
- **Proposals are specific** — "change X in Y" not "improve things"
- **Evidence required** — every WEP cites the pattern that triggered it
- **Nothing Is Deleted** — rejected proposals are archived with reason
