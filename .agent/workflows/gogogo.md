---
description: Start the development cycle - automated build and test
---

# /gogogo - Execute the Plan

> *"Stop asking, start doing."*

**Utility Tool** - Available to all agents

## Purpose

**gogogo** executes the full git workflow: Branch -> Commit -> Push -> PR. No half-measures.

## Usage

```
/gogogo #44           # Execute workflow for issue #44
/gogogo               # Execute for current branch
```

## Tool Info
- **Type**: Utility (no voice, no spawn)
- **Available to**: All agents (Neo, Architect, etc.)
- **Purpose**: Complete git workflow cycle

## The Protocol

### Step 1: Branch (if needed)
```bash
# Create branch from issue
gh issue develop #[issue_number]
# Creates: [issue_number]-[slug]
```

### Step 2: Commit
```bash
git add -A
git commit -m "[type]: [description]

Closes #[issue_number]

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

### Step 3: Push
```bash
git push -u origin [branch_name]
```

### Step 4: Pull Request
```bash
gh pr create --title "[type]: [description]" --body "$(cat <<'EOF'
## Summary
[What this PR does]

## Changes
- [Change 1]
- [Change 2]

## Testing
- [ ] Test 1
- [ ] Test 2

Closes #[issue_number]

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

## Core Principle

> **Complete workflow > partial shortcuts**

Better to finish slowly than to half-finish quickly. Every incomplete cycle leaves debris.

| Step | Command | Purpose |
|------|---------|---------|
| 1 | `gh issue develop` | Create branch |
| 2 | `git commit` | Capture work |
| 3 | `git push` | Make visible |
| 4 | `gh pr create` | Invite review |

*Reference: The_Source/08_github_workflow.md*
