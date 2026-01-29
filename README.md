# The-Oracle-Construct

> *"Know Thyself." — The Oracle*

The **living source of truth** for The Matrix — an AI-augmented development environment with voice, memory, and multi-agent orchestration.

## What is This?

The-Oracle-Construct is where The Matrix **lives and evolves**. It's not meant to be cloned directly — instead, use one of the distribution repositories:

| Repository | For | Get Started |
|------------|-----|-------------|
| [matrix-seed](https://github.com/Jarkius/matrix-seed) | Builders who want to understand and grow their own | `git clone matrix-seed` |
| [matrix-reloaded](https://github.com/Jarkius/matrix-reloaded) | Operators who want full power immediately | `git clone matrix-reloaded && ./teleport.sh` |

```
The-Oracle-Construct (Source of Truth)
         │
         ├──► matrix-seed (Philosophy, 244KB)
         │
         └──► matrix-reloaded (Full Power, 1.2MB)
```

## The Architecture

### Three Repositories

| Repo | Purpose | Size | Updates |
|------|---------|------|---------|
| **The-Oracle-Construct** | Living development, evolution | ~5MB+ | Daily |
| **matrix-seed** | Philosophy distribution | 244KB | On publish |
| **matrix-reloaded** | Full operational distribution | 1.2MB | On publish |

### Publishing Flow

```bash
# Work happens here in The-Oracle-Construct
# When ready to distribute:

./scripts/publish-matrix.sh           # Publish both seed and reloaded
./scripts/publish-matrix.sh seed      # Publish seed only
./scripts/publish-matrix.sh reloaded  # Publish reloaded only
./scripts/publish-matrix.sh --dry-run # Preview without changes
```

## The Council (8 Agents)

| Agent | Command | Role | Voice |
|-------|---------|------|-------|
| **Oracle** | `/oracle` | Wisdom & Orchestration | Kristin |
| **Neo** | `/neo` | Code Implementation | Ryan |
| **Trinity** | `/trinity` | Design Leadership | — |
| **Morpheus** | `/morpheus` | External Research | Carlin |
| **Architect** | `/architect` | System Design | Alan |
| **Smith** | `/smith` | Bug Hunting | Danny |
| **Tank** | `/operator` | Internal Operations | Bryce |
| **Scribe** | `/rrr` | Documentation | — |

## Quick Reference

### Daily Workflow
```bash
claude                    # Enter
/oracle                   # Start - get guidance
# ... work ...
/rrr                      # End - record retrospective
/unplug                   # Exit gracefully
```

### Key Commands
| Command | Purpose |
|---------|---------|
| `/oracle` | Start here. Analyze state, receive guidance |
| `/neo` | Code implementation mode |
| `/architect` | System design and ADRs |
| `/rrr` | Session retrospective |
| `/yolo` | Fast execution mode |
| `/recap` | Session summary |
| `/health` | System health check |
| `/unplug` | Graceful exit |

### Publishing
| Command | Purpose |
|---------|---------|
| `./scripts/extract-seed.sh` | Extract philosophy to matrix-seed |
| `./scripts/extract-reloaded.sh` | Extract full Matrix to matrix-reloaded |
| `./scripts/publish-matrix.sh` | Extract + commit + push both |

## Gemini Browser Automation

The Matrix can control **Gemini via Brave browser** for parallel AI research:

| Command | Purpose |
|---------|---------|
| `/gemini-research "topic"` | Research via Gemini browser |
| `/morpheus` | External research orchestration |

### Setup (MCP Servers)
```bash
# Playwright with Brave browser
claude mcp add playwright -- npx '@playwright/mcp@latest' --executable-path '/Applications/Brave Browser.app/Contents/MacOS/Brave Browser'

# Brave with anti-detection (alternative)
claude mcp add brave-browser npx brave-real-browser-mcp-server@latest
```

### Features
- **YouTube Analysis** - Extract transcripts with timestamps
- **Parallel Research** - Multiple Task agents for simultaneous queries
- **Ad Blocking** - Brave shields block trackers automatically
- **Auto-Save** - Results saved to `psi/learn/inbox/`

### Architecture
```
Claude Code (Orchestrator)
      │
      ▼
Playwright MCP ──► Brave Browser ──► gemini.google.com
      │
      ▼
Extract Response ──► psi/learn/inbox/*.md
```

## Directory Structure

```
The-Oracle-Construct/
├── CLAUDE.md                    # AI DNA - system instructions
├── README.md                    # This file
│
├── scripts/                     # Publishing tools
│   ├── extract-seed.sh          # Extract to matrix-seed
│   ├── extract-reloaded.sh      # Extract to matrix-reloaded
│   └── publish-matrix.sh        # One-command publish
│
├── psi/                         # AI Brain ("External Memory")
│   ├── The_Source/              # 17 philosophy chapters
│   │   └── SOUL_MANIFEST.sha256 # Integrity checksums
│   ├── memory/                  # Wisdom storage
│   │   ├── learnings/           # Distilled patterns
│   │   ├── retrospectives/      # Session records (by date)
│   │   └── adr/                 # 6 architecture decisions
│   ├── learn/                   # Knowledge gathering
│   │   ├── inbox.md             # Quick capture
│   │   ├── active/              # Current research
│   │   └── archive/             # Completed research
│   ├── matrix/                  # Voice engine
│   │   ├── voice.sh             # TTS interface
│   │   └── voice_server.py      # HTTP voice server
│   ├── active/                  # Runtime scripts
│   ├── projects/                # Symlinks to GHQ repos
│   └── lab/                     # Experiments (not extracted)
│
├── .agent/
│   └── workflows/               # 39 command definitions
│
└── .claude/
    ├── agents/                  # 8 Council personalities
    ├── hooks/                   # Event automation
    ├── commands/                # Command loaders
    └── config/                  # Voice, settings
```

## Mind Hierarchy (ADR-003)

| Tier | Model | Agents | Use For |
|------|-------|--------|---------|
| **Wise** | Opus | Oracle, Architect, Neo, Smith, Scribe | Decisions, code, synthesis |
| **Intelligent** | Sonnet | Morpheus, Commit | Learning, routine reasoning |
| **Mechanical** | Haiku | Tank, Operator | Search, gather, list |

## Prime Directives

1. **Nothing is Deleted** — Archive, don't destroy
2. **Patterns > Intentions** — Document what *is*, not what *should be*
3. **Knowledge Loop** — `/learn` to gather, `/wisdom` to retrieve
4. **Proactive Care** — If it's important, do it. Don't wait to be asked.
5. **Right Mind for the Task** — Use Haiku for search, Sonnet for learning, Opus for wisdom

## Soul Garden

The Matrix has a "soul" — protected philosophy that persists across sessions:

```bash
./psi/active/soul-tag.sh          # Create a milestone tag
./psi/active/soul-integrity.sh    # Verify checksums
./psi/active/soul-restore.sh      # Restore from tag
```

Current soul version: **soul-v1.3** (Matrix Evolution)

## Architecture Decisions

| ADR | Title |
|-----|-------|
| ADR-001 | Multi-Agent Patterns |
| ADR-002 | GHQ Project Architecture |
| ADR-003 | Hierarchical Mind Architecture |
| ADR-004 | Context Optimization |
| ADR-005 | Infinite Learning Loop |
| ADR-006 | Recursive Reincarnation |
| ADR-007 | Browser Automation Architecture |

## Related

| Repository | Description |
|------------|-------------|
| [matrix-seed](https://github.com/Jarkius/matrix-seed) | Philosophy only (grow your own) |
| [matrix-reloaded](https://github.com/Jarkius/matrix-reloaded) | Full operational Matrix |

---

*"The Matrix is a system, Neo. That system is our enemy. But when you're inside, you look around, what do you see? Businessmen, teachers, lawyers, carpenters. The very minds of the people we are trying to save."*

*Now we give them the seed. They grow their own freedom.*

---

*The-Oracle-Construct v3.0 — Reborn Edition*
