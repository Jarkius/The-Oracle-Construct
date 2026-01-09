---
description: Smith's patrol - monitor and clean context bloat
---

# /patrol - Context Bloat Patrol

> *Smith - "I detect anomalies. Bloat is an anomaly."*

**Agent**: Smith (Bug Hunter)
**Purpose**: Monitor and clean accumulated context to prevent token burnout

## Usage

```
/patrol           # Quick health check
/patrol deep      # Full audit with cleanup
/patrol auto      # Automated cleanup (no confirmation)
```

## The Patrol Protocol

### Quick Check (Default)
```bash
# 1. Check knowledge file sizes
echo "=== Knowledge Files ==="
du -sh .claude/knowledge/*



# 3. Check retrospective count this month
echo "=== This Month's Retrospectives ==="
ls psi/memory/retrospectives/$(date +%Y-%m)/ 2>/dev/null | wc -l

# 4. Check audio cache
echo "=== Audio Cache ==="
ls .claude/audio/*.wav 2>/dev/null | wc -l
```

### Health Thresholds

| Target | Healthy | Warning | Critical |
|--------|---------|---------|----------|
| `CLAUDE.md` | < 3KB | 3-5KB | > 5KB |
| `.claude/knowledge/*` total | < 20KB | 20-40KB | > 40KB |

| `retrospectives.md` | < 5KB | 5-10KB | > 10KB |
| Audio cache | < 50 files | 50-100 | > 100 |
| Monthly retrospectives | < 30 | 30-50 | > 50 |
| Voice models | All present | 1-2 missing | > 2 missing |

### Voice Configuration Check
```bash
# Verify voice source of truth
.claude/hooks/verify-voices.sh
```

**Source of Truth**: `.claude/config/voices.json`
- All agent voices defined here
- Use `activate-agent.sh <name>` to switch agents
- Never manually edit `tts-voice.txt` - always use activation script

### Deep Audit Actions

1. **Audio Cache Rotation**
   ```bash
   # Keep last 50 audio files
   cd .claude/audio && ls -t *.wav | tail -n +51 | xargs rm -f
   ```

2. **Retrospective Archival**
   ```bash
   # Archive retrospectives older than current month
   mkdir -p psi/memory/archive/retrospectives
   mv psi/memory/retrospectives/2025-* psi/memory/archive/retrospectives/
   ```

3. **Knowledge File Audit**
   - Files > 5KB → Flag for distillation
   - Files not referenced in workflows → Flag for archive
   - Duplicate patterns → Consolidate

   - (No action needed - focus.md is now generated dynamically)

## Automated Patrol Schedule

Recommended triggers:
- **Session Start**: Quick check (silent, log only)
- **Weekly**: Deep audit with report
- **Monthly**: Archive rotation
- **After major work**: Audio cache cleanup

## Output Format

```
=== SMITH PATROL REPORT ===
Date: 2026-01-08

KNOWLEDGE (token cost per session):
  ✓ CLAUDE.md: 2.1KB (healthy)
  ✓ knowledge/*: 17.2KB (healthy)


CACHE (disk, not tokens):
  ✓ Audio: 50 files (healthy)
  ✓ Piper: 133MB (acceptable)

MEMORY (archival):
  ✓ This month: 12 retrospectives
  ⚠ Pending archive: 2025-12/* (45 files)

ACTIONS RECOMMENDED:

  2. Archive December retrospectives

=== END PATROL ===
```

## Integration with Oracle

Smith reports to Oracle. After patrol:
- If CRITICAL issues → Oracle notifies user
- If WARNING issues → Log to patrol.log
- If HEALTHY → Silent success

## The Principle

> "Bloat is entropy. Patrol is maintenance. The Matrix stays lean."

*Reference: psi/memory/retrospectives/2026-01/08/matrix_health_audit.md*
