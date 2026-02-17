# WEP-005: Add CI/Test Failure Detection to Post-Action Hook

**Status**: applied
**Applied**: 2026-02-17
**Implementation**: Test runner detection (pytest, jest, vitest, bun test, phpunit, mocha, cargo test, go test). Emits ci:fail on non-zero exit, ci:pass on success. Non-test failures with keywords also caught.
**Detected**: 2026-02-17
**Pattern**: git_velocity — 0.9 commits/session (7 total)
**Confidence**: 0.8
**Generated-by**: pulse-evolution-proposer.py (Phase 8.3)

## Proposed Change

No ci:fail events detected despite 30+ events. Either tests always pass (unlikely) or the post-action hook does not detect test failures. Enhance pulse-post-action.sh to parse test runner output for failures and emit ci:fail events.

## Affected Workflows

- `.claude/hooks/pulse-post-action.sh`

## Evidence

- Pattern type: `git_velocity`
- Frequency: 7
- Events analyzed: 66
- Detected: 2026-02-17T01:16:15.181654+00:00

## Risk Assessment

**Risk**: low
**Reversibility**: easy
**Impact**: Workflow improvement — no breaking changes
