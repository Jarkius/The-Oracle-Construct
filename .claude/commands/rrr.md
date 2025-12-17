# /rrr - Session Retrospective

Create a session retrospective capturing what happened.

## Usage

```
/rrr              # Create retrospective for current session
```

## Output Location

`psi/memory/retrospectives/YYYY-MM/DD/HH.MM_[slug].md`

## Required Sections

1. **Session Info** - Date, duration, focus
2. **What Happened** - Actual events (not plans)
3. **Key Decisions** - What was decided and why
4. **AI Diary** - Genuine reflection
5. **Honest Feedback** - Real challenges
6. **Next Actions** - What's next

## Process

1. Gather context:
   ```bash
   git log --oneline -20
   git diff --stat
   ```

2. Create directory:
   ```bash
   YEAR_MONTH=$(date +"%Y-%m")
   DAY=$(date +"%d")
   mkdir -p "psi/memory/retrospectives/${YEAR_MONTH}/${DAY}"
   ```

3. Write retrospective using template

4. Save with timestamp:
   ```bash
   TIME_DOT=$(date +"%H.%M")
   # psi/memory/retrospectives/YYYY-MM/DD/HH.MM_slug.md
   ```

## Quality Standards

- **AI Diary**: Minimum 150 words, must be vulnerable
- **Honest Feedback**: Must include friction points
- **No placeholders**: Fill all blanks before saving

## Template

See `templates/retrospective.md` for full template.
