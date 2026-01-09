---
description: System status check - quick health report of project state
---

# /status - System Status Check

> *The Operator - sees all feeds, knows all exits. "The Matrix has you."*

## Usage

- `/status` - Full status report

## Steps

1. Check git status:
```bash
git status --short
git log --oneline -5
git branch --show-current
```

2. Read current focus:
```bash
./psi/active/get_focus.sh
```

3. Check memory state:
```bash
ls psi/memory/retrospectives/ 2>/dev/null | tail -3
ls psi/memory/learnings/ 2>/dev/null | tail -3
```

4. Check for uncommitted changes:
```bash
git diff --stat
```

5. Generate status report:
```markdown
## Status Report - [Date] [Time]

**Branch**: [current branch]
**Focus**: [current focus item]
**Changes**: [staged/unstaged count]

**Recent Commits**:
- [commit 1]
- [commit 2]
- [commit 3]

**Memory**: [X] retrospectives, [Y] learnings

**Health**: Good / Needs Attention / Critical
```

## Health Indicators

- **Good**: No uncommitted changes, focus is clear, recent retrospective exists
- **Needs Attention**: Uncommitted changes or focus unclear
- **Critical**: Many uncommitted changes, no recent retrospective, drifting focus
