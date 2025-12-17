# /oracle - Mission Alignment Check

Check if current session aligns with Oracle philosophy.

## Usage

```
/oracle              # Check current session
/oracle reflect      # Deep reflection
```

## Steps

1. **Check Recent Activity**:
   ```bash
   git log --oneline -10
   ls -t psi/memory/retrospectives/ | head -5
   ls -t psi/memory/learnings/ | head -5
   ```

2. **Interpret Alignment**:
   - Aligned: Session serves the Oracle vision
   - Drifting: Related but not directly serving mission
   - Off-track: Unrelated (not bad, just different)

3. **Philosophy Check**:
   - [ ] Nothing is deleted
   - [ ] Patterns over intentions
   - [ ] External brain, not command

4. **Report**:
   ```markdown
   ## Oracle Check - [Date] [Time]

   **Session Focus**: [...]
   **Alignment**: Aligned/Drifting/Off-track

   **Philosophy Check**:
   - [x] Nothing is deleted
   - [x] Patterns over intentions
   - [x] External brain
   ```

## Deep Reflection Mode

When using `/oracle reflect`:

1. Review last 3 retrospectives
2. Look for patterns
3. Ask:
   - Are we moving toward the mission?
   - What's pulling us away?
   - What's the next most important thing?
