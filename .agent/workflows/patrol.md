---
description: Smith's patrol - detect anomalies in both directions (bloat AND gaps)
---

# /patrol - Anomaly Detection Patrol

> *Smith - "I detect anomalies. Excess AND absence - both are chaos."*

**Agent**: Smith (Bug Hunter)
**Purpose**: Detect anomalies in both directions - bloat (too much) AND gaps (too little/missing)

## Philosophy

Anomalies go both ways:
- **Bloat**: Files too large, caches overflowing, entropy accumulating
- **Gaps**: Missing bindings, orphaned workflows, broken references

*"One side doesn't fit all."* - The Matrix must be balanced.

## Usage

```
/patrol           # Full patrol - both bloat AND gaps
/patrol bloat     # Original - excess detection only
/patrol gaps      # New - absence/broken binding detection only
/patrol deep      # Full audit with cleanup recommendations
```

## The Patrol Protocol

### Quick Check (Default)

Runs BOTH bloat and gap detection.

---

## BLOAT DETECTION (Excess)

### Bloat Checks
```bash
# 1. Check knowledge file sizes
echo "=== Knowledge Files ==="
du -sh .claude/knowledge/*

# 2. Check retrospective count this month
echo "=== This Month's Retrospectives ==="
ls psi/memory/retrospectives/$(date +%Y-%m)/ 2>/dev/null | wc -l

# 3. Check audio cache
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
.claude/hooks/matrix-verify-voices.sh
```

**Source of Truth**: `.claude/config/voices.json`
- All agent voices defined here
- Use `matrix-activate-agent.sh <name>` to switch agents
- Never manually edit `tts-voice.txt` - always use activation script

---

## GAP DETECTION (Absence)

### 1. Command ↔ Workflow Binding Check
```bash
# Find orphaned commands (command exists, workflow missing)
echo "=== Orphaned Commands (no workflow) ==="
for cmd in .claude/commands/*.md; do
  name=$(basename "$cmd" .md)
  workflow=".agent/workflows/${name}.md"
  if [[ ! -f "$workflow" ]]; then
    echo "⚠ $name: command exists, workflow MISSING"
  fi
done

# Find missing commands (workflow exists, command missing)
echo "=== Missing Commands (workflow orphaned) ==="
for wf in .agent/workflows/*.md; do
  name=$(basename "$wf" .md)
  cmd=".claude/commands/${name}.md"
  if [[ ! -f "$cmd" ]]; then
    echo "⚠ $name: workflow exists, command MISSING"
  fi
done
```

### 2. Hook Reference Check
```bash
# Verify settings.json hook references exist
echo "=== Hook References ==="
hooks=$(grep -o '"command": "[^"]*"' .claude/settings.json | cut -d'"' -f4)
for hook in $hooks; do
  if [[ ! -f "$hook" ]]; then
    echo "⚠ BROKEN: $hook referenced but MISSING"
  fi
done
```

### 3. Agent Definition Check
```bash
# Check all expected agents exist
echo "=== Agent Definitions ==="
EXPECTED_AGENTS="oracle neo trinity morpheus architect smith tank operator"
for agent in $EXPECTED_AGENTS; do
  if [[ ! -f ".claude/agents/agent-${agent}.md" ]] && [[ ! -f ".claude/agents/${agent}.md" ]]; then
    echo "⚠ Agent MISSING: $agent"
  fi
done
```

### 4. Stale Reference Check
```bash
# Find references to deleted files in documentation
echo "=== Stale References ==="
# Check for references to old 'status' (now 'health')
grep -r "\/status" .agent/workflows/*.md .claude/commands/*.md 2>/dev/null && echo "⚠ Found /status references (should be /health)"
# Check for old hook names
grep -r "session-start-tts\|subagent-start\|subagent-complete" .claude/ 2>/dev/null && echo "⚠ Found old hook name references"
```

### Gap Thresholds

| Check | Healthy | Warning | Critical |
|-------|---------|---------|----------|
| Orphaned commands | 0 | 1-2 | > 2 |
| Missing commands | 0 | 1-2 | > 2 |
| Broken hooks | 0 | 1 | > 1 |
| Missing agents | 0 | 1-2 | > 2 |
| Stale references | 0 | 1-3 | > 3 |

---

## DEEP AUDIT (Both Directions)

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
Date: 2026-01-11
Mode: Full (Bloat + Gaps)

─── BLOAT DETECTION (Excess) ───

KNOWLEDGE (token cost per session):
  ✓ CLAUDE.md: 2.1KB (healthy)
  ✓ knowledge/*: 17.2KB (healthy)

CACHE (disk, not tokens):
  ✓ Audio: 50 files (healthy)
  ✓ Piper: 133MB (acceptable)

MEMORY (archival):
  ✓ This month: 12 retrospectives
  ⚠ Pending archive: 2025-12/* (45 files)

─── GAP DETECTION (Absence) ───

BINDINGS:
  ✓ Commands ↔ Workflows: All aligned
  ✓ Hook references: All valid

AGENTS:
  ✓ All 8 agents defined

REFERENCES:
  ✓ No stale references found

─── SUMMARY ───

BLOAT:  ✓ Healthy (1 warning)
GAPS:   ✓ Healthy (0 issues)
OVERALL: STABLE

ACTIONS RECOMMENDED:
  1. Archive December retrospectives

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
