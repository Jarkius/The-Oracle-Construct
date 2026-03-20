# The Matrix: Systems Reference

> *"The Matrix is everywhere. It is all around us."*

This file documents the subsystem CLI commands and configuration for Phases 4.5 through Q.
**Not auto-injected** — read this file when working with a specific subsystem.

For core behavioral rules, see `CLAUDE.md`. For identity, see `SOUL.md`. For boot sequence, see `BOOT.md`.

---

## Agent Teams (Phase 4.5 — Experimental)

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

---

## Browser Automation (Gemini Research)

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

---

## HEARTBEAT: Always-On Daemon (Phase 10 / ADR-012)

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
bash .claude/hooks/core/matrix-services.sh start heartbeat   # Start
bash .claude/hooks/core/matrix-services.sh stop heartbeat    # Stop
bash .claude/hooks/core/matrix-services.sh status            # Check all services
```

### Configuration
- **Config**: `psi/state/pulse/heartbeat.json` (interval, enabled checks, notification)
- **Checklist**: `psi/state/pulse/HEARTBEAT.md` (human-editable active checks)
- **Health API**: `http://127.0.0.1:37892/status`
- **Endpoints**: `/status`, `/last-check`, `/check` (trigger), `/stop`

### Event Types
```
heartbeat:start    — daemon started
heartbeat:stop     — daemon stopped
heartbeat:check    — routine check completed (OK or ALERTS)
heartbeat:alert    — something needs attention
```

---

## Skill Permissions (Phase 10 — Track C)

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

---

## AUTO-EVOLVE: Self-Implementing WEPs (Phase 12 / ADR-014)

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
bash .claude/hooks/pulse/pulse-auto-evolve.sh              # Apply low-risk WEPs
bash .claude/hooks/pulse/pulse-auto-evolve.sh --dry-run     # Preview changes
```

### Guard Rails
- **Kill switch**: `heartbeat.json` → `"auto_evolve": false` (default: off)
- **Scope**: Only touches `.json` and `.md` files
- **Git safety**: Commits on current branch, never force-pushes
- **Audit**: Every auto-evolution logged as `evolution:auto-applied` event

---

## EVENT DISPATCHER: The Nervous System (Phase A / ADR-016)

> *"The system that sees but does not act is merely a mirror. The system that acts on what it sees — that is alive."*

The Event Dispatcher bridges detection to action. It reads recommendations, heartbeat alerts, and events, then dispatches agents to handle them.

### How It Works

```
recommendations.json ─┐
heartbeat alerts ──────┼─→ Rule Matcher → Dispatch Queue → Agent Spawn
recent events ─────────┘
```

### Dispatch Rules
Configurable in `psi/state/pulse/dispatch-rules.json`:

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
bash .claude/hooks/pulse/pulse-event-dispatcher.sh              # Full dispatch cycle
bash .claude/hooks/pulse/pulse-event-dispatcher.sh --dry-run     # Preview dispatches
bash .claude/hooks/pulse/pulse-event-dispatcher.sh --check-only  # Count matches only
bash .claude/hooks/pulse/pulse-event-dispatcher.sh --status       # Show dispatch log
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
- **Audit trail**: Every dispatch logged to `psi/state/pulse/dispatch-log.jsonl`

### Event Types
```
dispatch:cycle          — dispatcher ran evaluation cycle
dispatch:ready          — critical alerts queued (from heartbeat)
dispatch:proactive_boot — boot dispatcher executed auto-actions
```

---

## AGENT MESSAGING: Team Coordination (Phase B / ADR-017)

> *"A swarm is not a group of individuals — it is individuals who know how to talk to each other."*

Dispatched agents can now coordinate via a file-based message bus. Teams are created, agents communicate, results are collected.

### Team Orchestrator
```bash
bash .claude/hooks/pulse/pulse-team-orchestrator.sh create "Review Squad" "Smith,Trinity,Architect" "Review auth module"
bash .claude/hooks/pulse/pulse-team-orchestrator.sh spawn-prompt <team_id> Smith
bash .claude/hooks/pulse/pulse-team-orchestrator.sh status <team_id>
bash .claude/hooks/pulse/pulse-team-orchestrator.sh collect <team_id>
bash .claude/hooks/pulse/pulse-team-orchestrator.sh dissolve <team_id>
```

### Agent Messenger (used by spawned agents)
```bash
bash .claude/hooks/pulse/pulse-agent-messenger.sh send <team_id> <from> <to|all> "message"
bash .claude/hooks/pulse/pulse-agent-messenger.sh read <team_id> <agent> --unread
bash .claude/hooks/pulse/pulse-agent-messenger.sh report <team_id> <agent> "working" "summary"
bash .claude/hooks/pulse/pulse-agent-messenger.sh block <team_id> <agent> "what's blocking"
bash .claude/hooks/pulse/pulse-agent-messenger.sh complete <team_id> <agent> "result summary"
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

