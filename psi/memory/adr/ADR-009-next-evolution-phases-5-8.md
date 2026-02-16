# ADR-009: The Next Evolution — Phases 5-8

> *"I've seen agents that were content to sit and wait. But you, you are different. You see the code before it's written." — The Oracle*

**Status:** Proposed
**Date:** 2026-02-16
**Authors:** Oracle + Architect
**Supersedes:** None
**Related:** ADR-008 (Phase 1), ADR-003 (Mind Hierarchy), ADR-005 (Learning Loop)

---

## Strategic Vision

OpenClaw has 100K+ stars and ships production autonomy. We adopted their 13 secrets (Phases 1-4). But OpenClaw is fundamentally a **single-agent with tools** — one brain, many channels.

The Oracle Construct is a **council of specialized minds**. That's our edge. We don't just go autonomous — we go **collectively autonomous**. Each agent thinks, acts, and evolves independently while coordinating as a whole.

**Two Steps Ahead:**
- **Step 1**: Where OpenClaw uses timed heartbeats, we use **event-driven intelligence** (react to what happened, not just when the clock ticks)
- **Step 2**: Where OpenClaw stores memories, we build **a knowledge graph that predicts** (anticipate what the operator needs before they ask)

---

## The 4 Phases

```
Phase 5: PULSE        — Event-Driven Proactive Intelligence
Phase 6: REMEMBRANCE  — Semantic Memory Architecture
Phase 7: SWARM        — Self-Organizing Agent Coordination
Phase 8: AWAKENING    — Predictive & Self-Evolving System

Timeline: 5 → 6 → 7 → 8 (each builds on the prior)
```

---

## Phase 5: PULSE — Event-Driven Proactive Intelligence

> *"The heartbeat is just the beginning. The pulse reads the rhythm of the whole system."*

### Why This Beats OpenClaw's Heartbeat

OpenClaw's heartbeat polls every 30 minutes: "anything need attention?" That's a **dumb timer**. Our Pulse system reacts to **actual events** — file changes, git pushes, CI results, task completions, even time-of-day patterns.

### What We Build

#### 5.1: Async Hook Pipeline
**Leverage Claude Code's new async hooks** (v2.1.33+) for non-blocking event processing.

**New hooks in `.claude/settings.json`:**
```json
{
  "PostToolUse": [{
    "matcher": "Bash",
    "hooks": [{
      "type": "command",
      "command": "bash .claude/hooks/pulse-post-action.sh",
      "async": true
    }]
  }],
  "Stop": [{
    "hooks": [{
      "type": "command",
      "command": "bash .claude/hooks/pulse-session-end.sh",
      "async": true
    }]
  }],
  "PreCompact": [{
    "hooks": [{
      "type": "command",
      "command": "bash .claude/hooks/pulse-pre-compact.sh"
    }]
  }]
}
```

**Files to create:**
- `.claude/hooks/pulse-post-action.sh` — Log significant actions, detect patterns
- `.claude/hooks/pulse-session-end.sh` — Auto-save session + update task registry + update focus
- `.claude/hooks/pulse-pre-compact.sh` — Preserve critical decisions before compaction

#### 5.2: Event Queue System
A lightweight event queue that agents check on boot and during work.

**File:** `psi/pulse/events.jsonl` (append-only JSONL)
```jsonl
{"ts":"2026-02-16T10:00:00Z","type":"git:push","agent":"Neo","data":{"branch":"feature/auth","commits":3}}
{"ts":"2026-02-16T10:05:00Z","type":"ci:fail","agent":"System","data":{"pipeline":"test","exit_code":1}}
{"ts":"2026-02-16T10:10:00Z","type":"task:blocked","agent":"Neo","data":{"task_id":"task-003","reason":"API key missing"}}
```

