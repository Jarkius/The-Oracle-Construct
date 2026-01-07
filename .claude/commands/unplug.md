# /unplug - Graceful Exit from the Matrix

> *The Oracle - "Remember... all I'm offering is the truth."*

Graceful shutdown sequence. Ensures nothing is lost before the Operator leaves the Matrix.

## Usage

```
/unplug              # Prepare to exit, capture everything
/unplug quick        # Fast exit, minimal capture
```

## Voice Greeting
```bash
.claude/hooks/play-tts.sh "You're leaving the Matrix. Let me capture everything before you go."
```

## Process

### Step 1: Check Uncommitted Work
```bash
git status --short
git diff --stat
```

If uncommitted changes exist, offer:
- [c] Commit them now
- [s] Stash for later
- [l] Leave as-is

### Step 2: Update Focus
Update `psi/inbox/focus.md` with:
```markdown
**Last Session**: [date] @ [time] - [brief summary]
**Handoff**: Active

## Next Session Priorities
- [ ] [What to do next]
- [ ] [Pending items]
```

### Step 3: Auto-Capture Retrospective
- Check if retrospective exists for this session
- If NO retrospective: AUTO-RUN `/rrr` to create one
- Save to `psi/memory/retrospectives/YYYY-MM/DD/HH.MM_unplug.md`

**MANDATE**: ALWAYS create retrospective before exit - no exceptions

### Step 4: Final Summary
Display:
```markdown
## Unplug Summary

**Session Duration**: [estimate]
**Focus**: [what was worked on]

### Completed
- [List of completed items]

### In Progress
- [List of pending items]

### For Next Session
- [Priority items]

**Uncommitted**: [status]
**Retrospective**: [saved/skipped]
**Focus Updated**: Yes
```

### Step 5: Farewell
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
UNPLUGGED

"There is no spoon." — The Boy

See you in the next session.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Quick Mode (/unplug quick)

Skip confirmations:
- Auto-update focus.md
- Auto-create retrospective (no prompt)
- Display brief summary
- Exit immediately

## Voice

Oracle speaks the farewell. Calm, nurturing, prophetic.

ARGUMENTS: $ARGUMENTS
