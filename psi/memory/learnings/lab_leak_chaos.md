# Learning: The Lab Leak Chaos

**Date Recorded**: 2026-01-10
**Source**: Operator (Jarkius)
**Reference**: Git Issue #6

## Context
In the past, experimental features from `psi/lab/` "leaked" into the core Matrix without sufficient isolation or approval.

## The Chaos
This premature integration caused system instability and "chaos," forcing a rollback or major stabilization effort.
The specific mechanism of failure was likely:
- Unstable dependencies
- Conflicting logic (e.g., Voice Tray vs Core Voice Module)
- Context pollution

## The Lesson
> "The Lab is for observation, not integration."

Safety requires strict separation. The `active_protocols.md` (Protocol 0xD5) exists to prevent a recurrence of Issue #6.
Evolution must be deliberate, not accidental.