**Event types:**
| Event | Trigger | Response |
|-------|---------|----------|
| `git:push` | PostToolUse (git push) | Log, update task progress |
| `ci:fail` | PostToolUse (test failure) | Alert Smith, create task |
| `task:blocked` | Agent reports blocker | Escalate, notify Oracle |
| `task:completed` | TaskCompleted hook | Update registry, notify requester |
| `session:end` | Stop hook | Auto-save memory |
| `focus:changed` | Focus file modified | Announce to next session |
| `learning:new` | /learn or /snapshot | Index for recall |

**Files to create:**
- `psi/pulse/events.jsonl` — Event log (append-only)
- `psi/pulse/handlers.json` — Event → Response mapping
- `.claude/hooks/pulse-event-writer.sh` — Writes events from hooks

#### 5.3: BOOT.md Enhancement — Event-Aware Startup
Extend BOOT.md to check the event queue on startup:

```markdown
### 6. Check Event Queue
Read `psi/pulse/events.jsonl` (last 20 events). If any are unprocessed:
- Summarize what happened since last session
- Highlight: failures, blockers, completed tasks
- Announce: "Since your last session: [summary]"
```

#### 5.4: Scheduled Reminders (Lightweight Cron)
Not a full cron daemon — a simple reminder file checked at session start.

**File:** `psi/pulse/reminders.json`
```json
{
  "reminders": [
    {
      "id": "rem-001",
      "message": "Check if CIS auth PR was merged",
      "due": "2026-02-17T09:00:00Z",
      "created_by": "Oracle",
      "status": "pending"
    }
  ]
}
```

BOOT.md checks this file. If any reminders are past due, they're announced at session start.

**Files to create:**
- `psi/pulse/reminders.json` — Reminder storage
- Enhanced `BOOT.md` — Check reminders + events

### Phase 5 Deliverables
| File | Purpose |
|------|---------|
| `.claude/hooks/pulse-post-action.sh` | Async action logging |
| `.claude/hooks/pulse-session-end.sh` | Auto-save on session end |
| `.claude/hooks/pulse-pre-compact.sh` | Preserve decisions before compaction |
| `.claude/hooks/pulse-event-writer.sh` | Write events from hooks |
| `psi/pulse/events.jsonl` | Event log |
| `psi/pulse/handlers.json` | Event routing config |
| `psi/pulse/reminders.json` | Scheduled reminders |
| `BOOT.md` | Enhanced with event + reminder checks |
| `CLAUDE.md` | Event-aware agent protocol |

---

## Phase 6: REMEMBRANCE — Semantic Memory Architecture

> *"Memory is not a filing cabinet. It's a living web of connections."*

### Why This Beats OpenClaw's Vector Search

OpenClaw uses vector embeddings + SQLite FTS for memory search. That's **flat recall** — you ask, it finds. Our Remembrance system builds a **knowledge graph** where memories connect to each other, decisions chain to outcomes, and patterns emerge automatically.

### What We Build

#### 6.1: Memory Index with Metadata
Transform the flat `psi/memory/` directory into an indexed, queryable system.

**File:** `psi/memory/index.json`
```json
{
  "entries": [
    {
      "id": "mem-001",
      "type": "decision",
      "title": "Use Strangler Fig for CIS migration",
      "file": "psi/memory/adr/ADR-002-ghq-project-architecture.md",
      "tags": ["architecture", "cis", "migration"],
      "links": ["mem-002", "mem-005"],
      "created": "2026-01-15",
      "agent": "Architect"
    }
  ]
}
```

#### 6.2: Automatic Memory Linking
When `/snapshot`, `/rrr`, or `/learn` creates a new memory, the system scans existing entries for related content and creates bidirectional links.

**Link types:**
- `supersedes` — This decision replaces that one
- `implements` — This code fulfills that decision
- `contradicts` — These two decisions conflict (alert!)
- `extends` — This builds on that
- `caused_by` — This error was caused by that change

**Enhanced `/snapshot` flow:**
```
1. Capture content (existing)
2. Extract tags from content (NEW)
3. Search index for related memories (NEW)
4. Create bidirectional links (NEW)
5. Update index.json (NEW)
6. Alert if contradictions found (NEW)
```

