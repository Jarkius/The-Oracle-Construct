---
description: System health check - Soul Garden integrity diagnostic
---

# /health - System Health Check

> *The Operator - sees all feeds, knows all exits. "The Matrix has you."*

## Purpose

Deep diagnostic check of Matrix health using the Soul Garden system. Validates the integrity of the Matrix Core: agents, voice, philosophy, and git state.

## Usage

- `/health` - Quick health summary
- `/health deep` - Full Soul Garden integrity check (verbose)

## Steps

### Quick Mode (default)

1. Run Soul Integrity Check:
```bash
./psi/active/soul-integrity.sh
```

2. Summarize output:
```markdown
## Health Report - [Date] [Time]

**Soul Status**: [INTACT / STABLE / COMPROMISED]
**Errors**: [count]
**Warnings**: [count]

**Quick Checks**:
- Bible: [exists/missing]
- Agents: [X/8 present]
- Voice: [server running/stopped]
- Git: [clean/X uncommitted]

**Last Soul Tag**: [tag name] ([date])
```

### Deep Mode (`/health deep`)

1. Run verbose Soul Integrity:
```bash
./psi/active/soul-integrity.sh --verbose
```

2. Include all tier details in output.

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