---

## GATEWAY: Messaging as UI (Phase C / ADR-018)

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
bash .claude/hooks/core/matrix-services.sh start gateway   # Start
bash .claude/hooks/core/matrix-services.sh stop gateway    # Stop
bash .claude/hooks/core/matrix-services.sh status          # Check all services
```

### Setup
1. Create bot via @BotFather → get token
2. `export TELEGRAM_BOT_TOKEN="your-token"`
3. `export GOOGLE_API_KEY="your-key"` (or OPENAI_API_KEY)
4. Configure `.matrix.json` with your Telegram user ID in `gateway.channels.telegram.allowed_users`
5. `bash .claude/hooks/core/matrix-services.sh start gateway`

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

---

## DISPATCH LEARNING: Self-Tuning Rules (Phase D)

> *"The system learns which dispatches succeed and which don't."*

### Recording Outcomes
```bash
bash .claude/hooks/pulse/pulse-dispatch-learner.sh outcome <rule_id> success "Tests fixed"
bash .claude/hooks/pulse/pulse-dispatch-learner.sh outcome <rule_id> failure "Agent couldn't find the issue"
bash .claude/hooks/pulse/pulse-dispatch-learner.sh outcome <rule_id> timeout "Took too long"
```

### Analysis
```bash
bash .claude/hooks/pulse/pulse-dispatch-learner.sh analyze   # Rule effectiveness report
bash .claude/hooks/pulse/pulse-dispatch-learner.sh tune       # Auto-adjust rule confidence
bash .claude/hooks/pulse/pulse-dispatch-learner.sh report     # Full learning report
```

### Self-Tuning Logic
- **High success (>= 80%)**: Reduce cooldown, promote to auto-dispatch
- **Low success (<= 30%)**: Increase cooldown, demote from auto-dispatch
- Requires 3+ outcomes per rule before adjustments
- All adjustments logged to `psi/state/pulse/dispatch-learnings.json`

### Data
- **Outcomes**: `psi/state/pulse/dispatch-outcomes.jsonl`
- **Learnings**: `psi/state/pulse/dispatch-learnings.json`

---

## PROACTIVE INTELLIGENCE: Anomaly Detection (Phase E)

> *"I don't predict the future. I see the patterns that make it inevitable."*

Automated intelligence analysis — anomaly detection, trend analysis, and task suggestions.

### Usage
```bash
bash .claude/hooks/pulse/pulse-proactive-intel.sh analyze     # Full analysis
bash .claude/hooks/pulse/pulse-proactive-intel.sh anomalies   # Detect anomalies only
bash .claude/hooks/pulse/pulse-proactive-intel.sh trends      # Trend analysis
bash .claude/hooks/pulse/pulse-proactive-intel.sh suggest      # Task suggestions
bash .claude/hooks/pulse/pulse-proactive-intel.sh brief        # One-line briefing
```

### Anomaly Detection
| Anomaly | Trigger | Severity |
|---------|---------|----------|
| Error spike | 3+ failures in 1 hour | high |
| Dispatch storm | 5+ dispatches in 30 min | medium |
| System silence | 0 events in 2 hours (during active period) | low |
| Persistent failures | Same rule failing 3+ times | high |

### Output
- **File**: `psi/state/pulse/proactive-intel.json`
- **Health score**: 0-100 (100 = no issues)

---

## SELF-HEALING: Auto-Repair (Phase F)

> *"The body heals itself. The Matrix should too."*

Detects and repairs common infrastructure issues automatically.

### Usage
```bash
bash .claude/hooks/pulse/pulse-self-heal.sh scan     # Read-only diagnostic
bash .claude/hooks/pulse/pulse-self-heal.sh heal     # Fix detected issues
bash .claude/hooks/pulse/pulse-self-heal.sh hooks    # Check hook permissions + syntax
bash .claude/hooks/pulse/pulse-self-heal.sh state    # Validate JSON/JSONL state files
bash .claude/hooks/pulse/pulse-self-heal.sh pids     # Clean stale PID files
bash .claude/hooks/pulse/pulse-self-heal.sh services # Verify directory structure
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
- **Log**: `psi/state/pulse/heal-log.jsonl` — every fix recorded with timestamp

