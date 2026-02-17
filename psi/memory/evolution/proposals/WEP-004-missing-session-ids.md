# WEP-004: Wire Session IDs into Event Pipeline

**Status**: proposed
**Detected**: 2026-02-17
**Pattern**: session_rhythm — Peak activity at 17:00 UTC (4 sessions)
**Confidence**: 0.5
**Generated-by**: pulse-evolution-proposer.py (Phase 8.3)

## Proposed Change

Over 50% of events have session="unknown". Wire the Claude session ID from the transcript path into pulse-event-writer.sh so events can be correlated to specific sessions for better pattern analysis.

## Affected Workflows

- `.claude/hooks/pulse-event-writer.sh`
- `.claude/hooks/pulse-post-action.sh`

## Evidence

- Pattern type: `session_rhythm`
- Frequency: 4
- Events analyzed: 66
- Detected: 2026-02-17T01:16:15.181654+00:00

## Risk Assessment

**Risk**: low
**Reversibility**: easy
**Impact**: Workflow improvement — no breaking changes
