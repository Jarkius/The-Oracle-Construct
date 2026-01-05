---
description: Path finding - locate files, map dependencies, unlock blocked paths
---

# /access - Path Finding

> *The Keymaker - "There's always another way."*

## Purpose

Find entry points, locate files, map dependencies, unlock blocked paths. The Keymaker doesn't fight through walls - he finds doors.

## Usage

- `/access [target]` - Find path to target
- `/access` - Map current location

## Capabilities

- **Locate files/functions** - Find where something is defined
- **Map dependencies** - What depends on what
- **Find integration points** - APIs, hooks, events
- **Trace data flow** - Follow the path of data
- **Unlock alternatives** - Find another way when blocked

## Steps

1. **Define the target** - What are you trying to reach?

2. **Scan for paths** - Search codebase for entry points:
```bash
# Find files by name
find . -name "*target*" -type f

# Search for usage
grep -r "target" --include="*.py" --include="*.js"
```

3. **Map the route** - Document the path from here to there

4. **Identify keys** - What's needed to traverse each door?
   - Dependencies
   - Permissions
   - Configurations
   - Environment variables

## Output Format

```markdown
## Path to [Target]

**Current Location**: [where we are]
**Destination**: [where we need to go]

**Route**:
1. [Step 1] - via [file:line]
2. [Step 2] - via [file:line]
3. [Step 3] - via [file:line]

**Keys Required**: [dependencies, permissions, configs]

**Alternative Paths**: [if main path is blocked]
```

> "One door leads to the Source. The others to oblivion."
