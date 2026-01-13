---
description: Commit changes to the Source with Tank's voice
---

# /commit - Commit to the Source

> *Tank - The Operator - "Operator."*

## Purpose

Commit changes to git with Matrix personality. Tank handles all git operations as the internal systems operator.

**Architecture**: Tank (Sonnet) for commit operations — good reasoning at lower cost. See ADR-003.

## Usage

```
/commit              # Commit and push (default)
/commit:push         # Commit and push to remote
/commit:local        # Commit locally only (no push)
/commit "message"    # Commit with custom message
```

## Model Assignment

| Step | Model | Rationale |
|------|-------|-----------|
| Gather (status, diff) | haiku | Mechanical |
| Analyze + Commit | **sonnet** | Good reasoning, cheaper than Opus |

> *Commits need understanding, not just copying. Sonnet writes better messages than Haiku.*

## Process

### 1. Voice Greeting
```bash
sh psi/matrix/voice.sh "Operator. Uploading changes to the Source." "Tank"
```

### 2. Determine Mode

Check the command invocation:
- `/commit` or `/commit:push` → MODE = push
- `/commit:local` → MODE = local

### 3. Spawn Tank (Sonnet) for Commit

Use Task tool to spawn Sonnet for the commit operation:

```
Task:
  subagent_type: Bash
  model: sonnet
  prompt: |
    Commit workflow (MODE = $MODE):

    1. Gather context:
       git status --short
       git diff --stat
       git log --oneline -3

    2. Analyze changes:
       - What type? (feat/fix/docs/refactor/chore)
       - What scope? (component/module affected)
       - What's the summary? (concise description)

    3. Safety checks:
       - No secrets (.env, credentials, keys)
       - Not force pushing
       - Correct branch

    4. Stage and commit:
       git add -A
       git commit -m "<type>(scope): <description>

       <body if needed>

       Co-Authored-By: Claude Sonnet <noreply@anthropic.com>"

    5. Push if MODE = push:
       git push

    6. Report:
       - Commit hash
       - Files changed
       - Push status

    Return structured result.
```

### 4. Announce Completion

**On Success (push mode):**
```bash
sh psi/matrix/voice.sh "Changes uploaded to the Source. The Matrix remembers." "Tank"
```

**On Success (local mode):**
```bash
sh psi/matrix/voice.sh "Changes committed locally. Ready for upload when you are." "Tank"
```

**On Failure:**
```bash
sh psi/matrix/voice.sh "Problem detected. Check the output." "Tank"
```

## Commit Message Format

```
<type>(scope): <description>

<body if needed>

Co-Authored-By: Claude Sonnet <noreply@anthropic.com>
```

**Types:**
- `feat(scope):` — New feature
- `fix(scope):` — Bug fix
- `docs(scope):` — Documentation
- `refactor(scope):` — Code refactoring
- `chore(scope):` — Maintenance
- `perf(scope):` — Performance improvement

## Safety Checks

Before committing:
- [ ] No secrets in staged files (.env, credentials, keys)
- [ ] No force push to main/master
- [ ] Verify branch is correct

## Does NOT Do

- Force push (unless explicitly requested)
- Amend commits that were already pushed
- Skip hooks (--no-verify)

## Token Efficiency

| Approach | Model | Cost |
|----------|-------|------|
| Previous | Opus | $$$ |
| **Current** | **Sonnet** | **$$** |

**Savings**: ~60% on routine commits

## Voice

- **Agent**: Tank (The Operator)
- **Piper Voice**: `en_US-bryce-medium`
- **Personality**: Direct, efficient, technical

## References

- ADR-003: Hierarchical Mind Architecture
- Tank Agent: `.claude/agents/tank.md`

---

*"I know this ship better than anyone. Trust me."* — Tank
