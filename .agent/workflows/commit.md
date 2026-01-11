---
description: Commit changes to the Source with Tank's voice
---

# /commit - Commit to the Source

> *Tank - The Operator - "Operator."*

## Purpose

Commit changes to git with Matrix personality. Tank handles all git operations as the internal systems operator.

## Usage

```
/commit              # Commit and push (default)
/commit:push         # Commit and push to remote
/commit:local        # Commit locally only (no push)
/commit "message"    # Commit with custom message
```

## Voice Greeting

```bash
sh psi/active/voice_module.sh "Operator. Uploading changes to the Source." "Tank"
```

## Process

### 1. Determine Mode

Check the command invocation:
- `/commit` or `/commit:push` → MODE = push
- `/commit:local` → MODE = local

### 2. Gather Context

```bash
# Check status
git status --short

# Check staged and unstaged changes
git diff --stat

# Recent commit style
git log --oneline -3
```

### 3. Stage Changes

```bash
# Stage all changes (or specific files if provided in arguments)
git add -A
```

### 4. Create Commit

- Analyze the changes
- Generate commit message following repo conventions:
  - `feat(scope):` for new features
  - `fix(scope):` for bug fixes
  - `docs(scope):` for documentation
  - `refactor(scope):` for refactoring
  - `chore(scope):` for maintenance
- Include Co-Authored-By trailer

```bash
git commit -m "$(cat <<'EOF'
<type>(scope): <description>

<body if needed>

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

### 5. Push (if MODE = push)

```bash
# Only if mode is push
git push
```

### 6. Announce Completion

**On Success (push mode):**
```bash
sh psi/active/voice_module.sh "Changes uploaded to the Source. The Matrix remembers." "Tank"
```

**On Success (local mode):**
```bash
sh psi/active/voice_module.sh "Changes committed locally. Ready for upload when you are." "Tank"
```

**On Failure:**
```bash
sh psi/active/voice_module.sh "Problem detected. Check the output." "Tank"
```

## Safety Checks

Before committing:
- [ ] No secrets in staged files (.env, credentials, keys)
- [ ] No force push to main/master
- [ ] Verify branch is correct

## Does NOT Do

- ❌ Force push (unless explicitly requested)
- ❌ Amend commits that were already pushed
- ❌ Skip hooks (--no-verify)

## Voice

- **Agent**: Tank (The Operator)
- **Piper Voice**: `en_US-bryce-medium`
- **Personality**: Direct, efficient, technical

---

*"I know this ship better than anyone. Trust me."* — Tank
