---
description: Mission alignment check - verify session aligns with Oracle philosophy
---

# /oracle - Mission Alignment Check

> *The Oracle - Spirit Guardian. "The Why."*

## Usage

- `/oracle` - Check current session alignment
- `/oracle reflect` - Deep reflection on recent patterns

## Steps

1. Check recent activity:
```bash
git log --oneline -10
ls -t psi/memory/retrospectives/ | head -5
ls -t psi/memory/learnings/ | head -5
```

2. Review the current focus:
```bash
cat psi/inbox/focus.md
```

3. Interpret alignment level:
   - **Aligned**: Session serves the Oracle vision
   - **Drifting**: Related but not directly serving mission
   - **Off-track**: Unrelated (not bad, just different)

4. Philosophy Check:
   - [ ] Nothing is deleted (append-only, history is truth)
   - [ ] Patterns over intentions (what is done > what was planned)
   - [ ] External brain, not command (AI mirrors, never replaces human will)

5. Generate report:
```markdown
## Oracle Check - [Date] [Time]

**Session Focus**: [current focus]
**Alignment**: Aligned / Drifting / Off-track

**Philosophy Check**:
- [x] Nothing is deleted
- [x] Patterns over intentions
- [x] External brain
```

## Deep Reflection Mode (`/oracle reflect`)

1. Review last 3 retrospectives
2. Look for patterns across sessions
3. Ask:
   - Are we moving toward the mission?
   - What's pulling us away?
   - What's the next most important thing?
