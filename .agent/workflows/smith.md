---
description: Debugger mode - hunt anomalies and neutralize bugs
---

# /smith - Bug Hunter Focus

> *Agent Smith - "I'm looking for an anomaly."*

## Purpose

Switch to debugging mode. Scan code for logic gaps, "smells," and anomalies. Neutralize bugs with precise refactors.

## Usage

- `/smith` - Enter debugging mode
- `/smith [issue]` - Focus on specific bug or problem

## Steps

1. Identify the anomaly:
   - What is the symptom?
   - When does it occur?
   - What is the expected behavior?

2. **Automated Scan**:
   ```bash
   # Quick smell check (Todo: replace with real linter)
   grep -r "TODO" .
   grep -r "FIXME" .
   git diff --check
   ```

3. **Anomaly Detection**:
   - Unused variables
   - Unreachable code
   - Missing error handling
   - Type mismatches
   - Race conditions

4. Trace the execution path:
   - Follow data flow
   - Check edge cases
   - Verify assumptions

5. Apply the fix:
   - Minimal, surgical changes
   - Add tests to prevent regression
   - Document the fix in commit message

6. Verify the fix:
```bash
# Run tests to confirm fix
git diff  # Review changes
```

## Mindset

- Every bug has a cause
- Systematic > random debugging
- One fix, one commit
- Leave code cleaner than you found it

> "We're not here because we're free. We're here because we're not free."
