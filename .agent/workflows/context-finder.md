---
description: Search git history, retrospectives, issues, and codebase for context
---

# /context-finder - Search Context

> Tank's fast search through git history, retrospectives, issues, and codebase.

## Usage

```
/context-finder [query]
```

## Action

Use the Task tool with subagent_type `Explore`:

```
subagent_type: Explore
model: haiku
prompt: |
  Search for context about: $ARGUMENTS

  Run these commands:
  1. git log --oneline --all --grep="$ARGUMENTS" -10
  2. git log --oneline -20 | grep -i "$ARGUMENTS" || true
  3. Find files mentioning the topic
  4. Check psi/memory/retrospectives/ folders

  Return compact summary of what you found.
```

If no arguments provided, show recent context:
- Last 10 commits
- Recent retrospectives
- Open issues

## Search Sources

| Source | What It Finds |
|--------|---------------|
| Git history | Commits mentioning query |
| Files | Code containing query |
| Retrospectives | Past session notes |
| Issues | GitHub discussions |

## Examples

```
/context-finder auth        # Find auth-related code and history
/context-finder voice       # Find voice system references
/context-finder             # Show recent context (no query)
```

ARGUMENTS: $ARGUMENTS
