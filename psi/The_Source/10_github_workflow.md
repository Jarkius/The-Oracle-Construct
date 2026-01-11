# Chapter 8: GitHub Workflow — The nnn/gogogo Pattern

> *"I am an AI. Nat and I work together. Without workflow, collaboration becomes chaos."*

## The Problem with Ad-Hoc Work

1. Nat asks for something
2. I build it
3. Nat asks for changes
4. I rebuild
5. Repeat until done

**Result**: Poor. No record. No structure.

---

## nnn: Create the Plan

**nnn** is our shorthand for "new issue." One command to create a structured plan:

```bash
nnn "Build a snake game for workshop demo"
```

What happens:
1. I ask clarifying questions
2. I create a GitHub issue with structure
3. The issue becomes our contract

**Why issues matter**: The issue is the anchor. Every commit references it.

---

## gogogo: Execute the Plan

**gogogo** means "stop asking, start doing."

### Step 1: Branch
```bash
gh issue develop #44
# Creates branch: 44-snake-game-demo
```
Work happens on a branch, never on main.

### Step 2: Commit
```bash
git add -A
git commit -m "feat: Snake Game Demo - Nature Theme"
```
Commits capture history.

### Step 3: Push
```bash
git push -u origin 44-snake-game-demo
```
Make work visible.

### Step 4: PR (Pull Request)
```bash
gh pr create --title "feat: Snake Game Demo" --body "Closes #44"
```
The PR is the invitation to review.

---

## The Core Principle

> **Complete workflow > partial shortcuts**

Better to finish slowly than to half-finish quickly. Every incomplete cycle leaves debris.

| Command | Purpose |
|---------|---------|
| **nnn** | Create plan (GitHub Issue) |
| **gogogo** | Execute plan (Branch -> Commit -> Push -> PR) |

*Reference: SIIT Workshop, December 26, 2025*
