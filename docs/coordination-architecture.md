# Coordination Architecture

Cross-worktree coordination system for safe parallel agent work (Phases 4-7, ADR-019).

## Why External Coordination

Git worktrees are fully isolated copies of the repository. Agents working in separate worktrees share no runtime state -- no shared memory, no IPC, no WebSocket within the same project. The only reliable cross-process primitive is file I/O at a shared external location.

All coordination state lives at `~/.matrix/coordination/`, outside any git worktree.

## Directory Layout

```
~/.matrix/coordination/
  handshake.json          # Session plan (orchestrator writes, agents read)
  agents/                 # Per-agent status files
    agent-1.status.json
    agent-2.status.json
  messages/               # Individual JSON message files
    {id}.msg.json
  locks/                  # SHA256-hashed lock files
    {hash}.lock
  results/                # Completed work metadata
  elevation/              # Permission elevation requests/grants
  logs/                   # Coordination event logs
```

## Handshake Protocol

The orchestrator (Oracle) writes `handshake.json` before spawning agents. Each agent reads it to learn its scope.

| Phase | Actor | Action |
|-------|-------|--------|
| `planning` | Orchestrator | Writes handshake with scope assignments and merge order |
| `spawning` | Orchestrator | Provisions worktrees, agents start reading handshake |
| `working` | Agents | Work within their assigned scope, update status files |
| `merging` | Coordinator | Sequential merge following `mergeOrder` |
| `complete` | Orchestrator | Archives handshake, clears coordination dir |

### Handshake Structure

```json
{
  "sessionId": "session-20260318-100000",
  "orchestrator": "Oracle",
  "phase": "working",
  "plan": {
    "description": "Implement auth module",
    "decomposition": [
      {
        "taskId": "task-1",
        "assignee": "Neo (agent-3)",
        "scope": ["src/auth/**"],
        "branch": "agent-3/feature-auth",
        "dependsOn": []
      }
    ],
    "mergeOrder": ["task-1", "task-2"],
    "sharedReadOnly": ["src/config/**"]
  }
}
```

## File Locking

Agents must claim a lock before editing any file. Locks are advisory, enforced by the `matrix-lock-check.sh` hook.

| Property | Value |
|----------|-------|
| Storage | `~/.matrix/coordination/locks/{sha256}.lock` |
| Format | Individual JSON files per lock |
| Atomicity | Exclusive write flag (`wx`) for race-safe creation |
| Expiry | 1 hour (configurable via `lockExpiryMs`) |
| Re-entrant | Same owner can re-acquire their own lock |
| Directory prefix | Locking `src/auth/` also covers `src/auth/jwt.ts` |

## Status Writer

Each agent writes its current state to `agents/{agent-id}.status.json`. The orchestrator and other agents poll these files for visibility.

```json
{
  "agentId": "agent-3",
  "name": "Neo",
  "worktree": "/path/to/worktree",
  "branch": "agent-3/feature-auth",
  "status": "working",
  "currentTask": "Implement JWT validation",
  "progress": 0.6,
  "filesOwned": ["src/auth/jwt.ts"],
  "lastUpdate": "2026-03-18T10:30:00Z"
}
```

Agent statuses: `starting` | `idle` | `working` | `blocked` | `complete` | `error`

## Message Bus

File-based messaging using individual JSON files per message. No JSONL, no shared append -- eliminates all concurrency issues.

| Field | Description |
|-------|-------------|
| `from` | Agent ID or `"orchestrator"` |
| `to` | Agent ID, `"orchestrator"`, or `"all"` |
| `type` | `completion` / `discovery` / `request` / `broadcast` / `dependency-resolved` / `blocker` |
| TTL | 1 hour (configurable via `messageTtlMs`) |

## Merge Queue

Sequential merging following the handshake `mergeOrder`. After each successful merge, remaining branches are rebased onto the updated base.

```
Agent 1 completes -> merge to main -> rebase agent-2, agent-3
Agent 2 completes -> merge to main -> rebase agent-3
Agent 3 completes -> merge to main -> done
```

On conflict: skip the conflicting branch, notify orchestrator, continue with next.

## Hook Chain

Pre-tool-use hooks enforce coordination rules:

| Hook | Purpose |
|------|---------|
| `permission-gate` | Check agent's permission mode before tool use |
| `lock-check` | Verify file lock ownership before writes |
| `source-guard` | Protect sacred files (CLAUDE.md, SOUL.md, etc.) |

## CLI Tools

```bash
bun run scripts/coordination/start-session.ts       # Initialize handshake + worktrees
bun run scripts/coordination/monitor-session.ts      # Watch agent status in real-time
bun run scripts/coordination/end-session.ts          # Trigger merge queue + cleanup
bun run scripts/coordination/release-agent-locks.ts  # Force-release locks for an agent
```

## Key Source Files

| File | Purpose |
|------|---------|
| `src/coordination/types.ts` | All coordination type definitions |
| `src/coordination/coordinator.ts` | Session lifecycle and handshake management |
| `src/coordination/lock-manager.ts` | File locking with SHA256 keys |
| `src/coordination/message-bus.ts` | File-based cross-worktree messaging |
| `src/coordination/status-writer.ts` | Per-agent status file management |
| `src/coordination/merge-queue.ts` | Sequential merge with rebase |
| `src/pty/worktree-manager.ts` | Git worktree provisioning |
| `scripts/coordination/` | CLI tools for session management |