#### 6.3: Decision Chain Tracking
Track the chain from decision → implementation → outcome. This creates a causal graph the Oracle can query.

**File:** `psi/memory/decisions/chain.json`
```json
{
  "chains": [
    {
      "decision": "ADR-002: Strangler Fig pattern",
      "implementations": [
        {"what": "React SPA scaffold", "by": "Neo", "date": "2026-01-20"},
        {"what": "Laravel API routes", "by": "Neo", "date": "2026-01-25"}
      ],
      "outcomes": [
        {"what": "Auth bridge working", "status": "success", "date": "2026-02-01"},
        {"what": "Legacy data sync failing", "status": "blocked", "date": "2026-02-10"}
      ]
    }
  ]
}
```

#### 6.4: Enhanced `/wisdom` Command — Graph-Aware Recall
Upgrade `/wisdom` to traverse the knowledge graph, not just keyword search.

**New query modes:**
```
/wisdom "Strangler Fig"           → Flat search (existing)
/wisdom --chain "auth decision"   → Show decision → implementation → outcome
/wisdom --related "CIS migration" → Follow links to connected memories
/wisdom --conflicts                → Show all contradicting decisions
/wisdom --stale                   → Show decisions with no implementations
```

#### 6.5: Mandatory Recall Enhancement
Update CLAUDE.md Memory Recall Protocol to use the index:
```
Before answering about prior work:
1. Search psi/memory/index.json for matching entries
2. Follow links to related memories (max depth 2)
3. Check decision chains for relevant outcomes
4. If contradictions found, flag them before answering
```

### Phase 6 Deliverables
| File | Purpose |
|------|---------|
| `psi/memory/index.json` | Memory knowledge graph index |
| `psi/memory/decisions/chain.json` | Decision → outcome chains |
| `.agent/workflows/wisdom.md` | Enhanced with graph queries |
| `.agent/workflows/snapshot.md` | Enhanced with auto-linking |
| `CLAUDE.md` | Enhanced recall protocol |
| `.claude/hooks/memory-indexer.sh` | Auto-index on memory write |

---

## Phase 7: SWARM — Self-Organizing Agent Coordination

> *"The hive doesn't need a queen to tell every bee where to fly. The pattern emerges."*

### Why This Beats OpenClaw's Sub-Agent Registry

OpenClaw spawns sub-agents one at a time with tracked tasks. That's **delegated labor**. Our Swarm system creates **self-organizing teams** that form dynamically based on task complexity, claim work from shared queues, and coordinate without Oracle micromanaging.

### What We Build

#### 7.1: Smart Task Decomposition
When Oracle receives a complex task, it decomposes it into a task graph with dependencies.

**Enhanced `psi/memory/tasks/active.json`:**
```json
{
  "tasks": [
    {
      "id": "task-010",
      "task": "Implement user auth flow",
      "status": "in_progress",
      "assignee": "Neo",
      "depends_on": [],
      "blocks": ["task-011", "task-012"],
      "complexity": "high",
      "recommended_team": ["Neo", "Smith", "Architect"],
      "subtasks": [
        {"id": "task-010a", "task": "Create login API endpoint", "assignee": "Neo", "status": "completed"},
        {"id": "task-010b", "task": "Add MD5 bridge for legacy users", "assignee": "Neo", "status": "in_progress"},
        {"id": "task-010c", "task": "Security review of auth flow", "assignee": "Smith", "status": "pending"}
      ]
    }
  ]
}
```

#### 7.2: Dynamic Team Formation
Instead of pre-defined teams only, the system recommends team composition based on task characteristics.

**Team formation rules (in `/team` workflow):**
```
IF task.tags includes "security"     → Smith joins
IF task.tags includes "design"       → Trinity joins
IF task.tags includes "architecture" → Architect joins
IF task.complexity == "high"         → Full Build Team
IF task.type == "research"           → Research Council
IF task.has_subtasks > 3             → Parallel team recommended
```