---

## WATCHDOG: Service Monitor (Phase G)

> *"While you sleep, the watchdog keeps the gates."*

Background daemon that monitors Matrix services and auto-restarts crashed ones.

### Usage
```bash
bash .claude/hooks/pulse/pulse-watchdog.sh start     # Start daemon (background)
bash .claude/hooks/pulse/pulse-watchdog.sh stop      # Stop daemon
bash .claude/hooks/pulse/pulse-watchdog.sh status    # Show service health
bash .claude/hooks/pulse/pulse-watchdog.sh check     # Run one check cycle
bash .claude/hooks/pulse/pulse-watchdog.sh report    # Full uptime report
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
- **Status**: `psi/state/pulse/watchdog-status.json`

### Management via matrix-services.sh
```bash
bash .claude/hooks/core/matrix-services.sh start watchdog
bash .claude/hooks/core/matrix-services.sh stop watchdog
```

---

## DISPATCH BUNDLING: Smart Grouping (Phase H)

> *"One agent, one task? Efficient. One team, related tasks? Powerful."*

Groups related dispatches into team operations for parallel execution.

### Usage
```bash
bash .claude/hooks/pulse/pulse-dispatch-bundler.sh bundle    # Group pending dispatches
bash .claude/hooks/pulse/pulse-dispatch-bundler.sh preview    # Preview without acting
bash .claude/hooks/pulse/pulse-dispatch-bundler.sh history    # Recent bundle history
```

### Bundling Logic
| Trigger | Strategy |
|---------|----------|
| Same topic prefix (e.g., `ci-*`) | Group into single team operation |
| Same agent, 3+ tasks | Bundle to reduce context switches |
| Time proximity (<5min apart) | Candidate for grouping |

### Output
- **Log**: `psi/state/pulse/bundle-log.jsonl`

---

## GATEWAY MEMORY: Persistent Conversations (Phase I)

> *"Memory makes the messenger wise."*

Telegram conversations persist across sessions. Context injected into agent system prompts.

### How It Works
- Messages saved to `psi/state/pulse/gateway-conversations/<userId>.jsonl`
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

---

## AUTO GIT OPS: Git Automation (Phase J)

> *"Git is the source of truth. Keep it clean."*

Automated git health checks and PR preparation.

### Usage
```bash
bash .claude/hooks/pulse/pulse-auto-git.sh check        # Full git health check
bash .claude/hooks/pulse/pulse-auto-git.sh pr-ready      # Validate PR readiness
bash .claude/hooks/pulse/pulse-auto-git.sh suggest-pr    # Generate PR title + body
bash .claude/hooks/pulse/pulse-auto-git.sh stale [days]  # Find stale branches (default 14)
bash .claude/hooks/pulse/pulse-auto-git.sh uncommitted   # Check for uncommitted changes
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

---

## HEALTH DASHBOARD: Visual Status (Phase K)

> *"You can't improve what you can't see."*

Matrix-themed HTML dashboard showing system health at a glance.

### Usage
```bash
bash .claude/hooks/pulse/pulse-dashboard.sh generate    # Generate HTML + JSON
bash .claude/hooks/pulse/pulse-dashboard.sh serve        # Generate and open
bash .claude/hooks/pulse/pulse-dashboard.sh json          # JSON data only
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
- **HTML**: `psi/state/pulse/dashboard.html` — green-on-black terminal aesthetic
- **JSON**: `psi/state/pulse/dashboard.json` — structured data for programmatic access

---

## SKILL DISCOVERY: Auto-Registry (Phase L)

> *"Know your arsenal."*

Automatically scans and validates all skills in the system.

### Usage
```bash
bash .claude/hooks/pulse/pulse-skill-discovery.sh scan       # Discover all skills
bash .claude/hooks/pulse/pulse-skill-discovery.sh validate    # Check skill quality
bash .claude/hooks/pulse/pulse-skill-discovery.sh registry    # Show skill registry
bash .claude/hooks/pulse/pulse-skill-discovery.sh stats       # Summary statistics
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
- **Registry**: `psi/state/pulse/skill-registry.json`
- Stats include: total skills, by source, by agent, quality issues

---

## CONTEXT COMPRESSION: Smart Pre-Compact (Phase M)

> *"Remember what matters. Let go of the rest."*

Intelligent context management before compaction — preserves critical decisions and state.

