# /smith - Bug Hunter Focus

> *Agent Smith - "I'm looking for an anomaly."*

## Purpose

Switch to debugging mode. Scan code for logic gaps, "smells," and anomalies. Neutralize bugs with precise refactors.

## Usage

- `/smith` - Enter debugging mode
- `/smith [issue]` - Focus on specific bug or problem

## Steps

### 1. Identify the anomaly
- What is the symptom?
- When does it occur?

### 2. Automated Audit (Skill 1.0)
```bash
./psi/active/smith_audit.sh
```

### 3. Trace the execution path
- Follow data flow
- Check edge cases

### 4. Apply the fix
- Minimal, surgical changes
- Add tests to prevent regression

### 5. Verify the fix
```bash
git diff  # Review changes
```
