# Evolution Plan: OpenClaw-Inspired Matrix Upgrades

> *"Everything that has a beginning has an end. But every end is a new beginning."*

## Overview

Four evolution tracks inspired by OpenClaw's architecture, adapted to The Oracle Construct's philosophy. Skip marketplace (ClawHub) — we're a personal construct, not a platform.

### Tracks

| Track | Name | Priority | Sessions | Depends On |
|-------|------|----------|----------|------------|
| **A** | HEARTBEAT — Always-On Daemon | High | 1 | Phase 9 (done) |
| **B** | GATEWAY — Messaging as UI | High | 2-3 | Track A |
| **C** | PERMISSIONS — Skill Security Declarations | Low | 0.5 | None |
| **D** | AUTO-EVOLVE — Self-Implementing WEPs | Low | 1 | None |

---

## Track A: HEARTBEAT (Phase 10)

> *OpenClaw's killer feature: the agent wakes up on its own and decides if something needs attention.*

### What It Does

A lightweight daemon that runs between sessions, periodically checking:
- Overdue reminders (`psi/pulse/reminders.json`)
- CI/CD status (GitHub Actions via `gh` CLI)
- PR review requests
- Stale tasks (no updates in 48h+)
- Event queue anomalies (error spikes)

When something needs attention, it notifies via the messaging gateway (Track B) or falls back to a local notification.

### Architecture

```
┌──────────────────────────────────────────┐
│         matrix-heartbeat.ts              │
│    (new service in matrix-services.sh)   │
├──────────────────────────────────────────┤
│  Interval: configurable (default 30min)  │
│  Config: psi/pulse/heartbeat.json        │
│  Checklist: psi/pulse/HEARTBEAT.md       │
│  Notify: Gateway WS → Telegram/Discord   │
│  Fallback: macOS notification / log      │
└──────────────────────────────────────────┘
```

### Implementation

#### A1. Heartbeat config (`psi/pulse/heartbeat.json`)
```json
{
  "enabled": true,
  "interval_minutes": 30,
  "checks": {
    "reminders": true,
    "ci_status": true,
    "pr_reviews": true,
    "stale_tasks": true,
    "error_spikes": true
  },
  "notify": {
    "gateway": "ws://localhost:8082",
    "fallback": "log"
  }
}
```

#### A2. Heartbeat checklist (`psi/pulse/HEARTBEAT.md`)
Markdown file the daemon reads each cycle — similar to OpenClaw's approach. Human-editable, agent-readable:
```markdown
# Heartbeat Checklist
- [ ] Check overdue reminders in reminders.json
- [ ] Check GitHub CI status for active PRs
- [ ] Check for PR review requests assigned to Jarkius
- [ ] Flag tasks with no update in 48+ hours
- [ ] Scan events.jsonl for error spikes (3+ failures in 1h)
```

#### A3. Heartbeat daemon (`lib/matrix-memory-agents/src/heartbeat/heartbeat-daemon.ts`)
- New Bun service managed by `matrix-services.sh`
- Reads `heartbeat.json` config + `HEARTBEAT.md` checklist
- Runs checks on interval
- Sends notifications via Gateway WebSocket (or falls back to file log)
- HTTP health endpoint at port 37892 (`/status`, `/last-check`)
- Writes heartbeat events to `events.jsonl` (`heartbeat:check`, `heartbeat:alert`)

#### A4. Register in `matrix-services.sh`
Add heartbeat as third managed service alongside indexer and hub:
- `matrix-services.sh start heartbeat`
- `matrix-services.sh stop heartbeat`
- PID management, health checks, morning brief integration

#### A5. Morning brief integration
Update `morning-brief.py` to show heartbeat status and any alerts fired since last session.

### New Event Types
```
heartbeat:check    — routine check completed (HEARTBEAT_OK or alerts)
heartbeat:alert    — something needs attention (with details)
heartbeat:start    — daemon started
heartbeat:stop     — daemon stopped
```

### ADR
Create `ADR-012-heartbeat-daemon.md` documenting the design decision.

---

## Track B: GATEWAY — Messaging as UI (Phase 11)

> *One persistent agent, accessible from any messaging app.*

### What It Does

A Gateway service that bridges messaging platforms (Telegram, Discord) to The Oracle Construct. Send a message on Telegram, get Oracle Construct intelligence back.

### Architecture

