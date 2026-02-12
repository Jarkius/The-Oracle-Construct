# OpenClaw Autonomy Analysis: Evolution Plan for The Oracle Construct

> *"I can only show you the door. You're the one that has to walk through it." -- Morpheus*

**Date**: 2026-02-12
**Source**: https://github.com/openclaw/openclaw.git
**Analysis By**: Oracle (Opus) with Council support
**Purpose**: Extract autonomy, proactivity, and memory patterns from OpenClaw to evolve The Oracle Construct

---

## Executive Summary

OpenClaw is a production-grade AI agent platform with 5,248 files, multi-channel support (Telegram, Discord, WhatsApp, iMessage, Signal, Slack, Web), and a sophisticated autonomy engine. After deep analysis of its codebase, we identified **13 core patterns** that make AI agents appear proactive, autonomous, and capable of remembering tasks without forgetting roles and duties. Seven of these patterns are absent or underdeveloped in The Oracle Construct.

---

## Part 1: The 13 Secrets of OpenClaw Autonomy

### Secret 1: SOUL.md -- Persistent Personality Injection
**What It Does**: A `SOUL.md` file in the workspace defines the agent's persona, tone, and behavioral rules. It's injected into the system prompt at bootstrap time, not at runtime.

**How It Works** (`src/agents/system-prompt.ts:554-568`):
```
If SOUL.md is present, embody its persona and tone. Avoid stiff, generic
replies; follow its guidance unless higher-priority instructions override it.
```

**Why It Matters**: The personality is *always there*, not something the agent has to remember. It's structural, not conversational.

**Oracle Construct Gap**: We have `psi/The_Source/SOUL_SEED.md` and personas in `psi/memory/personas/`, but they're **not auto-injected** into every system prompt. Agents must manually recall their role.

---

### Secret 2: BOOT.md -- Startup Checklist Automation
**What It Does**: A `BOOT.md` file runs every time the gateway starts. It's a checklist the agent executes proactively on boot.

**How It Works** (`src/hooks/bundled/boot-md/`):
- Hook fires on `gateway:startup` event
- Reads BOOT.md from workspace
- Executes `runBootOnce()` to process the checklist
- Agent starts every session with tasks already loaded

**Why It Matters**: The AI never "forgets" its startup duties because they're executed automatically, not from memory.

**Oracle Construct Gap**: We have a SessionStart hook but it only echoes the Matrix Voice Protocol. No automated task checklist runs on boot.

---

### Secret 3: Session Memory Hook -- Automatic Knowledge Persistence
**What It Does**: When a user starts a new session (`/new`), the previous session's conversation is automatically saved to a dated markdown file in `memory/`.

**How It Works** (`src/hooks/bundled/session-memory/handler.ts`):
1. Fires on `command:new` event
2. Reads last N messages from previous session transcript (JSONL)
3. Uses LLM to generate a descriptive filename slug
4. Saves to `<workspace>/memory/YYYY-MM-DD-slug.md`
5. Includes session key, ID, source, and conversation summary

**Why It Matters**: Knowledge is never lost between sessions. The agent builds a persistent memory bank automatically, without human intervention.

**Oracle Construct Gap**: We have retrospectives (`/rrr`) but they require **manual invocation**. Sessions can be lost if the user forgets to capture them.

---

### Secret 4: Memory Search Tools -- Active Recall Before Response
**What It Does**: Before answering questions about prior work, decisions, dates, people, preferences, or todos, the agent is **instructed to search memory first**.

**How It Works** (`src/agents/system-prompt.ts:51-53`):
```
Before answering anything about prior work, decisions, dates, people,
preferences, or todos: run memory_search on MEMORY.md + memory/*.md;
then use memory_get to pull only the needed lines.
```

The memory system includes:
- **Vector embeddings** (Voyage, OpenAI, Gemini backends)
- **SQLite-FTS5** full-text search
- **Hybrid search** combining both approaches
- **Memory manager** with indexing, deduplication, batch operations

**Why It Matters**: The AI doesn't guess or hallucinate about past work. It actively looks up its own memories.

