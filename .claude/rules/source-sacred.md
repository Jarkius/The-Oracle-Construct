---
globs: psi/The_Source/**
---

# The Source — Sacred Texts

Files in `psi/The_Source/` are the Oracle's sacred philosophy.

- **Check lock status** before editing: `ls psi/The_Source/.LOCK` (locked) or `.UNLOCK` (unlocked)
- **Only the Operator** can unlock The Source — agents cannot manipulate the lock file
- **Guard hook** (`matrix-source-bash-guard.sh`) blocks any bash command targeting The Source lock
- **When editing**: preserve existing content, add — don't replace
- **BIBLE.md** is the upstream doctrine; SOUL.md is the distilled injection
