---
description: Morning Brief - synthesize system state into a concise greeting
---

# /morning-brief - The Oracle's Morning Brief

> *"The Matrix has you. But now, you remember."*

## Purpose

Generate a synthesized briefing at session start. Combines all intelligence layers:
- PULSE events since last session
- Pattern analysis from `psi/state/pulse/patterns.json`
- Active tasks from registry
- Pending reminders
- Memory recall from last session

This is Sprint 4.3 — the intelligence layer that makes BOOT.md *smart*.

## Arguments

ARGUMENTS: $ARGUMENTS

## Steps

### 1. Scan Patterns
Run the pattern scanner to get fresh analysis:
```bash
bash .claude/hooks/pulse-pattern-scanner.sh
```

Read `psi/state/pulse/patterns.json` for detected patterns.

### 2. Gather Intelligence

Read these files (silently, don't dump them):
- `psi/state/focus.md` — current mission
- `psi/memory/tasks/active.json` — task registry
- `psi/state/pulse/reminders.json` — pending reminders (if exists)
- `psi/state/pulse/events.jsonl` — last 20 events

### 3. Recall Last Session

Try semantic recall first:
```bash
cd lib/matrix-memory-agents && bun memory recall --last 2>/dev/null
```

Fallback: read latest file in `psi/memory/sessions/`.

### 4. Synthesize Brief

Generate a concise morning brief with this structure:

```
## Morning Brief — [date]

**Focus**: [current mission from focus.md]
**Last session**: [1-line summary of what was accomplished]

### System Pulse
- [N] events since last session ([summary of types])
- [Patterns detected, if any — e.g., "Peak activity at 17:00 UTC"]
- [Failures/blockers, if any]

### Tasks — [N] active
- [Blocked tasks first — highest priority]
- [In-progress tasks]
- [Key pending tasks]

### Reminders
- [Any overdue reminders]

### Recommendation
[What should the operator focus on this session, based on patterns + tasks + focus]
```

### 5. Announce

Use the Oracle voice for the brief:
```bash
sh scripts/voice/voice.sh "Morning brief ready. [1-line summary]" "Oracle"
```

## Rules

- **Be concise** — the brief should fit on one screen
- **Prioritize blockers** — blocked tasks and failures come first
- **Be specific** — "3 commits pushed, Sprint 2 complete" not "some work was done"
- **Make a recommendation** — Oracle doesn't just report, it guides
- **Don't dump raw data** — synthesize, don't regurgitate
