---
description: Red Pill - Automated system repair and standardization
---

# /fix - The Red Pill

> *Morpheus - "It is time to wake up."*

## Usage

- `/fix` - Run all critical fixers.
- `/fix git` - Fix git line endings and state.
- `/fix memory` - Archive old context.

## Steps

### Git Standardization
```bash
# Normalize Line Endings (CRLF -> LF)
git config core.autocrlf input
git add --renormalize .

# Check for large files
find . -type f -size +100M
```

### Memory Cleanup
```bash
# Archive outdated active files
# (Not deleting, just checking permissions)
ls -la psi/active/
```