```
┌─────────────────────────────────────────────┐
│            matrix-gateway.ts                 │
│       (new service in matrix-services.sh)    │
├─────────────┬───────────┬───────────────────┤
│  Telegram   │  Discord  │  Web UI (future)  │
│  (grammY)   │(discord.js│                   │
├─────────────┴───────────┴───────────────────┤
│              Message Router                  │
│  Parse intent → Select agent → Execute       │
├─────────────────────────────────────────────┤
│           Oracle Construct Runtime            │
│  Anthropic SDK · Tool Use · PULSE · Memory   │
│  Soul injection from .claude/agents/*.md     │
└─────────────────────────────────────────────┘
```

### Message Flow

```
User → Telegram → Gateway → Agent Router
                                ↓
                    Detect agent from message:
                    "Neo, build the auth endpoint"  → Neo
                    "What's the status?"            → Oracle
                    "Review PR #42"                 → Smith
                    "@tank find auth files"         → Tank
                                ↓
                    Inject agent soul (.claude/agents/*.md)
                    as system prompt to Claude API
                                ↓
                    Claude API with tool_use:
                    - Shell execution (sandboxed)
                    - File read/write
                    - Memory recall (bun memory)
                    - Git operations
                                ↓
                    Response → Gateway → Telegram → User
```

### Implementation

#### B1. Dependencies
```bash
# In lib/matrix-memory-agents/
bun add grammy               # Telegram Bot API
bun add @anthropic-ai/sdk    # Claude API
bun add discord.js           # Discord (optional, phase 2)
```

#### B2. Gateway config (`.matrix.json` extension)
Add gateway section to existing `.matrix.json`:
```json
{
  "gateway": {
    "enabled": true,
    "port": 8082,
    "channels": {
      "telegram": {
        "enabled": true,
        "bot_token_env": "TELEGRAM_BOT_TOKEN",
        "allowed_users": ["jarkius_telegram_id"]
      },
      "discord": {
        "enabled": false,
        "bot_token_env": "DISCORD_BOT_TOKEN",
        "allowed_channels": []
      }
    },
    "security": {
      "allowed_users_only": true,
      "sandbox_shell": true,
      "max_tokens_per_message": 4096,
      "rate_limit_per_minute": 10
    }
  }
}
```

#### B3. Agent Router (`lib/matrix-memory-agents/src/gateway/agent-router.ts`)
- Parse incoming message for agent triggers (`Neo,`, `@smith`, `/oracle`, etc.)
- Default to Oracle if no agent specified
- Load agent definition from `.claude/agents/*.md`
- Build system prompt: agent soul + current context (focus, tasks)
- Route to Claude API with appropriate model tier (ADR-003)

#### B4. Gateway service (`lib/matrix-memory-agents/src/gateway/gateway.ts`)
- Main entry point, managed by `matrix-services.sh`
- Initializes channel adapters (Telegram, Discord)
- WebSocket server on port 8082 for internal communication (heartbeat alerts)
- Message queue for rate limiting
- HTTP health endpoint (`/status`, `/channels`)

#### B5. Telegram adapter (`lib/matrix-memory-agents/src/gateway/channels/telegram.ts`)
- grammY bot initialization
- Message handling: text, commands, photos (for screenshot analysis)
- Response formatting: Markdown → Telegram MarkdownV2
- User authentication against allowed_users list
- Typing indicator while processing

#### B6. Claude API bridge (`lib/matrix-memory-agents/src/gateway/claude-bridge.ts`)
- Anthropic SDK client
- Tool definitions matching Oracle Construct capabilities:
  - `shell_exec` — run commands (sandboxed)
  - `file_read` / `file_write` — filesystem access
  - `memory_recall` — semantic search via bun memory
  - `task_list` — read/update active.json
  - `git_status` / `git_log` — repository state
  - `pulse_events` — recent events
- Agentic loop: tool_use → execute → feed back → continue until done
- Token budget per message (configurable)

#### B7. Security layer
- **User allowlist** — only configured Telegram/Discord users can interact
- **Shell sandbox** — commands run in restricted mode (no rm -rf, no force push)
- **Rate limiting** — prevent runaway token usage
- **Audit log** — all gateway interactions logged to events.jsonl as `gateway:message`
- **No secrets in messages** — filter .env values from responses

