# Multi-Agent Protocol

> *"A swarm is not a group of individuals — it is individuals who know how to talk to each other."*

## Agent Spawning Decision Tree

```
"I need work done"
│
├─ Is it a single, independent task?
│  YES ──► SUBAGENT (Agent tool)
│          ├─ Will it edit files?
│          │  YES ──► Add isolation: "worktree"
│          │  NO  ──► Run in main context (research, search)
│          └─ Done. Result comes back via tool output.
│
├─ Do multiple agents need to coordinate?
│  YES ──► AGENT TEAM (2-5 teammates)
│          ├─ Will they edit code?
│          │  YES ──► Each teammate gets worktree isolation
│          │         ├─ Do they touch the SAME files?
│          │         │  YES ──► STOP. Serialize instead.
│          │         │  NO  ──► Assign file ownership per agent.
│          │         └─ Merge sequentially when done.
│          │  NO  ──► No worktree needed (review, research)
│          └─ Oracle leads. Teammates report via messaging.
│
└─ Is it a bulk codebase-wide change?
   YES ──► /batch (Claude Code native)
           ├─ Auto-creates one worktree per unit
           └─ Best for: migrations, renames, bulk refactors
```

## Definitions

| Term | What It Is | When To Use |
|------|-----------|-------------|
| **Subagent** | Single Claude instance, fire-and-forget, returns result to parent | Focused independent tasks: research, review, file generation |
| **Agent Team** | 2-5 persistent instances, peer messaging, shared task list | Collaborative work: multi-angle review, coordinated feature build |
| **Worktree Agent** | Any agent with `isolation: "worktree"` — own branch + filesystem | Code-producing work that could conflict with other agents |

These are **composable layers**, not separate modes:
- Subagent + no isolation = Quick research task
- Subagent + worktree = Independent feature implementation
- Team member + no isolation = Collaborative review (read-only)
- Team member + worktree = Parallel feature build with coordination

## Anti-Patterns

| DON'T | WHY | DO THIS INSTEAD |
|-------|-----|-----------------|
| Spawn 6+ parallel agents | Coordination cost exceeds benefit | Max 5 agents. Usually 3 is optimal. |
| Parallel agents editing same file | Guaranteed merge conflict | Serialize: Agent 1 finishes, Agent 2 starts |
| Worktree without merge plan | Branches pile up, conflicts cascade | Define merge order BEFORE spawning agents |
| Subagent without clear output format | Parent can't parse result | Define expected output structure in spawn prompt |

## Coordination Layer

All cross-worktree coordination happens at `~/.matrix/coordination/` — a fixed path outside any git repo.

### Handshake Protocol

**File**: `~/.matrix/coordination/handshake.json`

The handshake is the single source of truth for parallel work:

```json
{
  "sessionId": "session-YYYYMMDD-HHMMSS",
  "orchestrator": "Oracle",
  "plan": {
    "description": "What we're building",
    "decomposition": [
      {
        "taskId": "task-1",
        "assignee": "Neo (agent-3)",
        "scope": ["src/auth/**"],
        "branch": "agent-3/feature-auth",
        "status": "working",
        "depends_on": []
      }
    ],
    "mergeOrder": ["task-1", "task-2"],
    "sharedReadOnly": ["CLAUDE.md", "SOUL.md", "psi/source/**"]
  }
}
```

**Lifecycle:**
1. **PLAN** — Orchestrator writes handshake.json with scope assignments
2. **SPAWN** — Each agent reads handshake to know its boundaries
3. **WORK** — Agents update status files; read handshake for context
4. **SYNC** — Orchestrator updates handshake when dependencies resolve
5. **MERGE** — Follow mergeOrder for sequential merging
6. **CLEANUP** — Archive handshake, clear coordination dir

### Agent Status

Each agent writes: `~/.matrix/coordination/agents/{agent-id}.status.json`

