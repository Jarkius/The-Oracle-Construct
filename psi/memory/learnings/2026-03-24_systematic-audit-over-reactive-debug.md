# Lesson: Systematic Audits Beat Reactive Debugging

**Date**: 2026-03-24
**Source**: rrr — audit plan + component dashboard session
**Tags**: audit, methodology, infrastructure, quality

## Context

After finding 24 broken path references by chasing a symptom ("why does the Matrix feel degraded?"), the Operator asked: shouldn't we audit every component systematically? The answer was yes — a layered audit framework (L-1 through L7, 67 components) was designed and an interactive HTML dashboard created for tracking.

## Lesson

When a system has grown to 89 hooks, 6 daemons, 10 modules, and 49 workflows:
1. **Reactive debugging finds one problem** — you fix the symptom but miss the other 23 broken refs
2. **Systematic auditing finds them all** — layer by layer, dependency-first
3. **Visual tracking accelerates completion** — clickable HTML dashboards > markdown checklists
4. **Foundation first** — if L-1 (platform) fails, everything above is moot

## Applied

- Created 8-layer audit plan with 67 checkpoints
- Built interactive matrix-audit.html dashboard
- Registered as task-0014 in active.json