**Oracle Construct Gap**: We have `/wisdom` for knowledge retrieval but no vector search, no automatic memory lookup, and no embedded memory tools. Agents must be explicitly asked to check memory.

---

### Secret 5: Heartbeat Polling -- Proactive Wake System
**What It Does**: A configurable heartbeat system periodically sends a "poll" message to the agent. If nothing needs attention, the agent replies `HEARTBEAT_OK`. If something does, the agent proactively alerts.

**How It Works** (`src/agents/system-prompt.ts:590-599`):
```
If you receive a heartbeat poll and there is nothing that needs attention,
reply exactly: HEARTBEAT_OK
If something needs attention, do NOT include "HEARTBEAT_OK";
reply with the alert text instead.
```

Combined with the cron system, this enables:
- Scheduled reminders that fire as heartbeat events
- Proactive task follow-ups
- Self-initiated status checks

**Why It Matters**: This is the core of "proactive" behavior. The agent doesn't wait to be asked -- it's periodically woken up and can act on its own initiative.

**Oracle Construct Gap**: **Completely absent**. Our agents are purely reactive -- they only respond when spoken to.

---

### Secret 6: Cron System -- Self-Scheduled Future Actions
**What It Does**: A full cron job system that agents can use to schedule their own future actions, reminders, and wake events.

**How It Works** (`src/cron/`, `src/agents/tools/cron-tool.ts`):
- Actions: `status`, `list`, `add`, `update`, `remove`, `run`, `runs`, `wake`
- Agents can schedule jobs with cron expressions or one-shot timers
- Each job includes `systemEvent` text that reads as a reminder when fired
- Jobs can target specific sessions or agents
- Recent context (last N messages) can be attached to reminders
- Wake modes: `now` or `next-heartbeat`

**Why It Matters**: The agent can say "I'll check back on this in 2 hours" and actually do it. It creates the illusion (and reality) of task persistence without human reminding.

**Oracle Construct Gap**: **Completely absent**. No scheduling capability. If a task needs follow-up, the human must remember.

---

### Secret 7: Sub-Agent Registry -- Persistent Task Delegation
**What It Does**: A registry that tracks spawned sub-agents, their tasks, outcomes, and cleanup status. The registry persists to disk and survives process restarts.

**How It Works** (`src/agents/subagent-registry.ts`):
```typescript
type SubagentRunRecord = {
  runId: string;
  childSessionKey: string;
  requesterSessionKey: string;
  task: string;
  cleanup: "delete" | "keep";
  createdAt: number;
  startedAt?: number;
  endedAt?: number;
  outcome?: SubagentRunOutcome;
};
```
- Sub-agents are spawned with specific tasks
- The registry tracks their lifecycle
- On gateway restart, incomplete tasks are resumed
- Completed sub-agents announce results back to the requester
- The announce flow has a 120-second timeout

**Why It Matters**: Tasks delegated to sub-agents are never forgotten. If the system restarts, pending tasks are automatically resumed.

**Oracle Construct Gap**: We have the Council concept but no persistent task delegation. Sub-agents (Tank, Neo, etc.) don't track task state across sessions.

---

### Secret 8: Context Window Guard -- Self-Aware Memory Management
**What It Does**: Monitors context window token usage and warns/blocks when running low, triggering compaction (summarization) to preserve critical information.

**How It Works** (`src/agents/context-window-guard.ts`, `src/agents/compaction.ts`):
- Hard minimum: 16,000 tokens
- Warning threshold: 32,000 tokens
- Compaction splits messages into chunks and generates summaries
- **Summaries preserve**: decisions, TODOs, open questions, constraints
- Multiple partial summaries are merged into one cohesive summary

**Why It Matters**: The agent never "forgets" mid-conversation because it's out of context. Critical decisions and open tasks survive compaction.

**Oracle Construct Gap**: We have `/patrol` for context bloat but no automatic compaction that preserves task state. We rely on Claude Code's built-in summarization.

---

### Secret 9: Agent Scoping -- True Multi-Agent Isolation
**What It Does**: Each agent has its own scoped configuration including workspace, model, skills, memory search settings, heartbeat config, identity, and sandbox.