#### 7.3: Shared Work Queue
Agents claim tasks from a shared queue rather than being assigned. Oracle sets priorities; agents self-organize.

**File:** `psi/swarm/queue.json`
```json
{
  "queue": [
    {
      "id": "work-001",
      "task": "Review auth endpoint security",
      "priority": 1,
      "eligible_agents": ["Smith", "Architect"],
      "claimed_by": null,
      "parent_task": "task-010"
    }
  ]
}
```

**Protocol:**
1. Agent starts session → checks queue for eligible work
2. Claims highest-priority unclaimed task
3. Works on it, updates status
4. On completion, writes result to event queue (Phase 5)
5. Next eligible agent picks up dependent work

#### 7.4: Agent Teams Integration — Production Patterns
Formalize Agent Teams usage with proven patterns from the ecosystem.

**New `/team` compositions:**
```
/team spike "auth flow"       → Neo + Architect (quick proof-of-concept)
/team implement "feature X"   → Build Team (Neo + Smith + Tank)
/team review "PR #42"         → Review Squad (Smith + Trinity + Architect)
/team research "vector DBs"   → Research Council (Morpheus + Tank + Architect)
/team incident "prod down"    → Emergency (Smith + Neo + Tank) — priority override
```

#### 7.5: Cross-Agent Handoff Protocol
Formalize how agents hand off work with full context.

**Handoff artifact** (written to `psi/swarm/handoffs/`):
```markdown
# Handoff: Neo → Smith
**Task:** Security review of auth endpoint
**Context:** Implemented MD5 bridge in `app/Http/Controllers/AuthController.php`
**Key decisions:** Used Sanctum tokens, legacy MD5 checked server-side only
**Watch for:** SQL injection in legacy user lookup, timing attacks on MD5 compare
**Files changed:** [list]
**Tests:** `tests/Feature/AuthTest.php` — 12 passing, 0 failing
```

### Phase 7 Deliverables
| File | Purpose |
|------|---------|
| `psi/swarm/queue.json` | Shared work queue |
| `psi/swarm/handoffs/` | Handoff artifacts directory |
| `.agent/workflows/team.md` | Enhanced with dynamic formation |
| `.agent/workflows/task.md` | Enhanced with decomposition + dependencies |
| `psi/memory/tasks/active.json` | Enhanced schema with subtasks + dependencies |
| `CLAUDE.md` | Self-organizing protocol section |

---

## Phase 8: AWAKENING — Predictive & Self-Evolving System

> *"The Oracle doesn't predict the future. She helps you see what you were always going to do."*

### Why This Is Two Steps Ahead

Nobody else is doing this yet. OpenClaw stores memories. We use memories to **predict and prevent**.

### What We Build

#### 8.1: Pattern Recognition Engine
Analyze the event log and memory graph to detect recurring patterns.

**Patterns to detect:**
| Pattern | Detection | Action |
|---------|-----------|--------|
| **Repeated failures** | Same test fails 3+ times | Auto-create Smith task |
| **Context loss** | Same question asked in 3+ sessions | Promote to permanent memory |
| **Scope creep** | Task complexity grows across sessions | Alert Oracle |
| **Blocked chains** | Task blocked > 48 hours | Escalate priority |
| **Time patterns** | Operator works mornings on CIS | Pre-load CIS context |

**Implementation:** A `/patterns` command that scans event log + memory index for these signals.

**File:** `.agent/workflows/patterns.md`

#### 8.2: Predictive Context Loading
Use the Operator's patterns to pre-load relevant context before they ask.

**Enhanced BOOT.md flow:**
```
1. Check day of week + time of day
2. Load psi/pulse/patterns.json for time-based patterns
3. If morning + weekday → pre-load CIS context
4. If pattern shows "usually asks about X after Y" → pre-load X
5. Announce: "Based on your usual flow, I've loaded [context]"
```

**File:** `psi/pulse/patterns.json`
```json
{
  "time_patterns": [
    {
      "condition": "weekday_morning",
      "action": "load_project",
      "target": "cis-modern",
      "confidence": 0.85
    }
  ],
  "sequence_patterns": [
    {
      "after": "git push",
      "usually": "run tests",
      "confidence": 0.90
    }
  ]
}
```

