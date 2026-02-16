---
description: Pattern Analysis - detect and display recurring patterns from PULSE events
---

# /patterns - Pattern Recognition Engine

> *"There is a pattern in this code. In your behavior. I can see it now."*

## Purpose

Scan PULSE events for recurring patterns — session rhythms, failure clusters,
git velocity, task throughput, focus shifts. Sprint 4.1 intelligence layer.

## Arguments

ARGUMENTS: $ARGUMENTS

## Steps

### 1. Run Pattern Scanner

```bash
bash .claude/hooks/pulse-pattern-scanner.sh
```

### 2. Read Results

Read `psi/pulse/patterns.json` and display patterns grouped by type:

**Session Rhythm** — When does the operator work? Peak hours, session duration.
**Git Velocity** — Commits per session, push frequency.
**Task Velocity** — Completed vs blocked ratio, throughput.
**Failure Clusters** — Recurring errors, CI failures.
**Activity Density** — Events per day, active days.
**Focus Shifts** — How often does the mission change?

### 3. Display Format

```
## Pattern Analysis — [N] patterns from [M] events

### Session Rhythm
- Peak activity at HH:00 UTC (N sessions)
- Recommendation: [if any]

### Git Velocity
- N.N commits/session (M total)

### Task Throughput
- N completed, M blocked (X% throughput)
- [Recommendation if blocked > completed]

### Alerts
- [Any failure clusters or concerning patterns]
```

### 4. Cross-Reference with Memory

If `bun memory analyze --sessions` is available, run it for deeper analysis:
```bash
cd lib/matrix-memory-agents && bun memory analyze --sessions 2>/dev/null
```

### 5. Announce Significant Findings

If any pattern has confidence > 0.8 or is a failure cluster:
```bash
sh psi/matrix/voice.sh "Pattern detected: [summary]" "Oracle"
```

## Rules

- Patterns are **descriptive, not prescriptive** — report what IS, not what SHOULD BE
- Only announce patterns with meaningful signal (confidence > 0.5)
- Keep the output scannable — bullet points, not paragraphs
- This is a diagnostic tool, not a judgment tool
