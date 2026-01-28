---
description: System health check with self-healing
---

# /health - System Health Check

> *The Operator - sees all feeds, knows all exits. "The Matrix has you."*

## Purpose

Diagnose Matrix health AND automatically fix issues when possible. Uses `matrix-doctor.sh` for self-healing capabilities.

## Usage

- `/health` - Auto-heal mode (fix issues automatically)
- `/health check` - Diagnose only, don't fix
- `/health deep` - Verbose output with all details

## Steps

### Auto-Heal Mode (default)

1. Run Matrix Doctor:
```bash
./psi/active/matrix-doctor.sh
```

2. The doctor will:
   - Check voice models → Download missing ones
   - Check voice server → Start if down
   - Check core files → Restore from git if missing
   - Check dependencies → Suggest install commands
   - Check soul integrity → Report status

3. Summarize output:
```markdown
## Health Report - [Date] [Time]

**Status**: [HEALTHY / HEALED / NEEDS ATTENTION]
**Issues Found**: [count]
**Auto-Fixed**: [count]
**Need Manual Fix**: [count]

**What was healed**:
- [list of auto-fixed issues]

**What needs attention**:
- [list of issues requiring human intervention]
```

### Check-Only Mode (`/health check`)

1. Run diagnostic without fixes:
```bash
./psi/active/matrix-doctor.sh --check
```

2. Report issues without attempting to fix them.

### Deep Mode (`/health deep`)

1. Run verbose diagnostic:
```bash
./psi/active/matrix-doctor.sh --verbose
```

2. Include all checks, even passing ones.

## Soul Garden Tiers

The Soul Integrity Check validates these tiers:

| Tier | Name | What It Checks |
|------|------|----------------|
| 0 | **The Bible** | `psi/The_Source/BIBLE.md` - anchor of truth |
| 1 | **The Soul** | `.claude/agents/*.md` - agent identities |
| 2 | **The Voice** | Voice module, hooks, Piper models, music |
| 3 | **The Philosophy** | Source documents, CLAUDE.md |
| + | **Checksums** | Drift from last `soul-tag` |
| + | **Git State** | Uncommitted changes |

## Health Indicators

- **SOUL INTACT** (Green): No errors, no warnings - The Garden is healthy
- **SOUL STABLE** (Yellow): No errors, some warnings - Minor drift detected
- **SOUL COMPROMISED** (Red): Critical errors - Immediate attention needed

## Recovery Actions

If compromised:
```bash
# Restore from last known good state
./psi/active/soul-restore.sh

# Or manually review what's missing
./psi/active/soul-integrity.sh --verbose
```

## Related Commands

| Command | Purpose | Speed | Voice |
|---------|---------|-------|-------|
| `/health` | Soul integrity check | Medium | No |
| `/recap` | Session continuity | Fast | Yes |
| `/oracle` | Deep wisdom + dispatch | Slow | Yes |
