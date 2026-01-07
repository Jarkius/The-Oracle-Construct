---
description: No-Nonsense Notes - quick logging to daily journal
---

# /nnn - New Issue Plan

> *"Create the plan before the work."*

**Utility Tool** - Available to all agents

## Purpose

**nnn** creates a structured GitHub issue as the contract for work. One command to plan.

## Usage

```
/nnn "Build a snake game for workshop demo"
/nnn "Fix authentication bug in login flow"
```

## Tool Info
- **Type**: Utility (no voice, no spawn)
- **Available to**: All agents (Oracle, Neo, Architect, etc.)
- **Purpose**: Create GitHub issue as work anchor

## The Protocol

### 1. Clarify Requirements
Ask clarifying questions:
- What is the goal?
- What are the constraints?
- What does "done" look like?

### 2. Create GitHub Issue
```bash
gh issue create --title "[type]: [description]" --body "$(cat <<'EOF'
## Summary
[Brief description]

## Requirements
- [ ] Requirement 1
- [ ] Requirement 2

## Acceptance Criteria
- [ ] Criteria 1
- [ ] Criteria 2

## Notes
[Additional context]
EOF
)"
```

### 3. Confirm the Contract
The issue number becomes the anchor. Every commit references it.

## Core Principle

> **Plan first, execute second.**

The issue is the contract between human and AI.

| Step | Action |
|------|--------|
| 1 | Ask clarifying questions |
| 2 | Create structured issue |
| 3 | Return issue number |

*Reference: The_Source/08_github_workflow.md*