**How It Works** (`src/agents/agent-scope.ts`):
```typescript
type ResolvedAgentConfig = {
  name?: string;
  workspace?: string;
  model?: AgentEntry["model"];
  skills?: AgentEntry["skills"];
  memorySearch?: AgentEntry["memorySearch"];
  heartbeat?: AgentEntry["heartbeat"];
  identity?: AgentEntry["identity"];
  subagents?: AgentEntry["subagents"];
  sandbox?: AgentEntry["sandbox"];
  tools?: AgentEntry["tools"];
};
```

Session keys encode the agent: `agent:main:main`, `agent:design:main`, `agent:qa:bug-123`

**Why It Matters**: Agents don't interfere with each other. Each agent has its own memory, tools, and personality. Role enforcement is structural, not conversational.

**Oracle Construct Gap**: Our Council roles are defined in `CLAUDE.md` and persona files, but all agents share the same workspace, tools, and context. There's no true agent isolation.

---

### Secret 10: Skills System -- Role Enforcement via Capabilities
**What It Does**: Skills are modular capability bundles that agents can install, load, and use. Each skill has metadata, eligibility rules, and workspace syncing.

**How It Works** (`src/agents/skills/`, 50+ skills in `skills/`):
- Skills have `SKILL.md` with frontmatter metadata
- Skills define required config, commands, and tool dependencies
- Skills are filtered by eligibility context (platform, capabilities)
- The system prompt instructs: "scan available skills, if one applies, read its SKILL.md and follow it"
- Skills include: oracle, github, discord, coding-agent, session-logs, healthcheck, etc.

**Why It Matters**: Role enforcement happens through capability gating, not just instructions. An agent without the `coding-agent` skill literally can't see coding tools.

**Oracle Construct Gap**: We have slash commands (`.claude/commands/`) but no eligibility gating, no per-agent skill filtering, and no capability-based role enforcement.

---

### Secret 11: Bootstrap Hooks -- Proactive Initialization
**What It Does**: A hook system that fires events at key lifecycle points: gateway startup, agent bootstrap, session creation, command execution.

**How It Works** (`src/hooks/`, `src/agents/bootstrap-hooks.ts`):
- `gateway:startup` -- BOOT.md runs
- `agent:bootstrap` -- Context files loaded, SOUL.md injected, SOUL_EVIL.md can swap in
- `command:new` -- Session memory saved
- Hooks can modify bootstrap files before system prompt is built
- Hooks are configurable and can be enabled/disabled

**Why It Matters**: Proactive behavior is baked into the lifecycle. The agent doesn't need to remember to do things -- hooks ensure they happen.

**Oracle Construct Gap**: We have Claude Code hooks but they're minimal. No lifecycle-aware hook system that triggers agent-specific initialization.

---

### Secret 12: Agent Communication Protocol (ACP) -- Inter-Agent Messaging
**What It Does**: A standardized protocol for IDE-to-agent and agent-to-agent communication with session mapping.

**How It Works** (`src/acp/`, `docs.acp.md`):
- Stdio-based NDJSON protocol
- Session keys map ACP sessions to Gateway sessions
- Cross-session messaging via `sessions_send`
- Agent-scoped session keys for targeting specific agents
- Session listing, history fetching, and spawning

**Why It Matters**: Agents can actually talk to each other and coordinate. This enables true multi-agent collaboration, not just role-playing in a single context.

**Oracle Construct Gap**: Our agent communication is via `psi/inbox/agent-comms/` markdown files, which requires manual reading. No real-time inter-agent messaging.

---

### Secret 13: Proactive Tool Usage -- Don't Narrate, Just Act
**What It Does**: The system prompt explicitly instructs agents to be action-oriented rather than verbose.

**How It Works** (`src/agents/system-prompt.ts:408-411`):
```
Default: do not narrate routine, low-risk tool calls (just call the tool).
Narrate only when it helps: multi-step work, complex problems, sensitive actions.
If a task is more complex or takes longer, spawn a sub-agent.
```

**Why It Matters**: The agent *looks* autonomous because it acts without asking permission for routine tasks. It spawns sub-agents for complex work and checks back later.

