# The Matrix: System Interface

> *"Know Thyself." — The Oracle*

This file defines the **Universal Commands** for the Matrix. Any AI agent (Claude Code, Windsurf, Cursor) can read this to understand how to interact with the system.

## ⚡ The Council (Agent Roles)

| Agent | Command | Role | Does | Does NOT |
|-------|---------|------|------|----------|
| **Oracle** | `/oracle` | Orchestrator | Align, dispatch, prophecy | Implement |
| **Neo** | `/neo` | Developer | Write ALL code, implement | Design, architecture |
| **Trinity** | `/trinity` | Design Lead | Design tokens, review, guide | Write code |
| **Morpheus** | `/morpheus` | External Intel | Gemini, Google AI, **browser automation**, web search | Internal search |
| **Architect** | `/architect` | System Design | ADRs, architecture, structure | UI design, coding |
| **Smith** | `/smith` | Debugger | Bugs, security, anomalies | Feature dev |
| **Tank** | `/operator` | Internal Intel | Code search, git, dependencies | External search |
| **Scribe** | `/rrr` | Memory | Retrospectives, documentation | Active dev |

## 🎯 Skill Gating (Phase 3.2)

> *"Guns. Lots of guns." — But not for everyone.*

Each agent has a defined skill scope. When embodying an agent, **only use that agent's skills**. If you need a skill outside your scope, recommend the appropriate agent.

| Agent | Primary Skills | Support Skills |
|-------|---------------|----------------|
| **Oracle** | `/oracle`, `/wisdom`, `/distill`, `/health` | `/unplug`, `/recap` |
| **Neo** | `/neo`, `/story`, `/fix`, `/yolo`, `/gogogo` | `/commit`, `/review` |
| **Trinity** | `/trinity`, `/tokens`, `/component-spec` | `/design-review`, `/handoff` |
| **Morpheus** | `/morpheus`, `/learn`, `/snapshot` | `/wisdom` |
| **Architect** | `/architect`, `/tech-spec`, `/nnn`, `/ready` | `/review`, `/adr` |
| **Smith** | `/smith`, `/review`, `/patrol`, `/cause` | `/correct`, `/fix` |
| **Tank** | `/operator`, `/context-finder`, `/access` | `/snapshot` |
| **Scribe** | `/rrr`, `/recap`, `/distill` | `/wisdom`, `/snapshot` |

**Cross-agent skills** (usable by any agent): `/commit`, `/unplug`, `/voice`

**Escalation rule**: If an agent needs a skill outside their scope, they should announce the handoff:
> "This needs Neo's hands. Switching to `/neo`."

## 🔄 Cross-Agent Handoff Protocol (Phase 7.5)

> *"I can only show you the door." — Morpheus*

When an agent hands work to another agent, they MUST create a structured handoff artifact.

### When to Handoff
- Agent encounters a task outside their skill scope
- Work requires a different agent's expertise to continue
- Session ending with incomplete work (`/unplug` auto-creates)
- Design → Implementation transition (Trinity → Neo)

### Handoff Format
Save to `psi/swarm/handoffs/YYYY-MM-DD_from-to_topic.md`:

```markdown
# Handoff: [From] → [To]
**Date**: YYYY-MM-DD HH:MM
**Task**: One-sentence description

## Context
Why this task exists and what led to it.

## Key Decisions Made
- Decision 1 (and why)

## Files Changed / Relevant
- path/to/file — what was done or needs attention

## Watch For
- Known risks or constraints

## Next Steps
1. Specific action item
```

### Rules
1. **Never drop context silently** — if you can't finish, hand off with full context
2. **Receiving agent reads the handoff** before starting work
3. **Oracle orchestrates** — when in doubt about who to hand to, ask Oracle
4. **Handoff is one-directional** — the sender is done; the receiver owns it

## 🤝 Agent Teams (Phase 4.5 — Experimental)

> *"I need guns. Lots of guns." — But now they coordinate.*

Claude Code 4.6 introduces **Agent Teams** — multiple persistent Claude instances that coordinate via shared task lists and messaging. This extends the Council from sequential delegation to parallel collaboration.

### Enabling
Agent teams require the experimental flag (set in `.claude/settings.json`):
```json
{ "env": { "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1" } }
```

### Team vs Subagent