```json
{
  "agentId": "agent-3",
  "name": "Neo",
  "worktree": "/path/to/.worktrees/agent-3",
  "branch": "agent-3/feature-auth",
  "status": "working",
  "currentTask": "Implement JWT refresh",
  "progress": 0.6,
  "filesOwned": ["src/auth/jwt.ts"],
  "lastUpdate": "2026-03-18T10:15:00Z"
}
```

### File Locking

Before editing any file, agents must claim a lock:

`~/.matrix/coordination/locks/{sha256-of-path}.lock`

```json
{
  "path": "src/auth/jwt.ts",
  "owner": "agent-3",
  "claimedAt": "2026-03-18T10:00:00Z",
  "expiresAt": "2026-03-18T11:00:00Z"
}
```

**Rules:**
- Check before write (enforced by source-guard hook)
- One owner per file
- Auto-expire after 1 hour
- Released on task completion

### Messages

Individual JSON files at `~/.matrix/coordination/messages/{timestamp}-{from}-{to}.json`:

```json
{
  "from": "agent-3",
  "to": "orchestrator",
  "type": "completion",
  "subject": "JWT refresh complete",
  "body": "12 tests pass. Ready for merge.",
  "timestamp": "2026-03-18T10:15:00Z"
}
```

### Merge Sequencing

Always merge sequentially:
1. Sort finished agents by completion time
2. Merge first branch into main
3. Rebase next branch onto updated main → merge
4. Repeat until all merged
5. If conflict: mark as needs-manual-resolution, skip to next

## Architecture Layers

```
Layer 0: IDENTITY    (SOUL.md, BOOT.md, USER.md, psi/source/)
Layer 1: STATE       (psi/state/, psi/memory/, ~/.matrix/coordination/)
Layer 2: SERVICES    (lib/matrix-memory-agents/src/)
Layer 3: AUTOMATION  (.claude/hooks/, .agent/workflows/)
Layer 4: EXTENSIONS  (mcp/, .claude/agents/, skills)
```

**Rule**: Dependencies point DOWN only. Layer 2 never imports from Layer 3.

## Implementation References

| Component | Source File |
|-----------|------------|
| Lock Manager | `lib/matrix-memory-agents/src/coordination/lock-manager.ts` |
| Coordinator | `lib/matrix-memory-agents/src/coordination/coordinator.ts` |
| Status Writer | `lib/matrix-memory-agents/src/coordination/status-writer.ts` |
| Message Bus | `lib/matrix-memory-agents/src/coordination/message-bus.ts` |
| Merge Queue | `lib/matrix-memory-agents/src/coordination/merge-queue.ts` |
| Permission Resolver | `lib/matrix-memory-agents/src/security/permission-resolver.ts` |
| Enforcement Engine | `lib/matrix-memory-agents/src/security/enforcement-engine.ts` |
| Elevation Manager | `lib/matrix-memory-agents/src/security/elevation.ts` |
| Lock Check Hook | `.claude/hooks/core/matrix-lock-check.sh` |
| Permission Gate Hook | `.claude/hooks/core/matrix-permission-gate.sh` |
| Source Guard Hook | `.claude/hooks/core/matrix-source-guard.sh` |

### CLI Tools

```bash
bun run scripts/coordination/start-session.ts --agents 3 --task "Build feature X"
bun run scripts/coordination/monitor-session.ts
bun run scripts/coordination/end-session.ts [--force]
bun run scripts/security/audit-permissions.ts
bun run scripts/security/wep-audit.ts
```

### Hook Chain (PreToolUse)

```
Edit|Write:
  1. matrix-permission-gate.sh  → Does this AGENT have permission for this TOOL?
  2. matrix-lock-check.sh       → Does this AGENT own the LOCK for this FILE?
  3. matrix-source-guard.sh     → Is this FILE in the SACRED psi/source/ directory?

Bash:
  1. matrix-permission-gate.sh  → Does this AGENT have Bash permission?
  2. matrix-source-bash-guard.sh → Is this command manipulating sacred files?
```

---

*Multi-Agent Protocol v2.0 — 2026-03-20*
