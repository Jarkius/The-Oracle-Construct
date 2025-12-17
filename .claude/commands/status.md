# /status - System Status Check

> "The Matrix has you."

*The Operator - sees all feeds, knows all exits.*

## Purpose

Quick health check of project state. The Operator sees everything from the chair.

## Usage

```
/status          # Full status report
```

## Checks

1. **Git Status**
   ```bash
   git status --short
   git log --oneline -5
   ```

2. **Current Focus**
   - Read `psi/inbox/focus.md`

3. **Memory State**
   ```bash
   ls psi/memory/retrospectives/ 2>/dev/null | tail -3
   ls psi/memory/learnings/ 2>/dev/null | tail -3
   ```

4. **Recent Activity**
   - Files modified today
   - Uncommitted changes

## Output Format

```markdown
## Status Report - [Date] [Time]

**Branch**: [current branch]
**Focus**: [current focus item]
**Changes**: [staged/unstaged count]

**Recent Commits**:
- [commit 1]
- [commit 2]

**Memory**: [X] retrospectives, [Y] learnings

**Health**: Good / Needs Attention / Critical
```
