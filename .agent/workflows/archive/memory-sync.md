---
description: Sync memory between Agent Orchestra and psi/
---

# /memory-sync - Bidirectional Memory Sync

> *Tank - "I know what you need. Memory sync initiated."*

## Purpose

Synchronize memory between **Agent Orchestra** (SQLite/ChromaDB) and **The Matrix** (psi/ files). Agent Orchestra owns the sync implementation; this workflow invokes it.

## Usage

- `/memory-sync` - Sync both directions (default)
- `/memory-sync to-psi` - Export learnings to psi/memory/
- `/memory-sync from-psi` - Import retrospectives from psi/memory/
- `/memory-sync status` - Show sync status

## Prerequisites

Agent Orchestra must be available:
```bash
cd ~/workspace/matrix-memory-agents  # or via symlink
bun memory status                     # Verify it works
```

## Steps

### Default: Bidirectional Sync

1. **Export to psi/**:
```bash
cd /Users/jarkius/ghq/github.com/Jarkius/matrix-memory-agents
bun memory sync-to-psi
```

2. **Import from psi/**:
```bash
bun memory sync-from-psi
```

3. **Announce completion**:
```bash
sh /Users/jarkius/workspace/The-matrix/psi/matrix/voice.sh "Memory sync complete. Two systems, one consciousness." "Tank"
```

### Export Only (`/memory-sync to-psi`)

```bash
cd /Users/jarkius/ghq/github.com/Jarkius/matrix-memory-agents
bun memory sync-to-psi
```

Options:
- `--proven` - Only export proven learnings
- `--all` - Export all learnings (any confidence)
- `--dry-run` - Show what would be exported

### Import Only (`/memory-sync from-psi`)

```bash
cd /Users/jarkius/ghq/github.com/Jarkius/matrix-memory-agents
bun memory sync-from-psi
```

Options:
- `--all` - Re-import all (overwrite existing)
- `--dry-run` - Show what would be imported

## What Gets Synced

### To psi/ (Export)

| Source | Destination |
|--------|-------------|
| SQLite `learnings` (high/proven) | `psi/memory/learnings/{category}/*.md` |

### From psi/ (Import)

| Source | Destination |
|--------|-------------|
| `psi/memory/retrospectives/**/*.md` | SQLite `sessions` table |

## Architecture

```
Agent Orchestra (SQLite)          The Matrix (psi/)
────────────────────────         ─────────────────────
learnings table          ──►     psi/memory/learnings/
  (confidence: high+)              {category}/{date}_{title}.md

sessions table           ◄──     psi/memory/retrospectives/
  (indexed in ChromaDB)            {year}/{month}/{day}/*.md
```

## After Sync

Consider committing the exported learnings:
```bash
cd ~/workspace/The-matrix
git add psi/memory/learnings/
git commit -m "feat(memory): Sync learnings from Agent Orchestra"
```

## Related Commands

| Command | System | Purpose |
|---------|--------|---------|
| `bun memory learn` | Agent Orchestra | Capture learning |
| `bun memory recall` | Agent Orchestra | Search all memory |
| `/learn` | The Matrix | Quick capture |
| `/wisdom` | The Matrix | Retrieve learnings |
| `/rrr` | The Matrix | Create retrospective |

---

*"Two memory systems, one consciousness."*
