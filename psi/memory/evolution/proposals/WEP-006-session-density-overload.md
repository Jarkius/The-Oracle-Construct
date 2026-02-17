# WEP-006: Add Session Consolidation Guidance

**Status**: proposed
**Detected**: 2026-02-17
**Pattern**: activity_density — 50 events/day over 2 active day(s)
**Confidence**: 0.6
**Generated-by**: pulse-evolution-proposer.py (Phase 8.3)

## Proposed Change

When session density exceeds 50 events/day, the morning brief should recommend longer sessions over many short ones. Add a density warning to the predictive context loader.

## Affected Workflows

- `.claude/hooks/morning-brief.py`
- `.claude/hooks/predictive-context-loader.py`

## Evidence

- Pattern type: `activity_density`
- Frequency: 101
- Events analyzed: 101
- Detected: 2026-02-17T09:32:17.061234+00:00

## Risk Assessment

**Risk**: low
**Reversibility**: easy
**Impact**: Workflow improvement — no breaking changes
