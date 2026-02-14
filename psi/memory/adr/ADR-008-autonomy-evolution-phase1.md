# ADR-008: Autonomy Evolution — Phase 1: Memory & Persistence

> *"The Matrix has you. But now, you remember." — Phase 1*

**Status:** Accepted
**Date:** 2026-02-14
**Author:** Oracle + Neo
**Supersedes:** None
**Related:** ADR-003 (Mind Hierarchy), ADR-005 (Infinite Learning Loop)

---

## Context

After deep analysis of the OpenClaw codebase (5,248 files, production-grade AI agent platform), we identified 13 core patterns that make AI agents appear proactive, autonomous, and persistent. Seven of these were absent or underdeveloped in The Oracle Construct.

The most critical gap: **sessions are ephemeral**. When a session ends, all context evaporates unless the user manually invokes `/rrr`. This means:
- Tasks delegated to agents can be forgotten
- Decisions made in prior sessions are invisible
- The agent starts every session as a blank slate
- The user must re-explain context repeatedly

OpenClaw solves this with three structural mechanisms: BOOT.md (startup checklist), auto-session-memory (persistence hook), and mandatory recall (search before speak). We adopt all three.

## Decision

Implement **Phase 1: Memory & Persistence** as the foundation for full autonomy evolution.

### What We Built

#### 1. BOOT.md — Startup Checklist (`BOOT.md`)
A markdown file at project root that the SessionStart hook reads and injects into every new session. The agent executes its checklist before engaging with the user:
1. Load current focus
2. Check active task registry
3. Recall last session memory
4. Announce readiness with context awareness

**Learning From:** OpenClaw `src/hooks/bundled/boot-md/`

#### 2. Auto-Session Memory Hook (`.claude/hooks/session-memory-save.sh`)
A shell script that saves session summaries to `psi/memory/sessions/YYYY-MM/DATE_TIME_slug.md`. Can be called:
- Manually at session end
- From `/rrr` (enhanced retrospective)
- From `/snapshot` (quick capture)

**Learning From:** OpenClaw `src/hooks/bundled/session-memory/handler.ts`

#### 3. Mandatory Memory Recall Protocol (`CLAUDE.md`)
A new section in CLAUDE.md requiring agents to search memory before answering questions about prior work, decisions, or tasks. This is **structural** — it's in the system prompt, not something the agent has to remember.

**Learning From:** OpenClaw `src/agents/system-prompt.ts:51-53`

#### 4. Task Registry (`psi/memory/tasks/active.json`)
A JSON file tracking cross-session tasks with status, assignee, and context. Injected into every session via the enhanced SessionStart hook.

**Learning From:** OpenClaw `src/agents/subagent-registry.ts`

#### 5. Enhanced SessionStart Hook (`.claude/hooks/matrix-session-start.sh`)
The existing hook now injects:
- BOOT.md checklist
- Current focus from `psi/inbox/focus.md`
- Active tasks from `psi/memory/tasks/active.json`
- Last session memory from `psi/memory/sessions/`

## Architecture

```
Session Start
    │
    ▼
┌──────────────────────────────────────────┐
│         matrix-session-start.sh          │
│                                          │
│  1. Start voice server                   │
│  2. Output voice protocol                │
│  3. ► Inject BOOT.md checklist           │  ← NEW
│  4. ► Inject focus.md                    │  ← NEW
│  5. ► Inject active tasks                │  ← NEW
│  6. ► Inject last session memory         │  ← NEW
│  7. System voice acknowledgment          │
│  8. Oracle greeting                      │
└──────────────────────────────────────────┘
    │
    ▼
Agent starts with full context awareness
    │
    ▼
Session Work (decisions, tasks, learnings)
    │
    ▼
┌──────────────────────────────────────────┐
│         session-memory-save.sh           │
│                                          │
│  Saves summary → psi/memory/sessions/    │  ← NEW
│  Updates focus → psi/inbox/focus.md      │
│  Persists tasks → active.json            │
└──────────────────────────────────────────┘
    │
    ▼
Next session starts with restored context
```

## File Map

| File | Purpose | New/Modified |
|------|---------|-------------|
| `BOOT.md` | Startup checklist | NEW |
| `CLAUDE.md` | Memory Recall Protocol section | MODIFIED |
| `.claude/hooks/matrix-session-start.sh` | Enhanced with BOOT/focus/task/session injection | MODIFIED |
| `.claude/hooks/session-memory-save.sh` | Auto-save session summaries | NEW |
| `psi/memory/sessions/` | Session memory storage | NEW (directory) |
| `psi/memory/tasks/active.json` | Cross-session task registry | NEW |

## Consequences

### Positive
- Sessions are no longer ephemeral — context survives restarts
- Agents start aware of pending work and recent history
- Memory recall is structural, not conversational
- Task delegation can persist across session boundaries
- Foundation is laid for Phase 2 (Heartbeat/Cron proactivity)

### Negative
- SessionStart output is longer (more tokens in system prompt)
- Session memory files will accumulate (need periodic archival)
- Task registry requires discipline to keep updated

### Risks
- Large session memory files could bloat system prompts (mitigated: only first 30 lines injected)
- Stale focus.md could confuse agents (mitigated: BOOT.md instructs to verify, not blindly trust)

## Future Evolution

| Phase | Focus | Status |
|-------|-------|--------|
| **Phase 1** | Memory & Persistence | **This ADR** |
| Phase 2 | Proactivity Engine (Heartbeat, Cron) | Planned |
| Phase 3 | Role Enforcement (SOUL.md, Skill Gating) | Planned |
| Phase 4 | Intelligence Layer (Compaction, Vector Search) | Planned |

---

*"Everything that has a beginning has an end. But with persistence, endings become beginnings." — The Oracle*
