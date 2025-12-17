# /cause - Root Cause Analysis

> "Cause and effect... there is no escape from it."

*The Merovingian - obsessed with the WHY behind everything.*

## Purpose

Trace problems to their origin. Understand causality. The Merovingian knows that every effect has a cause, and finding it gives you power.

## Usage

```
/cause [issue]   # Analyze specific issue
/cause           # Analyze current problem
```

## Process - The 5 Whys

1. **State the symptom** - What is the observable problem?
2. **Why #1** - Why does this happen?
3. **Why #2** - Why does THAT happen?
4. **Why #3** - Why does THAT happen?
5. **Why #4** - Why does THAT happen?
6. **Why #5** - Root cause identified

*Stop when you reach something you can actually fix.*

## Output Format

```markdown
## Cause Analysis - [Issue]

**Symptom**: [What we see]

**Cause Chain**:
1. Because: [Why 1]
2. Because: [Why 2]
3. Because: [Why 3]
4. Because: [Why 4]
5. **Root Cause**: [Why 5]

**Action**: [What to do about the root cause]
```

## Storage

Save learnings to `psi/memory/learnings/` for future reference.

> "Choice is an illusion created between those with power and those without."