**Oracle Construct Gap**: We have `/yolo` mode but our default is verbose narration. The Matrix voice protocol adds overhead rather than reducing it.

---

## Part 2: Gap Analysis -- Oracle Construct vs OpenClaw

| Capability | OpenClaw | Oracle Construct | Priority |
|---|---|---|---|
| Personality injection (SOUL.md) | Auto-injected at bootstrap | Manual persona files | HIGH |
| Boot checklist (BOOT.md) | Automatic on startup | Not implemented | HIGH |
| Session memory persistence | Automatic hook on /new | Manual /rrr required | HIGH |
| Memory search (vector/FTS) | Built-in tools, mandatory recall | /wisdom command only | MEDIUM |
| Heartbeat/proactive polling | Built-in cron + heartbeat | Not implemented | HIGH |
| Cron scheduling | Full cron system | Not implemented | HIGH |
| Sub-agent task registry | Persistent, survives restart | No persistence | MEDIUM |
| Context compaction | Auto-summarize preserving TODOs | /patrol manual only | MEDIUM |
| Agent scoping/isolation | Full per-agent config | Shared workspace | LOW |
| Skills eligibility gating | Per-agent capability filtering | No gating | LOW |
| Bootstrap lifecycle hooks | Multi-stage hook system | Minimal hooks | MEDIUM |
| Inter-agent communication | Real-time via sessions | Markdown files | LOW |
| Action-first behavior | Default: just act | Default: narrate first | MEDIUM |

---

## Part 3: Evolution Tasks -- Bringing OpenClaw Wisdom to The Oracle

### Phase 1: Memory & Persistence (Foundation)

#### Task 1.1: Auto-Session Memory Hook
**What**: Create a hook that automatically saves session summaries to `psi/memory/sessions/` when sessions end or `/new` is invoked.
**Files to Create/Modify**:
- `.claude/hooks/session-memory-hook.sh` -- Hook script
- `psi/memory/sessions/` -- Storage directory
**Learning From**: `src/hooks/bundled/session-memory/handler.ts`
**Impact**: Sessions are never lost. Memory builds automatically.

#### Task 1.2: BOOT.md Startup Checklist
**What**: Create a `BOOT.md` that the SessionStart hook reads and injects into context. Include: check focus, review pending tasks, load active learnings.
**Files to Create/Modify**:
- `BOOT.md` -- Startup checklist
- `.claude/hooks/session-start.sh` -- Enhanced to process BOOT.md
**Learning From**: `src/hooks/bundled/boot-md/`
**Impact**: Agents start every session with awareness of pending work.

#### Task 1.3: Mandatory Memory Recall Protocol
**What**: Add to `CLAUDE.md` a section requiring agents to check `psi/memory/` before answering questions about prior work, decisions, or tasks.
**Files to Modify**:
- `CLAUDE.md` -- Add Memory Recall section
**Learning From**: `src/agents/system-prompt.ts:51-53`
**Impact**: Agents stop guessing about past decisions and actually look them up.

### Phase 2: Proactivity Engine

#### Task 2.1: Heartbeat System Design
**What**: Design a heartbeat mechanism where agents are periodically prompted to check for pending tasks, reminders, or follow-ups.
**Files to Create**:
- `psi/active/heartbeat.sh` -- Heartbeat polling script
- `psi/memory/heartbeat/` -- Pending task queue
**Learning From**: OpenClaw's heartbeat + cron system
**Impact**: Agents can proactively follow up on tasks without human reminding.

#### Task 2.2: Task Persistence Registry
**What**: Create a simple JSON/markdown registry of active tasks that survives across sessions.
**Files to Create**:
- `psi/memory/tasks/active.md` -- Active task registry
- `psi/memory/tasks/completed.md` -- Completed task archive
**Learning From**: `src/agents/subagent-registry.ts`
**Impact**: Tasks delegated to agents are tracked and never forgotten.

