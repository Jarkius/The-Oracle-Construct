---
description: Rest, Reflect, Record - session shutdown and documentation
---

# /rrr - Session Retrospective

> *The Scribe - "Everything that has a beginning has an end."*

Create a session retrospective capturing what happened.

## Usage

```
/rrr              # Create retrospective for current session
```

## Voice Greeting
```bash
sh psi/active/voice_module.sh "Recording session memory. What happened today?" "System"
```

## Output Location

`psi/memory/retrospectives/YYYY-MM/DD/HH.MM_[slug].md`

## Required Sections

1. **Session Info** - Date, duration, focus
2. **What Happened** - Actual events (not plans)
3. **Key Decisions** - What was decided and why
4. **AI Diary** - Genuine reflection using the **3 Core Phrases**:
   - "I assumed X but learned Y..."
   - "I was confused about X until..."
   - "I expected X but got Y because..."
5. **Honest Feedback** - Real challenges (Frustrated/Delighted)
6. **Next Actions** - What's next

## Process

1. Gather context:
   ```bash
   git log --oneline -20
   git diff --stat
   ```

2. **Summon The Scribe**:
   ```bash
   ./psi/active/scribe_record.sh "slug"
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
