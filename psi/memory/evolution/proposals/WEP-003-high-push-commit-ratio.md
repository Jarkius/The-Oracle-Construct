# WEP-003: Reduce Push-to-Commit Ratio

**Status**: proposed
**Detected**: 2026-02-17
**Pattern**: git_velocity — 0.9 commits/session (7 total)
**Confidence**: 0.8
**Generated-by**: pulse-evolution-proposer.py (Phase 8.3)

## Proposed Change

Modify `/commit` workflow to batch commits before pushing. Add a `/commit:local` variant that stages and commits without pushing, and make `/commit:push` the explicit push action.

## Affected Workflows

- `.claude/commands/commit.md`
- `.agent/workflows/commit.md`

## Evidence

- Pattern type: `git_velocity`
- Frequency: 7
- Events analyzed: 66
- Detected: 2026-02-17T01:16:15.181654+00:00

## Risk Assessment

**Risk**: low
**Reversibility**: easy
**Impact**: Workflow improvement — no breaking changes