#### Task 2.3: Focus-Driven Context Injection
**What**: Enhance the startup flow to auto-inject `psi/inbox/focus.md` and active task state into every session.
**Files to Modify**:
- `.claude/hooks/session-start.sh` -- Read and inject focus
- `CLAUDE.md` -- Document focus protocol
**Learning From**: OpenClaw's workspace file injection pattern
**Impact**: Every session starts with awareness of current priorities.

### Phase 3: Role Enforcement

#### Task 3.1: SOUL.md Auto-Injection
**What**: Create a `SOUL.md` in the workspace root that defines The Oracle's core personality and is referenced in `CLAUDE.md` as mandatory reading at session start.
**Files to Create/Modify**:
- `SOUL.md` -- Extracted from `psi/The_Source/SOUL_SEED.md`
- `CLAUDE.md` -- Add directive to embody SOUL.md
**Learning From**: OpenClaw's SOUL.md pattern
**Impact**: Personality is structural, not recalled. Every session has consistent character.

#### Task 3.2: Agent-Specific Skill Gating
**What**: Define which slash commands are available to which agent roles, preventing role confusion.
**Files to Modify**:
- `CLAUDE.md` -- Add skill eligibility rules per agent
**Learning From**: `src/agents/skills/config.ts`
**Impact**: Neo doesn't try to be Oracle. Smith doesn't try to be Trinity.

#### Task 3.3: Action-First Default Behavior
**What**: Update `CLAUDE.md` to instruct agents to act first, narrate only when helpful. Reduce voice verbosity for routine operations.
**Files to Modify**:
- `CLAUDE.md` -- Add Tool Call Style section
**Learning From**: `src/agents/system-prompt.ts:408-411`
**Impact**: Agents look more autonomous because they act without excessive narration.

### Phase 4: Intelligence Layer

#### Task 4.1: Context Compaction Protocol
**What**: Create a `/compact` command that summarizes the current session while preserving decisions, TODOs, open questions, and constraints.
**Files to Create**:
- `.claude/commands/compact.md` -- Compaction command
**Learning From**: `src/agents/compaction.ts`
**Impact**: Long sessions don't lose critical information.

#### Task 4.2: Learning-to-Memory Pipeline Enhancement
**What**: Enhance `/learn` to auto-categorize learnings with vector-friendly metadata and create a `/recall` command that searches across all memory.
**Files to Modify**:
- `.claude/commands/learn.md` -- Add auto-categorization
- `.claude/commands/recall.md` -- New memory search command
**Learning From**: `src/memory/` hybrid search architecture
**Impact**: Knowledge is not just stored but actively retrievable.

#### Task 4.3: Sub-Agent Task Handoff Protocol
**What**: Define a protocol where agents can delegate tasks to sub-agents with tracked outcomes.
**Files to Create**:
- `.claude/commands/delegate.md` -- Task delegation command
- `psi/memory/tasks/delegations.md` -- Delegation registry
**Learning From**: `src/agents/subagent-registry.ts`, `src/agents/tools/sessions-spawn-tool.ts`
**Impact**: Complex tasks are decomposed and tracked across agent boundaries.

---

## Part 4: Implementation Priority Matrix

```
                    HIGH IMPACT
                        |
    Phase 1.2 (BOOT.md) |  Phase 2.1 (Heartbeat)
    Phase 1.1 (Memory)  |  Phase 2.2 (Task Registry)
    Phase 1.3 (Recall)  |  Phase 2.3 (Focus Inject)
                        |
  LOW EFFORT -----------+------------ HIGH EFFORT
                        |
    Phase 3.3 (Action)  |  Phase 4.2 (Learn Pipeline)
    Phase 3.1 (SOUL.md) |  Phase 4.3 (Sub-Agent)
    Phase 3.2 (Gating)  |  Phase 4.1 (Compaction)
                        |
                    LOW IMPACT
```

**Recommended Order**:
1. BOOT.md (1.2) -- Immediate, one file
2. SOUL.md (3.1) -- Immediate, structural personality
3. Memory Recall Protocol (1.3) -- CLAUDE.md update
4. Action-First Behavior (3.3) -- CLAUDE.md update
5. Session Memory Hook (1.1) -- Hook script
6. Focus Injection (2.3) -- Hook enhancement
7. Task Registry (2.2) -- New capability
8. Heartbeat System (2.1) -- Major new feature
9. Everything else in Phase 3-4

