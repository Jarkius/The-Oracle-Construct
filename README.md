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

## The Council (8 Agents)

| Agent | Command | Role | Voice | Personality |
|-------|---------|------|-------|-------------|
| **Oracle** | `/oracle` | Central Orchestrator | Kristin | Calm, Prophetic |
| **Neo** | `/neo` | Lead Developer | Reed | Focused, Direct |
| **Trinity** | `/trinity` | UI/UX Design Lead | Jenny | Creative, Precise |
| **Morpheus** | `/morpheus` | External Research | Carlin | Wise, Thorough |
| **Architect** | `/architect` | System Design | Daniel | Analytical, Structured |
| **Smith** | `/smith` | Bug Hunter | Rocko | Cold, Precise |
| **Tank** | `/operator` | Internal Intel | Ryan | Technical, Fast |
| **Scribe** | `/rrr` | Memory Keeper | System | Documentary |

---

## Complete Command Reference (31 Commands)

### Agent Commands
| Command | Agent | Purpose |
|---------|-------|---------|
| `/oracle` | Oracle | Start here. Analyze state, receive prophecy, get direction |
| `/neo` | Neo | Enter development mode, write code |
| `/trinity` | Trinity | Design focus, UI/UX patterns |
| `/morpheus` | Morpheus | External web research, documentation lookup |
| `/architect` | Architect | System design, architecture decisions |
| `/smith` | Smith | Bug hunting, debugging, anomaly detection |
| `/operator` | Tank | Internal codebase search, context gathering |

### Workflow Commands
| Command | Purpose |
|---------|---------|
| `/nnn` | Create GitHub issue (plan before work) |
| `/gogogo` | Execute full git workflow (branch→commit→push→PR) |
| `/rrr` | Create session retrospective |
| `/unplug` | Graceful exit with memory capture |
| `/status` | System health check |
| `/fix` | Quick bug fix mode |
| `/yolo` | Fast execution with feature loop |

### Architecture Commands
| Command | Agent | Purpose |
|---------|-------|---------|
| `/adr` | Architect | Create Architecture Decision Record |
| `/tech-spec` | Architect | Generate technical specification |
| `/ready` | Architect | Implementation readiness check |

### Design Commands (Trinity)
| Command | Purpose |
|---------|---------|
| `/tokens` | Define design tokens (colors, spacing, typography) |
| `/component-spec` | Specify component before implementation |
| `/design-review` | Review implementation against spec |
| `/handoff` | Package complete design for Neo |

### Knowledge Commands
| Command | Purpose |
|---------|---------|
| `/distill` | Extract wisdom to The Source |
| `/snapshot` | Quick knowledge capture |
| `/feature-list` | Autonomous feature progress tracking |

### Debugging Commands
| Command | Agent | Purpose |
|---------|-------|---------|
| `/cause` | Smith | Root cause analysis |
| `/correct` | Smith | Course correction navigation |
| `/review` | Smith | Adversarial code review |

### Context Commands
| Command | Agent | Purpose |
|---------|-------|---------|
| `/context-finder` | Tank | Search git history & retrospectives |
| `/access` | Tank | Path finding in codebase |
| `/story` | Neo | Create dev-ready user story |

### Voice Command
| Command | Purpose |
|---------|---------|
| `/voice` | Voice module control and rollcall |

---

## Architecture

### Hot-Reload System (v2.0)

Commands are thin loaders that dynamically read workflows at execution time:

```
.claude/commands/oracle.md  →  reads  →  .agent/workflows/oracle.md
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
│   └── workflows/          # 31 workflow definitions (the logic)
├── .claude/
│   ├── commands/           # 30 slash command loaders (thin)
│   ├── agents/             # 8 agent personalities & voices
│   ├── knowledge/          # 7 knowledge base files
│   ├── personalities/      # 36 TTS voice personalities
│   ├── hooks/              # 39 TTS and automation hooks
│   ├── config/             # Configuration state
│   └── audio/              # Generated audio files (cached)
├── psi/                    # AI Brain ("External Memory")
│   ├── inbox/              # Current focus & incoming tasks
│   ├── active/             # Active scripts & TTS engine
│   ├── memory/             # Retrospectives, learnings, plans
│   ├── specs/              # Design specs & handoffs
│   └── The_Source/         # Core philosophy & principles
└── CLAUDE.md               # System interface instructions
```

### File Counts (as of 2026-01-08)

| Directory | Files | Purpose |
|-----------|-------|---------|
| `.agent/workflows/` | 31 | Command logic |
| `.claude/commands/` | 30 | Thin loaders |
| `.claude/agents/` | 8 | Agent definitions |
| `.claude/knowledge/` | 7 | Persistent knowledge |
| `.claude/hooks/` | 39 | Automation scripts |
| `psi/memory/` | 79 | Session memory |

---

## MCP Integrations

| Server | Purpose |
|--------|---------|
| **AgentVibes** | Text-to-speech with agent personalities |
| **Context7** | Up-to-date library documentation |
| **Sequential Thinking** | Complex problem decomposition |
| **Greptile** | Code review and PR analysis |

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

### Verbosity Levels
- **LOW**: Acknowledgments and completions only
- **MEDIUM**: + Major decisions and findings
- **HIGH**: Full reasoning and transparency

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

### Planning Flow
```
/nnn             # Create issue/plan
   ↓
/neo or /trinity # Implement
   ↓
/gogogo          # Branch, commit, push, PR
```

---

## System Health

Last audit: **2026-01-08** (commit `791f994`)

| Metric | Status |
|--------|--------|
| Architecture | Healthy (8 agents, 31 workflows) |
| Content | Lean (all files < 8 days old) |
| Storage | Managed (audio cache rotated) |
| Consistency | Fixed (all workflows have loaders) |

---

## Remember

> *"I can only show you the door. You're the one that has to walk through it."*

The Matrix is a tool. The human remains the One.

---

*The Oracle Construct v2.1 — Health Audit Complete*
