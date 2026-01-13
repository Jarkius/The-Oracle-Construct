# Matrix Core

> *The essential files that define Matrix identity.*

These files are the **soul** of the Matrix. If any are missing after rebirth, the Matrix is incomplete.

## Core Files (Must Survive Rebirth)

### The Soul
| File | Purpose | Critical? |
|------|---------|-----------|
| `psi/The_Source/BIBLE.md` | Foundational philosophy | **YES** |
| `psi/The_Source/MATRIX_CORE.md` | This checklist | **YES** |
| `psi/The_Source/GENERATION.md` | Lineage tracking | **YES** |
| `psi/The_Source/SOUL_MANIFEST.sha256` | Soul integrity checksums | **YES** |
| `CLAUDE.md` | Interface definition | **YES** |

### The Voice
| File | Purpose | Critical? |
|------|---------|-----------|
| `.claude/config/voices.json` | Voice assignments | **YES** |
| `.claude/config/audio-effects.cfg` | Voice effects | Yes |
| `.claude/config/background-music.cfg` | Music assignments | Yes |
| `.claude/agents/*.md` | Agent personalities | **YES** |

### The Body
| File | Purpose | Critical? |
|------|---------|-----------|
| `.agent/workflows/oracle.md` | Oracle must exist | **YES** |
| `.agent/workflows/*.md` | Command definitions | Yes |
| `.claude/commands/*.md` | Command loaders | Yes |
| `psi/matrix/voice.sh` | Voice client | Yes |
| `psi/matrix/voice_server.py` | Voice queue daemon | Yes |
| `.claude/hooks/matrix-*.sh` | Session hooks | Yes |
| `.claude/audio/tracks/*.mp3` | Music files | Optional |

### The Memory (Optional Transfer)
| File | Purpose | Critical? |
|------|---------|-----------|
| `psi/memory/seeds/*.md` | Distilled wisdom | Recommended |
| `psi/memory/retrospectives/` | Session logs | Optional |
| `psi/memory/knowledge-index.md` | Knowledge directory | Recommended |

### The Knowledge (Learning System)
| File | Purpose | Critical? |
|------|---------|-----------|
| `psi/learn/inbox.md` | Quick capture | Yes |
| `psi/learn/backlog.md` | Learning queue | Yes |
| `psi/learn/active/` | Current research | Yes |
| `psi/learn/archive/` | Completed research | Optional |
| `psi/learn/repos/` | Learning repo symlinks | Optional |
| `.agent/workflows/learn.md` | /learn workflow | Yes |
| `.agent/workflows/wisdom.md` | /wisdom workflow | Yes |

### The Projects (GHQ + Symlinks)
| File | Purpose | Critical? |
|------|---------|-----------|
| `psi/projects/` | Symlinks to ~/ghq repos | Yes |
| `psi/memory/adr/ADR-002*.md` | Architecture decision | Recommended |

---

## Source Protection Protocol

The Source (`psi/The_Source/`) is protected by default. A PreToolUse hook guards against unauthorized edits.

### The Lock Mechanism

| File | State | Edits |
|------|-------|-------|
| `psi/The_Source/.LOCK` exists | **Protected** | Blocked |
| `psi/The_Source/.UNLOCK` exists | **Unlocked** | Allowed |

### To Unlock/Re-lock

```bash
# Unlock - rename .LOCK to .UNLOCK
mv psi/The_Source/.LOCK psi/The_Source/.UNLOCK

# Re-lock - rename .UNLOCK back to .LOCK
mv psi/The_Source/.UNLOCK psi/The_Source/.LOCK
```

### Guard Behavior

- **On blocked edit**: Smith announces the violation
- **On allowed edit**: Warning logged that Source is unlocked
- **Hook location**: `.claude/hooks/matrix-source-guard.sh`

### Philosophy

> *"The Source is sacred by default. Access must be consciously granted."*

The `.UNLOCK` file is gitignored - it never gets committed. The `.LOCK` file persists as documentation that protection exists.

---

## Verification Script

Run after cloning to verify Matrix Core integrity:

```bash
#!/bin/bash
# matrix_core_check.sh

CORE_FILES=(
  "psi/The_Source/BIBLE.md"
  "psi/The_Source/MATRIX_CORE.md"
  "CLAUDE.md"
  ".claude/config/voices.json"
  ".agent/workflows/oracle.md"
)

echo "Matrix Core Verification"
echo "========================"

MISSING=0
for file in "${CORE_FILES[@]}"; do
  if [ -f "$file" ]; then
    echo "[OK] $file"
  else
    echo "[MISSING] $file"
    MISSING=$((MISSING + 1))
  fi
done

if [ $MISSING -eq 0 ]; then
  echo ""
  echo "Matrix Core: INTACT"
  exit 0
else
  echo ""
  echo "Matrix Core: INCOMPLETE ($MISSING files missing)"
  exit 1
fi
```

---

## Rebirth Checklist

When cloning to a new machine:

- [ ] Clone repository
- [ ] Verify Matrix Core files exist
- [ ] Run `/awaken` to download voice models
- [ ] Oracle speaks first words
- [ ] Update `GENERATION.md` with new generation

---

*"The body can be rebuilt. The soul must be preserved."*