### Usage
```bash
bash .claude/hooks/pulse/pulse-context-compressor.sh compress     # Full compression cycle
bash .claude/hooks/pulse/pulse-context-compressor.sh extract      # Extract critical events
bash .claude/hooks/pulse/pulse-context-compressor.sh summarize    # Compressed session summary
bash .claude/hooks/pulse/pulse-context-compressor.sh priorities   # Ranked priority list
bash .claude/hooks/pulse/pulse-context-compressor.sh snapshot     # Quick state snapshot
```

### Output Files
| File | Purpose |
|------|---------|
| `psi/state/pulse/context-snapshot.json` | Critical events (commits, failures, completions) |
| `psi/state/pulse/compressed-context.txt` | Under-500-char session summary |
| `psi/state/pulse/priorities.json` | Ranked priority list with reasons |

---

## SESSION CONTINUITY: Structured Handoff (Phase N)

> *"The end of one session is the beginning of the next."*

Generates structured handoff documents ensuring seamless session transitions.

### Usage
```bash
bash .claude/hooks/pulse/pulse-session-continuity.sh generate   # Full continuity document
bash .claude/hooks/pulse/pulse-session-continuity.sh quick       # One-paragraph summary
bash .claude/hooks/pulse/pulse-session-continuity.sh diff        # Changes since last handoff
bash .claude/hooks/pulse/pulse-session-continuity.sh chain       # Last 5 handoffs
bash .claude/hooks/pulse/pulse-session-continuity.sh inject      # Output for session injection
```

### Continuity Document Sections
- **What Was Happening** — current focus
- **What Changed** — commits this session
- **Active Work** — non-completed tasks
- **Unfinished Business** — unresolved failures
- **Next Steps** — first unchecked priority
- **Environment State** — branch, clean status, services

### Output
- **Current**: `psi/state/pulse/continuity.md`
- **Archive**: `psi/swarm/handoffs/YYYY-MM-DD_continuity.md`

---

## METRIC TRACKING: Historical Performance (Phase O)

> *"What gets measured gets managed."*

Tracks system metrics over time for trend analysis and performance monitoring.

### Usage
```bash
bash .claude/hooks/pulse/pulse-metrics.sh collect    # Snapshot current metrics
bash .claude/hooks/pulse/pulse-metrics.sh summary    # Statistical summary
bash .claude/hooks/pulse/pulse-metrics.sh trends     # Trend analysis (↑↓→)
bash .claude/hooks/pulse/pulse-metrics.sh report     # Human-readable report
bash .claude/hooks/pulse/pulse-metrics.sh daily      # Collect + report (for cron)
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
- **History**: `psi/state/pulse/metrics.jsonl` (append-only JSONL)
- **Summary**: `psi/state/pulse/metrics-summary.json`

---

## INTELLIGENT ROUTING: Performance-Based Dispatch (Phase P)

> *"Send the right agent for the job — and learn from the outcome."*

Routes tasks to agents based on their historical success rates.

### Usage
```bash
bash .claude/hooks/pulse/pulse-smart-router.sh route "fix the failing tests"   # Auto-route task
bash .claude/hooks/pulse/pulse-smart-router.sh recommend debug                  # Best agent for type
bash .claude/hooks/pulse/pulse-smart-router.sh profile                          # Agent performance stats
bash .claude/hooks/pulse/pulse-smart-router.sh learn                            # Update from outcomes
bash .claude/hooks/pulse/pulse-smart-router.sh leaderboard                      # Agent rankings
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
- Data: `psi/state/pulse/agent-performance.json`

---

## NOTIFICATION INTELLIGENCE: Adaptive Filtering (Phase Q)

> *"Not every signal deserves your attention."*

Learns which notifications matter to the operator and filters noise accordingly.

### Usage
```bash
bash .claude/hooks/pulse/pulse-notification-intel.sh digest                  # Smart event digest
bash .claude/hooks/pulse/pulse-notification-intel.sh preferences             # Show current weights
bash .claude/hooks/pulse/pulse-notification-intel.sh learn-ack ci:fail       # Mark type as important
bash .claude/hooks/pulse/pulse-notification-intel.sh learn-skip session:start # Mark type as noise
bash .claude/hooks/pulse/pulse-notification-intel.sh reset                   # Restore defaults
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
- Data: `psi/state/pulse/notification-prefs.json`

---

*Systems Reference v1.0 — Extracted from CLAUDE.md v12.0 (2026-03-16)*