#### B8. Register in `matrix-services.sh`
Add gateway as fourth managed service:
- `matrix-services.sh start gateway`
- Auto-start configurable in `psi/pulse/heartbeat.json`

#### B9. Heartbeat → Gateway bridge
When heartbeat detects something, it sends via Gateway WebSocket → Telegram notification.

### New Event Types
```
gateway:message    — incoming user message (channel, agent, intent)
gateway:response   — outgoing response (agent, tokens, duration)
gateway:error      — processing failure
gateway:connect    — channel connected
gateway:disconnect — channel disconnected
```

### ADR
Create `ADR-013-messaging-gateway.md` documenting the design decision.

### Phase 2 (Future)
- Discord channel support
- Web UI dashboard
- Voice messages (ElevenLabs TTS via existing voice.sh)
- Image/screenshot analysis (Claude vision)
- Group chat support (multiple users, same construct)

---

## Track C: PERMISSIONS — Skill Security Declarations (Quick Win)

> *Skills declare what they can touch. Users see before they approve.*

### What It Does

Add permission declarations to skill/command definitions. Not enforcement (Claude Code already handles that) — but **visibility**. When a skill is invoked, the user knows what it accesses.

### Implementation

#### C1. Extend workflow frontmatter format
Add `permissions` block to `.agent/workflows/*.md`:

```yaml
---
name: neo
permissions:
  files: [read, write]       # Can read/write project files
  shell: [git, npm, bun]     # Can run these commands
  network: false              # No external network access
  memory: [read, write]       # Can access memory system
  destructive: false          # No force-push, rm -rf, etc.
---
```

#### C2. Update agent definitions
Add matching permissions to `.claude/agents/*.md` frontmatter for each agent.

#### C3. Document in CLAUDE.md
Add a "Skill Permissions" section listing each agent's declared access scope.

### No ADR needed — this is a convention, not architecture.

---

## Track D: AUTO-EVOLVE — Self-Implementing WEPs (Phase 12)

> *Close the loop: pattern → proposal → implementation → applied.*

### What It Does

Currently the Evolution Proposer drafts WEPs but stops there. Track D adds an **auto-implementation** path for low-risk WEPs (config changes, documentation updates, hook tweaks) while keeping Oracle review for high-risk changes.

### Risk Classification

```
LOW RISK (auto-implementable):
  - Config file changes (json)
  - Documentation updates (md)
  - Hook parameter tweaks
  - New event types
  - Morning brief format changes

HIGH RISK (require Oracle review):
  - New services/daemons
  - Architecture changes
  - Security-related changes
  - Dependency additions
  - Shell script modifications
```

### Implementation

#### D1. Add risk level to WEP proposals
Evolution proposer already generates WEPs. Add a `risk: low|medium|high` field to the frontmatter.

#### D2. Auto-implement script (`pulse-auto-evolve.sh`)
- Triggered by heartbeat (Track A) or at boot
- Scans `psi/memory/evolution/proposals/` for `risk: low` WEPs
- For each low-risk WEP:
  - Parse the implementation steps
  - Execute file edits (config changes, doc updates)
  - Commit with message: `chore(evolution): auto-apply WEP-NNN`
  - Move to `applied/`
  - Log event: `evolution:auto-applied`
- For medium/high risk: skip, announce at boot for Oracle review

#### D3. Guard rails
- **Dry-run first** — show what would change before applying
- **Git safety** — auto-commit on a branch, not main
- **Rollback** — if any step fails, revert all changes
- **Audit** — every auto-evolution logged to events.jsonl
- **Kill switch** — `heartbeat.json` flag: `"auto_evolve": false`

### ADR
Create `ADR-014-auto-evolution.md` documenting the self-improvement loop.

---

## Implementation Order

```
Session 1: Track A (HEARTBEAT)
  ├── A1: heartbeat.json config
  ├── A2: HEARTBEAT.md checklist
  ├── A3: heartbeat-daemon.ts
  ├── A4: Register in matrix-services.sh
  ├── A5: Morning brief integration
  └── ADR-012

Session 2: Track B (GATEWAY) — Core
  ├── B1: Dependencies
  ├── B2: Gateway config
  ├── B3: Agent router
  ├── B4: Gateway service
  ├── B5: Telegram adapter
  └── B6: Claude API bridge

Session 3: Track B (GATEWAY) — Security + Polish
  ├── B7: Security layer
  ├── B8: Register in matrix-services.sh
  ├── B9: Heartbeat → Gateway bridge
  ├── ADR-013
  └── End-to-end testing

Session 4: Track C + D (Quick wins)
  ├── C1-C3: Permission declarations
  ├── D1-D3: Auto-evolve script
  └── ADR-014

```