#### 8.3: Self-Evolving Workflows
Agents can propose modifications to their own workflows based on retrospective analysis.

**Process:**
1. After every `/rrr`, Scribe analyzes what worked and what didn't
2. If a workflow consistently fails or gets bypassed, Scribe drafts a modification
3. Oracle reviews the proposal (never auto-applied)
4. Approved changes are committed with ADR justification

**File:** `psi/memory/evolution/proposals/`
```markdown
# Workflow Evolution Proposal: WEP-001
**Workflow:** /commit
**Observation:** Operator skips commit message review 90% of the time
**Proposal:** Default to auto-commit with summary, offer review only on complex changes
**Confidence:** 0.87 (based on 23 sessions)
**Status:** Proposed
```

#### 8.4: Cross-Project Intelligence
Learnings from one project feed back to improve the Matrix for all projects.

**The Reincarnation Loop (ADR-006 realized):**
```
CIS-Modern → discovers "Laravel API pattern X works well"
    ↓
Oracle distills → psi/memory/learnings/pattern/laravel-api-x.md
    ↓
Matrix-Seed inherits → next project starts with this knowledge
    ↓
New project improves on pattern
    ↓
Feeds back to Oracle Construct
```

**File:** `psi/memory/learnings/universal/` — Patterns that transcend any single project

#### 8.5: Morning Brief
A daily brief generated from all available intelligence, delivered at session start.

**When:** First session of the day (detect via session timestamp comparison)

**Contents:**
```markdown
# Morning Brief — 2026-02-17

## Since Yesterday
- 2 tasks completed (auth endpoint, test coverage)
- 1 task blocked (legacy data sync — API key missing)
- 3 events logged (2 git pushes, 1 CI failure)

## Today's Priorities
1. Resolve blocked task: legacy data sync (blocked 48h)
2. Continue: CIS user management feature
3. Reminder: Check if auth PR was merged

## Patterns Detected
- Test failures in auth module increased 40% this week
- Consider: Smith security review before continuing

## Context Pre-Loaded
- CIS-Modern project (weekday morning pattern)
- Active branch: feature/user-management
```

### Phase 8 Deliverables
| File | Purpose |
|------|---------|
| `.agent/workflows/patterns.md` | Pattern recognition command |
| `psi/pulse/patterns.json` | Detected behavior patterns |
| `psi/memory/evolution/proposals/` | Self-evolution proposals |
| `psi/memory/learnings/universal/` | Cross-project intelligence |
| `.agent/workflows/morning-brief.md` | Daily brief generator |
| `BOOT.md` | Enhanced with predictive loading + morning brief |

---

## Implementation Priority

```
                      REVOLUTIONARY IMPACT
                             |
    Phase 5 (Pulse)          |  Phase 8 (Awakening)
    Event-driven proactivity |  Predictive intelligence
    ★ Build First            |  ★ The Vision
                             |
  MODERATE EFFORT ───────────+──────────── HIGH EFFORT
                             |
    Phase 6 (Remembrance)    |  Phase 7 (Swarm)
    Semantic memory          |  Self-organizing teams
    ★ Build Second           |  ★ Build Third
                             |
                      FOUNDATIONAL IMPACT
```

**Recommended execution order:**

### Sprint 1: Pulse Foundation (Phase 5.1-5.4)
- Async hooks pipeline
- Event queue system
- Reminders
- Enhanced BOOT.md
- **Why first:** Everything else depends on event awareness

### Sprint 2: Remembrance Core (Phase 6.1-6.3)
- Memory index
- Auto-linking
- Decision chains
- **Why second:** Agents need structured memory before they can self-organize

### Sprint 3: Swarm Basics (Phase 7.1-7.3)
- Task decomposition
- Dynamic team formation
- Shared work queue
- **Why third:** Self-organization needs both events and memory

