```
---
description: Session retrospective - REQUIRED at end of every session
---

# /rrr - Session Retrospective

> Create a session retrospective capturing what happened.

## Steps

1. Gather context from recent activity:
```bash
git log --oneline -20
git diff --stat
```

2. **Summon The Scribe (Skill 1.0)**:
```bash
# Scribe generates the draft from Git reality
FILE=$(./psi/active/scribe_record.sh "session_focus")
echo "Editing $FILE..."
```

3. Write the retrospective with these **Required Sections**:
   - **Session Info** - Date, duration, focus
   - **What Happened** - Actual events (not plans)
   - **Key Decisions** - What was decided and why
   - **AI Diary** - Genuine reflection using the **3 Core Phrases**:
     1. "I assumed X but learned Y..."
     2. "I was confused about X until..."
     3. "I expected X but got Y because..."
   - **Honest Feedback** - Real challenges (Frustrated/Delighted)
   - **Next Actions** - What's next

4. Save with timestamp to `psi/memory/retrospectives/YYYY-MM/DD/HH.MM_[slug].md`:
```bash
TIME_DOT=$(date +"%H.%M")
# Example: psi/memory/retrospectives/2025-12/17/14.30_api_refactor.md
```

## Quality Standards

- **AI Diary**: Minimum 150 words, must be vulnerable
- **Honest Feedback**: Must include friction points
- **No placeholders**: Fill all blanks before saving

## Template Reference

See `templates/retrospective.md` for the full template structure.