## Pre-Requisites

- [ ] Telegram Bot Token (create via @BotFather)
- [ ] `ANTHROPIC_API_KEY` env var for Claude API calls from gateway
- [ ] Decide on gateway port (proposed: 8082)
- [ ] Review security model for shell execution via messaging

---

## Track E: TRUE SELF-EVOLUTION (Phase 13)

> *"The system improves itself while you sleep."*

### What It Does

Extends Phase 12 (ADR-014) from low-risk config tweaks to full sandbox-based self-improvement. Three tiers of increasing autonomy.

### Tiers

| Tier | Name | What | Depends On |
|------|------|------|-----------|
| **1** | Sandbox Evolution | Branch → test gates → merge/rollback | Phase 12 (done) |
| **2** | Intelligent Evolution | LLM generates implementation → sandbox → test | Phase 11 (Gateway/Claude API) |
| **3** | Cascading Evolution | Successful WEP triggers related proposals | Tier 2 proven |

### Tier 1 Implementation (Priority — 1 session)

```
Pattern detected → WEP proposed → Create sandbox branch
    → Apply changes on branch → Run 5 test gates
        → PASS: Merge, archive, log success
        → FAIL: Delete branch, reject, log failure + reason
```

**Test gates**: syntax check → hook health → memory health → service health → custom command

**Expanded scope** (beyond ADR-014):
- `.sh` files in `.claude/hooks/`
- Config files in `psi/pulse/`
- WEP metadata

**Sacred files** (never auto-evolved):
- SOUL.md, CLAUDE.md, USER.md, BOOT.md
- psi/The_Source/**
- .claude/agents/*.md

### Implementation Steps

| Step | What | Effort |
|------|------|--------|
| E1 | Extend `pulse-auto-evolve.sh` with sandbox branching | ~1h |
| E2 | Add 5 test gates (syntax, hooks, memory, services, custom) | ~1h |
| E3 | Add `evolution-log.jsonl` and event types | ~30m |
| E4 | Sacred files exclusion list | ~15m |
| E5 | Extended WEP frontmatter format | ~15m |
| E6 | Wire to heartbeat (optional trigger) | ~30m |

### New Event Types
```
evolution:sandbox    — WEP moved to sandbox branch
evolution:test       — Test gate result (pass/fail)
evolution:applied    — WEP merged successfully
evolution:rejected   — WEP failed, rolled back
evolution:cascade    — Tier 3: new WEP triggered
evolution:learning   — Meta-learning captured
```

### ADR
See `ADR-015-true-self-evolution.md`.

---

## Revised Implementation Order

```
Session N: Track E Tier 1 (TRUE SELF-EVOLUTION)
  ├── E1: Sandbox branching in pulse-auto-evolve.sh
  ├── E2: 5 test gates
  ├── E3: Evolution log (JSONL)
  ├── E4: Sacred files exclusion
  ├── E5: Extended WEP frontmatter
  └── E6: Heartbeat trigger wiring

Session N+1: Track B (GATEWAY) — Core
  ├── B1: Dependencies (grammy, @anthropic-ai/sdk)
  ├── B2: Gateway config (.matrix.json)
  ├── B3: Agent Router
  ├── B4: Claude API Bridge
  ├── B5: Telegram Adapter
  └── B6: Security Layer

Session N+2: Track B (GATEWAY) — Integration
  ├── B7: Register in matrix-services.sh
  ├── B8: Heartbeat → Gateway bridge
  ├── B9: End-to-end testing
  └── ADR-013

Session N+3: Track E Tier 2 (INTELLIGENT EVOLUTION)
  ├── Claude API bridge (reuse Gateway infra)
  ├── LLM-generated implementations
  ├── Evaluation prompts
  └── Evolution memory analysis
```

---

## What We're NOT Doing

- **No marketplace/ClawHub** — personal construct, not a platform
- **No WhatsApp** — unofficial API, ban risk, not worth it
- **No social network for agents** (Moltbook) — fun but frivolous
- **No autonomous execution without review** for high-risk changes
- **No auto-evolution of sacred files** — SOUL.md, CLAUDE.md are human-gated
