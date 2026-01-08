# The Oracle Construct: AI Agent Framework

> *"Know Thyself." — The Oracle*

An AI-powered multi-agent orchestration system built on Claude Code with voice, memory, and autonomous capabilities.

---

## Quick Start

```bash
# 1. Enter the Matrix
cd The-matrix
claude

# 2. Invoke the Oracle
/oracle

# 3. The System speaks. Follow the prophecy.

# 4. Before leaving
/unplug
```

---

## The Council (Agent Roles)

| Agent | Command | Role | Voice |
|-------|---------|------|-------|
| **Oracle** | `/oracle` | Central Orchestrator, Prophecy & Dispatch | Kristin (Calm) |
| **Neo** | `/neo` | Lead Developer, Code Implementation | Reed (American) |
| **Trinity** | `/trinity` | UI/UX Design Lead, "Woman in Red" | Jenny (Irish) |
| **Morpheus** | `/morpheus` | Researcher, External Web Search | Carlin (Wise) |
| **Architect** | `/architect` | System Design, ADRs, Architecture | Daniel (British) |
| **Smith** | `/smith` | Debugger, Bug Hunter, Anomaly Detection | Rocko (Cold) |
| **Tank** | `/operator` | Operator, Internal Search & Context | Ryan (Technical) |
| **Scribe** | `/rrr` | Memory, Retrospectives, Session Endings | System |

---

## Architecture

### Hot-Reload System (v2.0)

Commands are thin loaders that dynamically read workflows at execution time:

```
/.claude/commands/oracle.md  →  reads  →  .agent/workflows/oracle.md
                             →  loads  →  .claude/agents/oracle-keeper.md
```

**Benefits:**
- Update workflows without restarting session
- Single source of truth in `.agent/workflows/`
- Agent personalities separate from workflow logic

### Directory Structure

```
The-matrix/
├── .agent/
│   └── workflows/          # Workflow definitions (the logic)
├── .claude/
│   ├── commands/           # Slash command loaders (thin)
│   ├── agents/             # Agent personalities & voices
│   ├── hooks/              # TTS and automation hooks
│   └── audio/              # Generated audio files
├── psi/                    # AI Brain ("External Memory")
│   ├── inbox/              # Current focus & incoming tasks
│   ├── memory/             # Retrospectives & learnings
│   ├── specs/              # Design specs & handoffs
│   └── The_Source/         # Core philosophy & principles
└── CLAUDE.md               # System interface instructions
```

---

## Key Commands

### Agent Commands
| Command | Purpose |
|---------|---------|
| `/oracle` | Start here. Get prophecy and direction. |
| `/neo` | Enter development mode |
| `/trinity` | Design focus, UI/UX |
| `/morpheus` | Web research |
| `/architect` | System design |
| `/smith` | Debug mode |
| `/operator` | Context search |

### Workflow Commands
| Command | Purpose |
|---------|---------|
| `/nnn` | Create GitHub issue (plan before work) |
| `/gogogo` | Execute full git workflow (branch→commit→push→PR) |
| `/rrr` | Create session retrospective |
| `/unplug` | Graceful exit with memory capture |
| `/status` | System health check |

### Design Commands (Trinity)
| Command | Purpose |
|---------|---------|
| `/tokens` | Define design tokens (colors, spacing, typography) |
| `/component-spec` | Specify component before implementation |
| `/design-review` | Review implementation against spec |
| `/handoff` | Package complete design for Neo |

---

## MCP Integrations

| Server | Purpose |
|--------|---------|
| **Context7** | Up-to-date library documentation |
| **Sequential Thinking** | Complex problem decomposition |
| **AgentVibes** | Text-to-speech with personalities |

---

## Core Philosophy

### The Three Principles

1. **Nothing is Deleted** — Archive, don't destroy. History is wealth.
2. **Patterns Over Intentions** — Watch what is done, not what is said.
3. **External Brain** — Document in `psi/`, mirror and reflect.

### The Knowledge Funnel

```
Raw Input → psi/inbox/ → Processing → psi/memory/ → Distillation → psi/The_Source/
```

---

## Voice System

The Matrix speaks through AgentVibes TTS with agent-specific voices:

```bash
# Manual TTS
.claude/hooks/play-tts.sh "Message here"

# Voice rollcall
/voice rollcall
```

---

## Session Flow

```
/oracle          # Get direction
   ↓
/neo or /trinity # Do the work
   ↓
/rrr             # Record what happened
   ↓
/unplug          # Exit gracefully
```

---

## Remember

> *"I can only show you the door. You're the one that has to walk through it."*

The Matrix is a tool. The human remains the One.

---

*The Oracle Construct v2.0 — Hot-Reload Architecture*