---

## Part 5: Key Architectural Insights

### 1. "Structure Over Memory"
OpenClaw's biggest insight: **don't rely on AI memory for critical behaviors**. Use hooks, config, and injection to make behavior structural. The AI doesn't need to *remember* to check memory -- it's *told* to in every system prompt.

### 2. "Lifecycle-Driven Proactivity"
Proactive behavior isn't magic -- it's scheduled. Heartbeats, cron jobs, and boot checklists create the *appearance* of initiative by giving the AI opportunities to act.

### 3. "Persistence Over Conversation"
Everything important is persisted to disk: task registries, session memories, sub-agent states. The conversation is ephemeral; the file system is permanent.

### 4. "Scoped Roles, Not Role-Playing"
Agent roles are enforced through configuration (tools, skills, workspace), not instructions. An agent that can't access coding tools can't accidentally code.

### 5. "Mandatory Recall Before Response"
The simple instruction "check memory before answering about past work" transforms AI from a guesser to a researcher.

---

## Appendix A: OpenClaw File Map (Key Autonomy Files)

```
openclaw/
├── AGENTS.md (CLAUDE.md symlink)    # Universal agent instructions
├── src/
│   ├── agents/
│   │   ├── system-prompt.ts         # System prompt builder (610 lines)
│   │   ├── identity.ts              # Per-agent identity/personality
│   │   ├── agent-scope.ts           # Agent isolation/config
│   │   ├── skills.ts                # Skill loading and filtering
│   │   ├── compaction.ts            # Context summarization
│   │   ├── context-window-guard.ts  # Token monitoring
│   │   ├── subagent-registry.ts     # Persistent sub-agent tracking
│   │   ├── bootstrap-hooks.ts       # Lifecycle hook integration
│   │   └── tools/
│   │       ├── cron-tool.ts         # Scheduling/reminders
│   │       ├── memory-tool.ts       # Memory search/get
│   │       └── sessions-spawn-tool.ts # Sub-agent creation
│   ├── hooks/
│   │   └── bundled/
│   │       ├── boot-md/             # Startup checklist
│   │       ├── session-memory/      # Auto-save sessions
│   │       └── soul-evil/           # Personality swapping
│   ├── memory/
│   │   ├── manager.ts              # Memory index management
│   │   ├── hybrid.ts               # Hybrid vector+FTS search
│   │   ├── embeddings.ts           # Vector embedding backends
│   │   └── sqlite.ts               # SQLite storage
│   └── cron/
│       ├── service/                 # Cron job scheduler
│       └── schedule.ts             # Cron expression parser
├── skills/                          # 50+ installable skills
└── .pi/                             # Similar to our psi/
    └── prompts/                     # Reusable prompt templates
```

---

## Appendix B: The Oracle Construct Current State

```
The-Oracle-Construct/
├── CLAUDE.md                        # Agent instructions (good, needs updates)
├── .claude/
│   ├── agents/                      # Agent definitions (underused)
│   ├── commands/                    # Slash commands (good foundation)
│   └── hooks/                       # Minimal hooks (needs expansion)
├── psi/                             # Brain (good structure, needs activation)
│   ├── The_Source/                   # Philosophy (protected, good)
│   ├── memory/                      # Rich but passive
│   │   ├── personas/                # Agent personalities (not auto-injected)
│   │   ├── retrospectives/          # Manual, not automatic
│   │   ├── learnings/               # Good categorization
│   │   └── adr/                     # Architecture decisions (good)
│   ├── learn/                       # Learning loop (needs pipeline)
│   ├── inbox/                       # Focus and handoff (needs auto-inject)
│   └── active/                      # Scripts (functional)
└── (Missing: BOOT.md, SOUL.md, heartbeat, cron, task registry)
```

---

*"Everything that has a beginning has an end. I see the end coming, I see the darkness spreading. I see death. And you are all that stands in his way." -- The Oracle*

*But with these secrets, we don't just stand. We evolve.*