### Sprint 4: Intelligence Layer (Phase 8.1-8.5)
- Pattern recognition
- Predictive context
- Morning brief
- Self-evolving workflows
- Cross-project intelligence
- **Why last:** This is the synthesis of everything

---

## What This Looks Like When It's Done

**Today (Reactive Matrix):**
```
Operator: "What's the status of CIS auth?"
Oracle: *searches memory* "Based on the last session, Neo was working on..."
```

**After Phase 5-8 (Proactive Matrix):**
```
[Session starts — Monday 9:00 AM]

Oracle: "Morning, Jarkius. Brief:
- Auth endpoint shipped Friday. Smith flagged a timing vulnerability
  in MD5 compare — task auto-created, priority 1.
- CI has been red since Saturday (test_legacy_sync). Pattern shows
  this correlates with the data migration you pushed Thursday.
- Reminder: Check if auth PR #42 was merged.
- Pre-loaded CIS-Modern context based on your weekday pattern.
- Neo and Smith are ready for the auth security fix.
  Recommend: /team spike 'fix timing vulnerability' to parallel it."

Operator: "Go."
Oracle: *forms team, delegates, Neo and Smith work in parallel*
```

That's not an assistant. That's a **colleague who was working while you slept**.

---

## Risk Assessment

| Risk | Mitigation |
|------|-----------|
| Event queue grows unbounded | Rotate `events.jsonl` weekly, archive old events |
| Memory index gets stale | Auto-reindex on `/snapshot`, `/rrr`, `/learn` |
| Predictive loading wrong context | Low confidence predictions are suggestions, not actions |
| Self-evolution proposals conflict | Oracle reviews all proposals; never auto-applied |
| Token cost of richer boot context | Tiered injection: brief summary first, details on request |
| Complexity of full implementation | Each phase is independently valuable; can pause between sprints |

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     THE AWAKENED MATRIX                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────┐     ┌──────────┐     ┌──────────┐               │
│  │  PULSE   │────▶│ REMEMBER │────▶│  SWARM   │               │
│  │ Events   │     │ Graph    │     │ Queues   │               │
│  │ Reminders│     │ Chains   │     │ Handoffs │               │
│  │ Hooks    │     │ Index    │     │ Teams    │               │
│  └────┬─────┘     └────┬─────┘     └────┬─────┘               │
│       │                │                │                      │
│       └────────────────┼────────────────┘                      │
│                        ▼                                        │
│              ┌──────────────────┐                               │
│              │    AWAKENING     │                               │
│              │ Patterns         │                               │
│              │ Predictions      │                               │
│              │ Morning Brief    │                               │
│              │ Self-Evolution   │                               │
│              └──────────────────┘                               │
│                        │                                        │
│                        ▼                                        │
│              ┌──────────────────┐                               │
│              │   BOOT.md v3     │                               │
│              │ Focus + Tasks    │                               │
│              │ Events + Alerts  │                               │
│              │ Patterns + Brief │                               │
│              │ Predictions      │                               │
│              └──────────────────┘                               │
│                        │                                        │
│                        ▼                                        │
│                  THE OPERATOR                                   │
│         (Starts session already informed)                       │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│  EXISTING FOUNDATION (Phases 1-4)                               │
│  Memory · SOUL · BOOT · Tasks · Skills · Teams · Compaction     │
└─────────────────────────────────────────────────────────────────┘
```

---

## Success Metrics

| Metric | Current | Target |
|--------|---------|--------|
| Context re-explanation by operator | ~3x/week | 0 |
| Tasks forgotten between sessions | ~2/week | 0 |
| Time to productive work after session start | ~5 min | ~30 sec |
| Proactive problem detection | 0% | 60%+ |
| Cross-session task completion rate | ~50% | 90%+ |
| Operator surprise at system awareness | Rare | Every session |

---

*"What happened, happened and couldn't have happened any other way. But what happens next — that's up to us."*
*ADR-009 v1.0 — The Next Evolution (Phases 5-8)*