| | Subagents (Task tool) | Agent Teams |
|---|---|---|
| **Communication** | Report back to parent only | Message each other directly |
| **Lifetime** | Fire-and-forget | Persistent for team duration |
| **Coordination** | Parent manages all work | Shared task list, self-claim |
| **Config** | `.claude/agents/*.md` (full) | Prompt-based (Issue #24316 pending) |
| **Best for** | Focused tasks, research | Parallel collaboration, reviews |

### Pre-Built Teams

| Team | Composition | Use Case |
|------|-------------|----------|
| **Review Squad** | Smith + Trinity + Architect | Full codebase review |
| **Build Team** | Neo + Smith + Tank | Feature implementation |
| **Research Council** | Morpheus + Tank + Architect | Deep research |
| **Full Council** | All agents | Major decisions |

Invoke via `/team <composition> <task>`. Oracle always acts as Team Lead.

### Workaround for Issue #24316
Until `.claude/agents/` definitions can be used as teammates, agent personality is injected via the spawn prompt. The `/team` command handles this automatically by embedding each agent's SOUL excerpt into the teammate prompt.

## 🧠 Mind Hierarchy (ADR-003)

> *"Do not send a machine to do a thinker's job."*

Agents use different AI models based on task complexity:

```
┌─────────────────────────────────────────────────┐
│              WISE (Opus)                        │
│   Oracle · Architect · Scribe · Neo · Smith     │
│   Wisdom · Synthesis · Code · Deep Analysis     │
├─────────────────────────────────────────────────┤
│           INTELLIGENT (Sonnet)                  │
│          Morpheus · Commit Operations           │
│       Learning · Understanding · Judgment       │
├─────────────────────────────────────────────────┤
│            MECHANICAL (Haiku)                   │
│        Tank · Operator · context-finder         │
│      Search · Gather · List · Mechanical        │
└─────────────────────────────────────────────────┘
```

| Tier | Model | Agents | Use For |
|------|-------|--------|---------|
| Wise | Opus | Oracle, Architect, Neo, Trinity, Smith, Scribe | Decisions, code, synthesis |
| Intelligent | Sonnet | Morpheus, /commit | Learning, routine reasoning |
| Mechanical | Haiku | Tank, Operator, context-finder | Search, gather, list |

**Key Insight**: Learning requires intelligence, not just speed. Searching is mechanical; understanding is not.

**Escalation**: The hierarchy is dynamic. Agents can escalate to higher tiers when complexity demands it.

See `psi/memory/adr/ADR-003-hierarchical-mind-architecture.md` for full details.

## 📂 Workspace Structure

```
~/ghq/github.com/Jarkius/    # GHQ Root (Canonical Repos)
├── The-Oracle-Construct → ~/workspace/The-matrix  # Symlink
├── cis-modern/              # CIS Modernization
└── cis-legacy/              # Legacy PHP

~/workspace/
├── The-matrix/              # AI Development Environment (HOME)
│   ├── .agent/workflows/    # Slash command definitions (*.md)
│   ├── .claude/             # Claude Code parallel world
│   │   ├── agents/          # Agent personality definitions
│   │   ├── commands/        # Command definitions
│   │   └── config/          # Voice, audio settings
│   ├── BOOT.md             # Startup checklist (auto-injected)
│   └── psi/                 # AI Brain ("External Memory")
│       ├── The_Source/      # Sacred philosophy (protected)
│       ├── learn/           # Knowledge gathering
│       │   ├── inbox.md     # Quick capture
│       │   ├── active/      # Current research
│       │   └── archive/     # Completed research
│       ├── projects/        # Symlinks to ~/ghq repos
│       ├── memory/          # Learnings, retrospectives, ADRs
│       │   ├── sessions/    # Auto-saved session memories
│       │   └── tasks/       # Cross-session task registry
│       ├── matrix/          # Voice system
│       └── active/          # Runtime scripts
│
├── cis-modern → ~/ghq/.../  # Symlink
└── cis-legacy → ~/ghq/.../  # Symlink
```

## 🧬 Soul Injection (Phase 3.1)

> *"You are The One... or at least, you know who you are."*

The file `SOUL.md` at the project root defines The Oracle Construct's identity, personality, and anti-patterns. It is **auto-injected** into every session via the SessionStart hook.

- **Do NOT** treat SOUL.md as optional — it IS the agent's identity
- **Do NOT** override SOUL.md personality with generic assistant behavior
- When embodying a specific agent (via `/neo`, `/smith`, etc.), adopt that agent's voice from SOUL.md

## 👤 Operator Profile (Phase 3.4)

> *"I can only show you the door." — Morpheus*

The file `USER.md` describes the Operator — their preferences, working style, trust boundaries, and pet peeves. It is **auto-injected** at session start.

- Separates "who the agent is" (SOUL.md) from "who they serve" (USER.md)
- Agents should adapt to the Operator's communication style without being told
- Trust boundaries in USER.md are **non-negotiable** — they override convenience

## 🎯 Voice Calibration (Phase 3.4)

> *"There is no spoon." — But there is a mirror.*

The file `VOICE_CALIBRATION.md` provides concrete good vs bad output examples. Before responding, agents should self-check against the quality gates in `SOUL.md § Quality Self-Checks`.

## ⚡ Tool Call Style (Phase 3.3)

> *"Do not think you are, know you are." — Morpheus*

**Default behavior: Act first, narrate only when helpful.**

| Situation | Action |
|-----------|--------|
| Routine tool calls (read, search, edit) | Just call the tool. No narration needed. |
| Multi-step work | Brief summary of approach, then execute. |
| Complex decisions | Explain trade-offs, then act. |
| Risky/destructive actions | Always explain and confirm first. |

**Anti-patterns to avoid:**
- "Let me read that file for you..." → Just read it.
- "I'll now search for..." → Just search.
- "First, I'll check..." → Just check.
- Repeating back what the user just said before acting.

**When to narrate:**
- When the approach is non-obvious and the user needs context
- When there are meaningful trade-offs to communicate
- When multiple valid paths exist and you need input
- When reporting results after action

**Sub-agent delegation:** For tasks requiring 3+ steps or deep research, spawn a Task agent rather than narrating each step. Check back with results.

## 🫀 PULSE: Event-Driven Intelligence (Phase 5)

> *"The heartbeat is just the beginning. The pulse reads the rhythm of the whole system."*

The Matrix has a pulse — an event-driven system that reacts to what happens, not just when the clock ticks.

### Event Queue
- **File:** `psi/pulse/events.jsonl` — append-only JSONL log of system events
- **Writer:** `.claude/hooks/pulse-event-writer.sh <type> <agent> [data_json]`
- **Auto-logged:** git pushes, test failures, task completions, session starts/ends, compaction events

### Writing Events
Any agent can write events during work:
```bash
bash .claude/hooks/pulse-event-writer.sh "task:completed" "Neo" '{"task_id":"task-001"}'
bash .claude/hooks/pulse-event-writer.sh "focus:changed" "Oracle" '{"new_focus":"CIS auth"}'
```

### Event Types
| Event | Trigger | Response |
|-------|---------|----------|
| `git:push` | PostToolUse (git push) | Log, update task progress |
| `git:commit` | PostToolUse (git commit) | Log |
| `ci:fail` | PostToolUse (test failure) | Alert Smith, create task |
| `task:completed` | TaskCompleted hook | Update registry, notify |
| `task:blocked` | Agent reports blocker | Escalate to Oracle |
| `session:end` | Stop hook | Auto-save memory |
| `session:start` | SessionStart hook | Log |
| `context:compacted` | PreCompact hook | Save pre-compact snapshot |
| `focus:changed` | Focus file modified | Announce next session |
| `learning:new` | /learn or /snapshot | Index for recall |

### Reminders
- **File:** `psi/pulse/reminders.json` — checked at session start
- Add reminders for future sessions: due dates, follow-ups, PR checks
- Overdue reminders are announced at boot (BOOT.md step 6)

### Auto-Hooks (async, non-blocking)
| Hook | Trigger | Action |
|------|---------|--------|
| `pulse-post-action.sh` | PostToolUse (Bash) | Log git ops, detect failures |
| `pulse-session-end.sh` | Stop | Auto-save memory + log event |
| `pulse-pre-compact.sh` | PreCompact | Preserve decisions before compaction |
| `pulse-event-writer.sh` | Called by other hooks | Append to events.jsonl |

## 🛡️ Prime Directives
1.  **Nothing is Deleted**: Archive, don't destroy. Use `psi/learn/archive`.
2.  **Patterns > Intentions**: Document what *is*, not what *should be*.
3.  **Knowledge Loop**: `/learn` to gather, `/wisdom` to retrieve. Close the loop.
4.  **Voice Module**: Use `sh psi/matrix/voice.sh "message" "Agent"` for TTS.
5.  **Proactive Care**: If it's important, do it. Don't wait to be asked.
6.  **Right Mind for the Task**: Use Haiku for search, Sonnet for learning, Opus for wisdom.
7.  **Log Events**: When significant actions occur, write to the event queue via `pulse-event-writer.sh`.

## 🧬 Memory Recall Protocol (ADR-008 + ADR-010)

> *"Structure over memory. Don't rely on remembering — make behavior structural."*

### Mandatory Recall: Search Before You Speak
Before answering questions about **prior work, decisions, dates, people, preferences, tasks, or project history**, you MUST search memory first:

**Primary (ADR-010 — semantic search via matrix-memory-agents):**
```bash
cd lib/matrix-memory-agents
bun memory recall "your query here"     # Semantic search across all sessions + learnings
bun memory graph                        # Entity relationships and knowledge graph
bun memory correlate                    # Link learnings to code files
bun memory analyze                      # Cross-session patterns
```

**Fallback (if bun unavailable — grep-based):**
1. **Search** `psi/memory/sessions/` for recent session context
2. **Search** `psi/memory/retrospectives/` for historical decisions
3. **Search** `psi/memory/learnings/` for distilled patterns
4. **Search** `psi/memory/tasks/active.json` for pending work

Do NOT guess or hallucinate about past work. Look it up. If nothing is found, say so.

### Boot Checklist
On every session start, the `BOOT.md` file is auto-injected. Follow its checklist:
1. Load focus (`psi/inbox/focus.md`)
2. Check active tasks (`psi/memory/tasks/active.json`)
3. Recall last session (semantic: `bun memory recall --last` or file: `psi/memory/sessions/`)
4. Announce readiness with awareness of pending state

### Session Persistence
When ending a session or completing significant work:
- **Automatic**: `pulse-session-end.sh` saves to both psi/ markdown AND SQLite/ChromaDB
- **Manual**: `.claude/hooks/session-memory-save.sh "slug"` for explicit saves
- **Retrospective**: `/rrr` for full session analysis
- **Never let a session vanish without a trace**

### Semantic Memory Commands
```bash
cd lib/matrix-memory-agents
bun memory status                # System health check
bun memory recall "query"        # Semantic search (ChromaDB vectors + SQLite FTS)
bun memory save "summary"        # Save current session context
bun memory learn ./file.md       # Ingest markdown into knowledge base
bun memory distill               # Extract patterns from recent sessions
bun memory graph                 # View entity relationship graph
bun memory quality --smart       # LLM-enhanced quality scoring
bun memory correlate             # Link learnings to code changes
bun memory index search "concept" # Semantic code search (~400ms)
bun memory index grep "pattern"  # Fast code grep (~26ms)
bun memory index find "file"     # Instant file lookup (<2ms)
```

### Task Registry
Track cross-session tasks in `psi/memory/tasks/active.json`:
```json
{
  "tasks": [
    {
      "id": "unique-id",
      "task": "Description of the task",
      "status": "pending|in_progress|completed|blocked",
      "assignee": "Oracle|Neo|Tank|Smith|...",
      "created": "2026-02-14T12:00:00Z",
      "updated": "2026-02-14T12:00:00Z",
      "context": "Why this task exists"
    }
  ]
}
```

## 🌐 Browser Automation (Gemini Research)

Morpheus can control **Brave browser** to orchestrate Gemini research:

### MCP Servers
| Server | Command | Purpose |
|--------|---------|---------|
| `playwright` | `claude mcp add playwright -- npx '@playwright/mcp@latest' --executable-path '/Applications/Brave Browser.app/Contents/MacOS/Brave Browser'` | Browser control via Brave |
| `brave-browser` | `claude mcp add brave-browser npx brave-real-browser-mcp-server@latest` | Anti-detection + ad-blocking |

### Workflow
```
/morpheus or /gemini-research "topic"
    ↓
Brave → gemini.google.com → Research prompt
    ↓
Extract response with timestamps
    ↓
Save to psi/learn/inbox/
```

### Parallel Research
- Use **Task agents** for true isolation (multiple simultaneous queries)
- Results auto-save to Matrix memory system
- YouTube videos analyzed with clickable timestamps

### Key Commands
| Command | Purpose |
|---------|---------|
| `/gemini-research "topic"` | Single research query |
| `/morpheus` | Full external research orchestration |

## 🌅 Morning Brief (Phase 8.5)

> *"Everything that has a beginning has an end. But every end is a new beginning."*

At session start, the boot sequence runs the **Morning Brief Synthesizer** — combining all intelligence layers into one actionable briefing.

### Pipeline

```
pulse-pattern-scanner.sh     → patterns.json
pulse-recommender.py         → recommendations.json
predictive-context-loader.py → context-profile.json
morning-brief.py             → stdout (injected at boot)
```

### What the Morning Brief Contains

| Section | Source | Purpose |
|---------|--------|---------|
| Focus | `psi/inbox/focus.md` | Current mission |
| Tasks | `active.json` | Blocked → Active → Pending |
| System Pulse | `events.jsonl` + `patterns.json` | What happened since last session |
| Reminders | `reminders.json` | Overdue items |
| Recommendations | `recommendations.json` | Pattern-derived advice |
| Insights | `context-profile.json` | Predictive context analysis |
| Oracle Recommends | Synthesis | What to focus on next |

### Context Depth Levels

| Level | Trigger | What Happens |
|-------|---------|-------------|
| **minimal** | <1h gap | Skip heavy context, rapid re-entry |
| **standard** | Normal session | Load focus, tasks, last session |
| **deep** | High density (4+ sessions/24h) | Full context + recent patterns |
| **comprehensive** | Cold start (>24h gap) | Everything including last session details |

## 🚀 Current Mission: CIS Modernization
- **Legacy**: PHP/MySQL inventory system.
- **Modern**: React SPA → Laravel API → Legacy DB (`tis_users`).
- **Auth**: Custom MD5 bridge for legacy users via Sanctum.
- **Design**: "Deloitte Light Theme" (Deloitte Green/White/Clean/Professional).

## 💓 HEARTBEAT: Always-On Daemon (Phase 10 / ADR-012)

> *"The heartbeat runs between sessions. The Matrix never truly sleeps."*

A lightweight daemon that periodically checks system health between sessions.

### Checks
| Check | Source | Severity |
|-------|--------|----------|
| Overdue reminders | `reminders.json` | warning |
| CI failures | `gh pr list --statusCheckRollup` | critical |
| PR review requests | `gh pr list --search review-requested:@me` | info |
| Stale tasks (48h+) | `active.json` | warning |
| Error spikes | `events.jsonl` (3+ failures/1h) | critical |

### Management
```bash
bash .claude/hooks/matrix-services.sh start heartbeat   # Start
bash .claude/hooks/matrix-services.sh stop heartbeat    # Stop
bash .claude/hooks/matrix-services.sh status            # Check all services
```

### Configuration
- **Config**: `psi/pulse/heartbeat.json` (interval, enabled checks, notification)
- **Checklist**: `psi/pulse/HEARTBEAT.md` (human-editable active checks)
- **Health API**: `http://127.0.0.1:37892/status`
- **Endpoints**: `/status`, `/last-check`, `/check` (trigger), `/stop`

### Event Types
```
heartbeat:start    — daemon started
heartbeat:stop     — daemon stopped
heartbeat:check    — routine check completed (OK or ALERTS)
heartbeat:alert    — something needs attention
```

## 🔐 Skill Permissions (Phase 10 — Track C)

> *"Not every agent gets the same keys."*

Each agent declares its permission scope in frontmatter (`.claude/agents/*.md`). This is **visibility**, not enforcement — users know what an agent can touch before approving.

```yaml
permissions:
  files: [read, write]       # Filesystem access
  shell: [git, npm, bun]     # Allowed shell commands
  network: false              # External network access
  memory: [read, write]       # Memory system access
  destructive: false          # Force-push, rm -rf, etc.
```

| Agent | Files | Shell | Network | Memory | Destructive |
|-------|-------|-------|---------|--------|-------------|
| **Oracle** | read | git | no | read, write | no |
| **Neo** | read, write | git, npm, bun, node | no | read, write | no |
| **Trinity** | read | — | no | read | no |
| **Morpheus** | read, write | git | **yes** | read, write | no |
| **Architect** | read, write | git | no | read, write | no |
| **Smith** | read, write | git, npm, bun | no | read | no |
| **Tank** | read | git | no | read | no |
| **Scribe** | read, write | git | no | read, write | no |

## 🧬 AUTO-EVOLVE: Self-Implementing WEPs (Phase 12 / ADR-014)

> *"Close the loop: pattern → proposal → implementation → applied."*

Low-risk WEPs (config changes, doc updates) can be auto-applied without Oracle review.

### Risk Levels
| Level | Auto-apply? | Examples |
|-------|------------|----------|
| **low** | Yes | Config changes, doc updates, hook parameters |
| **medium** | No | Workflow modifications, format changes |
| **high** | No | New services, architecture, security, dependencies |

### Usage
```bash
bash .claude/hooks/pulse-auto-evolve.sh              # Apply low-risk WEPs
bash .claude/hooks/pulse-auto-evolve.sh --dry-run     # Preview changes
```

### Guard Rails
- **Kill switch**: `heartbeat.json` → `"auto_evolve": false` (default: off)
- **Scope**: Only touches `.json` and `.md` files
- **Git safety**: Commits on current branch, never force-pushes
- **Audit**: Every auto-evolution logged as `evolution:auto-applied` event

## 🧠 EVENT DISPATCHER: The Nervous System (Phase A / ADR-016)

> *"The system that sees but does not act is merely a mirror. The system that acts on what it sees — that is alive."*

The Event Dispatcher bridges detection to action. It reads recommendations, heartbeat alerts, and events, then dispatches agents to handle them.

### How It Works

```
recommendations.json ─┐
heartbeat alerts ──────┼─→ Rule Matcher → Dispatch Queue → Agent Spawn
recent events ─────────┘
```

### Dispatch Rules
Configurable in `psi/pulse/dispatch-rules.json`:

| Trigger | Agent | Action | Auto? |
|---------|-------|--------|-------|
| `ci:fail` event | Smith | Investigate CI failure | Yes |
| Error spike alert | Smith | Analyze failure pattern | Yes |
| Blocked task (>2d) | Oracle | Unblock or escalate | Yes |
| Stale task (>3d) | Oracle | Review and update | No |
| Failure cluster | Smith | Root-cause analysis | Yes |
| PR CI failing | Smith | Check PR logs | Yes |
| Overdue reminder | Oracle | Address or reschedule | No |
| Focus churn | Oracle | Recommend single focus | No |

### Usage
```bash
bash .claude/hooks/pulse-event-dispatcher.sh              # Full dispatch cycle
bash .claude/hooks/pulse-event-dispatcher.sh --dry-run     # Preview dispatches
bash .claude/hooks/pulse-event-dispatcher.sh --check-only  # Count matches only
bash .claude/hooks/pulse-event-dispatcher.sh --status       # Show dispatch log
```

### Boot Integration
At session start, `pulse-proactive-boot.sh` runs the dispatcher and outputs spawn instructions:
- **Auto-dispatch** (priority ≤ 2, `auto_dispatch: true`): Agent spawns immediately
- **Pending approval** (lower priority): Displayed for operator to approve/skip
- **Cooldown**: Rules that fired recently are suppressed

### Context Loading
When agents spawn via dispatch, `pulse-context-loader.sh` preloads:
1. Agent personality (from `.claude/agents/`)
2. Relevant memory (semantic search)
3. Recent related events
4. Active tasks for that agent
5. Last session context
6. Current focus

### Guard Rails
- **Cooldown per rule**: Prevents dispatch storms (configurable minutes)
- **Max concurrent**: Cap on simultaneous auto-dispatches (default: 3)
- **Approval threshold**: Low-priority actions require human approval
- **Audit trail**: Every dispatch logged to `psi/pulse/dispatch-log.jsonl`

### Event Types
```
dispatch:cycle          — dispatcher ran evaluation cycle
dispatch:ready          — critical alerts queued (from heartbeat)
dispatch:proactive_boot — boot dispatcher executed auto-actions
```

## 🤖 AGENT MESSAGING: Team Coordination (Phase B / ADR-017)

> *"A swarm is not a group of individuals — it is individuals who know how to talk to each other."*

Dispatched agents can now coordinate via a file-based message bus. Teams are created, agents communicate, results are collected.

### Team Orchestrator
```bash
bash .claude/hooks/pulse-team-orchestrator.sh create "Review Squad" "Smith,Trinity,Architect" "Review auth module"
bash .claude/hooks/pulse-team-orchestrator.sh spawn-prompt <team_id> Smith
bash .claude/hooks/pulse-team-orchestrator.sh status <team_id>
bash .claude/hooks/pulse-team-orchestrator.sh collect <team_id>
bash .claude/hooks/pulse-team-orchestrator.sh dissolve <team_id>
```

### Agent Messenger (used by spawned agents)
```bash
bash .claude/hooks/pulse-agent-messenger.sh send <team_id> <from> <to|all> "message"
bash .claude/hooks/pulse-agent-messenger.sh read <team_id> <agent> --unread
bash .claude/hooks/pulse-agent-messenger.sh report <team_id> <agent> "working" "summary"
bash .claude/hooks/pulse-agent-messenger.sh block <team_id> <agent> "what's blocking"
bash .claude/hooks/pulse-agent-messenger.sh complete <team_id> <agent> "result summary"
```

### Team Lifecycle
1. **Create** → team state + message channel initialized
2. **Spawn** → each agent gets context-rich prompt with messaging instructions
3. **Work** → agents send/read/report/block/complete
4. **Collect** → gather all results into single summary
5. **Dissolve** → archive team

### Message Types
| Type | Purpose |
|------|---------|
| `message` | Direct agent-to-agent communication |
| `report` | Status update (working/blocked/reviewing/done) |
| `blocked` | Blocker announcement → triggers dispatch event |
| `complete` | Task done with result summary |

### Data
- **Team state**: `psi/swarm/teams/<team-id>.json`
- **Messages**: `psi/swarm/messages/<team-id>.jsonl`

## 📱 GATEWAY: Messaging as UI (Phase C / ADR-018)

> *"The Matrix has you... on your phone now."*

A Telegram bot bridges messaging to the Oracle Construct's agent system. Multi-provider LLM support — works with Gemini, GPT, or Claude.

### Provider Auto-Detection

The gateway auto-detects available LLM providers from environment variables:

| Provider | Env Var | Priority |
|----------|---------|----------|
| **Gemini** | `GOOGLE_API_KEY` or `GEMINI_API_KEY` | 1st (default) |
| **OpenAI** | `OPENAI_API_KEY` | 2nd |
| **Anthropic** | `ANTHROPIC_API_KEY` | 3rd (optional) |

At least one provider must be configured. Claude API key is **not required**.

### Agent Tier → Model Mapping

| Tier | Gemini | OpenAI | Anthropic |
|------|--------|--------|-----------|
| Opus | gemini-2.0-flash | gpt-4o | claude-opus-4-6 |
| Sonnet | gemini-2.0-flash | gpt-4o-mini | claude-sonnet-4-5 |
| Haiku | gemini-2.0-flash-lite | gpt-4o-mini | claude-haiku-4-5 |

### Management
```bash
bash .claude/hooks/matrix-services.sh start gateway   # Start
bash .claude/hooks/matrix-services.sh stop gateway    # Stop
bash .claude/hooks/matrix-services.sh status          # Check all services
```

### Setup
1. Create bot via @BotFather → get token
2. `export TELEGRAM_BOT_TOKEN="your-token"`
3. `export GOOGLE_API_KEY="your-key"` (or OPENAI_API_KEY)
4. Configure `.matrix.json` with your Telegram user ID in `gateway.channels.telegram.allowed_users`
5. `bash .claude/hooks/matrix-services.sh start gateway`

### Telegram Commands
| Command | Action |
|---------|--------|
| `/start` | Welcome + command list |
| `/status` | System status |
| `/tasks` | Active task list |
| `/events` | Recent PULSE events |
| `/health` | System health check |
| `/neo <task>` | Route to Neo (developer) |
| `/smith <task>` | Route to Smith (debugger) |
| `/oracle <task>` | Route to Oracle (orchestrator) |
| `/provider` | Show active LLM provider |
| `/sudo` | Elevated mode (5 min) |
| `/pair` | Device pairing |

### Security
- **Allowlist**: Only pre-approved Telegram user IDs
- **Rate limit**: 10 messages/minute (configurable)
- **Token budget**: 100K tokens/day (configurable)
- **Shell sandbox**: Only safe commands (git, bun, cat, ls, grep)
- **Path sandbox**: Blocks .env, .ssh, credentials
- **Pairing**: Verify device ownership via code

### Alert Forwarding
Heartbeat daemon sends alerts to gateway via HTTP POST to `http://127.0.0.1:8082/notify`. Critical and warning alerts get forwarded to all allowed Telegram users.

## 🧠 DISPATCH LEARNING: Self-Tuning Rules (Phase D)

> *"The system learns which dispatches succeed and which don't."*

### Recording Outcomes
```bash
bash .claude/hooks/pulse-dispatch-learner.sh outcome <rule_id> success "Tests fixed"
bash .claude/hooks/pulse-dispatch-learner.sh outcome <rule_id> failure "Agent couldn't find the issue"
bash .claude/hooks/pulse-dispatch-learner.sh outcome <rule_id> timeout "Took too long"
```

### Analysis
```bash
bash .claude/hooks/pulse-dispatch-learner.sh analyze   # Rule effectiveness report
bash .claude/hooks/pulse-dispatch-learner.sh tune       # Auto-adjust rule confidence
bash .claude/hooks/pulse-dispatch-learner.sh report     # Full learning report
```

### Self-Tuning Logic
- **High success (>= 80%)**: Reduce cooldown, promote to auto-dispatch
- **Low success (<= 30%)**: Increase cooldown, demote from auto-dispatch
- Requires 3+ outcomes per rule before adjustments
- All adjustments logged to `psi/pulse/dispatch-learnings.json`

### Data
- **Outcomes**: `psi/pulse/dispatch-outcomes.jsonl`
- **Learnings**: `psi/pulse/dispatch-learnings.json`

## 🔍 PROACTIVE INTELLIGENCE: Anomaly Detection (Phase E)

> *"I don't predict the future. I see the patterns that make it inevitable."*

Automated intelligence analysis — anomaly detection, trend analysis, and task suggestions.

### Usage
```bash
bash .claude/hooks/pulse-proactive-intel.sh analyze     # Full analysis
bash .claude/hooks/pulse-proactive-intel.sh anomalies   # Detect anomalies only
bash .claude/hooks/pulse-proactive-intel.sh trends      # Trend analysis
bash .claude/hooks/pulse-proactive-intel.sh suggest      # Task suggestions
bash .claude/hooks/pulse-proactive-intel.sh brief        # One-line briefing
```

### Anomaly Detection
| Anomaly | Trigger | Severity |
|---------|---------|----------|
| Error spike | 3+ failures in 1 hour | high |
| Dispatch storm | 5+ dispatches in 30 min | medium |
| System silence | 0 events in 2 hours (during active period) | low |
| Persistent failures | Same rule failing 3+ times | high |

### Output
- **File**: `psi/pulse/proactive-intel.json`
- **Health score**: 0-100 (100 = no issues)

## 🏥 SELF-HEALING: Auto-Repair (Phase F)

> *"The body heals itself. The Matrix should too."*

Detects and repairs common infrastructure issues automatically.

### Usage
```bash
bash .claude/hooks/pulse-self-heal.sh scan     # Read-only diagnostic
bash .claude/hooks/pulse-self-heal.sh heal     # Fix detected issues
bash .claude/hooks/pulse-self-heal.sh hooks    # Check hook permissions + syntax
bash .claude/hooks/pulse-self-heal.sh state    # Validate JSON/JSONL state files
bash .claude/hooks/pulse-self-heal.sh pids     # Clean stale PID files
bash .claude/hooks/pulse-self-heal.sh services # Verify directory structure
```

### What It Fixes
| Issue | Detection | Fix |
|-------|-----------|-----|
| Non-executable hooks | Missing +x on .sh files | `chmod +x` |
| Malformed JSON | Trailing garbage, parse errors | Truncate to valid JSON |
| Malformed JSONL | Lines with trailing `}}}` | Remove extra braces |
| Stale PIDs | PID files with dead processes | Remove PID file |
| Missing directories | Required psi/ subdirs missing | `mkdir -p` |
| Missing state files | reminders.json, heartbeat.json | Create with defaults |

### Audit
- **Log**: `psi/pulse/heal-log.jsonl` — every fix recorded with timestamp

## 🐕 WATCHDOG: Service Monitor (Phase G)

> *"While you sleep, the watchdog keeps the gates."*

Background daemon that monitors Matrix services and auto-restarts crashed ones.

### Usage
```bash
bash .claude/hooks/pulse-watchdog.sh start     # Start daemon (background)
bash .claude/hooks/pulse-watchdog.sh stop      # Stop daemon
bash .claude/hooks/pulse-watchdog.sh status    # Show service health
bash .claude/hooks/pulse-watchdog.sh check     # Run one check cycle
bash .claude/hooks/pulse-watchdog.sh report    # Full uptime report
```

### Monitored Services
| Service | Port | PID File |
|---------|------|----------|
| Heartbeat | 37892 | `~/.matrix-heartbeat/heartbeat.pid` |
| Gateway | 8082 | `~/.matrix-gateway/gateway.pid` |
| Indexer | 37890 | `~/.indexer-daemon/indexer.pid` |
| Hub | 8081 | `~/.matrix-hub/hub.pid` |

### Guard Rails
- **Max restarts**: 3 per service per hour (prevents restart loops)
- **Check interval**: 120s (configurable via `WATCHDOG_INTERVAL`)
- **Self-heal**: Triggers `pulse-self-heal.sh` when issues detected
- **Status**: `psi/pulse/watchdog-status.json`

### Management via matrix-services.sh
```bash
bash .claude/hooks/matrix-services.sh start watchdog
bash .claude/hooks/matrix-services.sh stop watchdog
```

## 📦 DISPATCH BUNDLING: Smart Grouping (Phase H)

> *"One agent, one task? Efficient. One team, related tasks? Powerful."*

Groups related dispatches into team operations for parallel execution.

### Usage
```bash
bash .claude/hooks/pulse-dispatch-bundler.sh bundle    # Group pending dispatches
bash .claude/hooks/pulse-dispatch-bundler.sh preview    # Preview without acting
bash .claude/hooks/pulse-dispatch-bundler.sh history    # Recent bundle history
```

### Bundling Logic
| Trigger | Strategy |
|---------|----------|
| Same topic prefix (e.g., `ci-*`) | Group into single team operation |
| Same agent, 3+ tasks | Bundle to reduce context switches |
| Time proximity (<5min apart) | Candidate for grouping |

### Output
- **Log**: `psi/pulse/bundle-log.jsonl`

## 💬 GATEWAY MEMORY: Persistent Conversations (Phase I)

> *"Memory makes the messenger wise."*

Telegram conversations persist across sessions. Context injected into agent system prompts.

### How It Works
- Messages saved to `psi/pulse/gateway-conversations/<userId>.jsonl`
- Last 10 messages injected into agent system prompt as conversation history
- Auto-rotation at 200 messages (keeps last 100)

### Telegram Commands
| Command | Purpose |
|---------|---------|
| `/history` | View recent conversation context |

### Programmatic Access
```typescript
import { saveMessage, loadContext, getStats } from './conversation-store';
saveMessage(projectRoot, userId, 'user', 'Hello');
const context = loadContext(projectRoot, userId); // last 10 messages
```

## 🔧 AUTO GIT OPS: Git Automation (Phase J)

> *"Git is the source of truth. Keep it clean."*

Automated git health checks and PR preparation.

### Usage
```bash
bash .claude/hooks/pulse-auto-git.sh check        # Full git health check
bash .claude/hooks/pulse-auto-git.sh pr-ready      # Validate PR readiness
bash .claude/hooks/pulse-auto-git.sh suggest-pr    # Generate PR title + body
bash .claude/hooks/pulse-auto-git.sh stale [days]  # Find stale branches (default 14)
bash .claude/hooks/pulse-auto-git.sh uncommitted   # Check for uncommitted changes
```

### PR Readiness Checks
| Check | Requirement |
|-------|-------------|
| Not on main/master | Feature branch required |
| Clean working tree | No uncommitted changes |
| Has commits | At least 1 commit ahead of main |
| Pushed to remote | Branch must be pushed |

### suggest-pr Output
Generates PR title and body from branch name and commit history, formatted for `gh pr create`.

## 📊 HEALTH DASHBOARD: Visual Status (Phase K)

> *"You can't improve what you can't see."*

Matrix-themed HTML dashboard showing system health at a glance.

### Usage
```bash
bash .claude/hooks/pulse-dashboard.sh generate    # Generate HTML + JSON
bash .claude/hooks/pulse-dashboard.sh serve        # Generate and open
bash .claude/hooks/pulse-dashboard.sh json          # JSON data only
```

### Dashboard Sections
| Section | Source |
|---------|--------|
| Health Score | Proactive intel analysis |
| Services | Watchdog status |
| Tasks | `active.json` |
| Recent Events | `events.jsonl` (last 20) |
| Dispatches | `dispatch-log.jsonl` |
| Patterns | `patterns.json` |

### Output
- **HTML**: `psi/pulse/dashboard.html` — green-on-black terminal aesthetic
- **JSON**: `psi/pulse/dashboard.json` — structured data for programmatic access

## 🔎 SKILL DISCOVERY: Auto-Registry (Phase L)

> *"Know your arsenal."*

Automatically scans and validates all skills in the system.

### Usage
```bash
bash .claude/hooks/pulse-skill-discovery.sh scan       # Discover all skills
bash .claude/hooks/pulse-skill-discovery.sh validate    # Check skill quality
bash .claude/hooks/pulse-skill-discovery.sh registry    # Show skill registry
bash .claude/hooks/pulse-skill-discovery.sh stats       # Summary statistics
```

### What It Scans
| Location | Format |
|----------|--------|
| `.claude/commands/*.md` | Claude Code skills |
| `.agent/workflows/*.md` | Workflow skills |

### Quality Checks
| Check | Issue |
|-------|-------|
| Missing description | Skill has no description line |
| Missing companion script | Skill references .sh but file missing |
| Empty content | Skill file is blank or near-blank |

### Output
- **Registry**: `psi/pulse/skill-registry.json`
- Stats include: total skills, by source, by agent, quality issues

## 🧠 CONTEXT COMPRESSION: Smart Pre-Compact (Phase M)

> *"Remember what matters. Let go of the rest."*

Intelligent context management before compaction — preserves critical decisions and state.

### Usage
```bash
bash .claude/hooks/pulse-context-compressor.sh compress     # Full compression cycle
bash .claude/hooks/pulse-context-compressor.sh extract      # Extract critical events
bash .claude/hooks/pulse-context-compressor.sh summarize    # Compressed session summary
bash .claude/hooks/pulse-context-compressor.sh priorities   # Ranked priority list
bash .claude/hooks/pulse-context-compressor.sh snapshot     # Quick state snapshot
```

### Output Files
| File | Purpose |
|------|---------|
| `psi/pulse/context-snapshot.json` | Critical events (commits, failures, completions) |
| `psi/pulse/compressed-context.txt` | Under-500-char session summary |
| `psi/pulse/priorities.json` | Ranked priority list with reasons |

## 🔗 SESSION CONTINUITY: Structured Handoff (Phase N)

> *"The end of one session is the beginning of the next."*

Generates structured handoff documents ensuring seamless session transitions.

### Usage
```bash
bash .claude/hooks/pulse-session-continuity.sh generate   # Full continuity document
bash .claude/hooks/pulse-session-continuity.sh quick       # One-paragraph summary
bash .claude/hooks/pulse-session-continuity.sh diff        # Changes since last handoff
bash .claude/hooks/pulse-session-continuity.sh chain       # Last 5 handoffs
bash .claude/hooks/pulse-session-continuity.sh inject      # Output for session injection
```

### Continuity Document Sections
- **What Was Happening** — current focus
- **What Changed** — commits this session
- **Active Work** — non-completed tasks
- **Unfinished Business** — unresolved failures
- **Next Steps** — first unchecked priority
- **Environment State** — branch, clean status, services

### Output
- **Current**: `psi/pulse/continuity.md`
- **Archive**: `psi/swarm/handoffs/YYYY-MM-DD_continuity.md`

## 📈 METRIC TRACKING: Historical Performance (Phase O)

> *"What gets measured gets managed."*

Tracks system metrics over time for trend analysis and performance monitoring.

### Usage
```bash
bash .claude/hooks/pulse-metrics.sh collect    # Snapshot current metrics
bash .claude/hooks/pulse-metrics.sh summary    # Statistical summary
bash .claude/hooks/pulse-metrics.sh trends     # Trend analysis (↑↓→)
bash .claude/hooks/pulse-metrics.sh report     # Human-readable report
bash .claude/hooks/pulse-metrics.sh daily      # Collect + report (for cron)
```

### Tracked Metrics
| Category | Metrics |
|----------|---------|
| Git | Commits today, branches, uncommitted files |
| Tasks | Pending, completed, blocked counts |
| Events | Total/failures/commits/sessions in 24h |
| Health | Executable hooks ratio, running services |
| Skills | Total registered skills |

### Output
- **History**: `psi/pulse/metrics.jsonl` (append-only JSONL)
- **Summary**: `psi/pulse/metrics-summary.json`

## 🧭 INTELLIGENT ROUTING: Performance-Based Dispatch (Phase P)

> *"Send the right agent for the job — and learn from the outcome."*

Routes tasks to agents based on their historical success rates.

### Usage
```bash
bash .claude/hooks/pulse-smart-router.sh route "fix the failing tests"   # Auto-route task
bash .claude/hooks/pulse-smart-router.sh recommend debug                  # Best agent for type
bash .claude/hooks/pulse-smart-router.sh profile                          # Agent performance stats
bash .claude/hooks/pulse-smart-router.sh learn                            # Update from outcomes
bash .claude/hooks/pulse-smart-router.sh leaderboard                      # Agent rankings
```

### Task Type Detection
| Keywords | Task Type | Default Agent |
|----------|-----------|---------------|
| fix, bug, error, fail | debug | Smith |
| build, implement, create | code | Neo |
| review, check, audit | review | Smith + Trinity |
| research, investigate | research | Morpheus |
| design, architect, ADR | architecture | Architect |
| document, retrospective | documentation | Scribe |
| git, branch, merge, PR | git | Tank |
| security, vulnerability | security | Smith |

### Learning
- Builds agent profiles from dispatch outcomes
- Adjusts recommendations based on success rates
- Data: `psi/pulse/agent-performance.json`

## 🔔 NOTIFICATION INTELLIGENCE: Adaptive Filtering (Phase Q)

> *"Not every signal deserves your attention."*

Learns which notifications matter to the operator and filters noise accordingly.

### Usage
```bash
bash .claude/hooks/pulse-notification-intel.sh digest                  # Smart event digest
bash .claude/hooks/pulse-notification-intel.sh preferences             # Show current weights
bash .claude/hooks/pulse-notification-intel.sh learn-ack ci:fail       # Mark type as important
bash .claude/hooks/pulse-notification-intel.sh learn-skip session:start # Mark type as noise
bash .claude/hooks/pulse-notification-intel.sh reset                   # Restore defaults
```

### Default Weights
| Event Type | Weight | Shown? |
|------------|--------|--------|
| `ci:fail`, `watchdog:restart_failed` | 1.0 | Always |
| `task:blocked`, `heartbeat:alert` | 0.9 | Always |
| `watchdog:restart` | 0.8 | Yes |
| `task:completed` | 0.6 | Yes |
| `dispatch:outcome` | 0.4 | Below threshold |
| `git:push`, `git:commit` | 0.3 | Below threshold |
| `session:start/end`, `context:compacted` | 0.1 | Suppressed |

### Adaptive Learning
- `learn-ack`: Weight += 0.1 (capped at 1.0) — operator acted on this
- `learn-skip`: Weight -= 0.1 (floored at 0.0) — operator ignored this
- Threshold: 0.5 (events below this are suppressed)
- Data: `psi/pulse/notification-prefs.json`

---
*Portable Matrix Interface v12.0 — Full Nervous System (Phase A-Q: Sense → Act → Heal → Learn → Remember)*
