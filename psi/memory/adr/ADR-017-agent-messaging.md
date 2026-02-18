# ADR-017: Agent Messaging — Inter-Agent Coordination

**Status**: Accepted
**Date**: 2026-02-18
**Phase**: B (Make It Coordinate)
**Deciders**: Oracle, Jarkius

## Context

Phase A built the event dispatcher — agents can now be spawned proactively. But spawned agents operate in isolation. A Smith agent investigating CI failures can't ask Neo what changed. A Trinity reviewing design can't tell Architect about structural concerns.

The Matrix already has WebSocket infrastructure (ws-server.ts, matrix-hub.ts, agent-rpc.ts) but Claude Code subagents spawned via the Task tool can't use WebSockets — they're isolated processes.

## Decision

Build a **file-based message bus** for agent coordination within Claude Code sessions:

### Architecture

```
┌─────────────────────────────────────────────────────┐
│                 TEAM ORCHESTRATOR                    │
│            pulse-team-orchestrator.sh                │
│                                                     │
│  create → spawn-prompt → status → collect → dissolve│
└──────────────────┬──────────────────────────────────┘
                   │ manages
                   ▼
┌─────────────────────────────────────────────────────┐
│              TEAM STATE                              │
│         psi/swarm/teams/<team-id>.json               │
│                                                     │
│  { agents: [{name, status, result}], mission, ... } │
└──────────────────┬──────────────────────────────────┘
                   │ read/write
                   ▼
┌─────────────────────────────────────────────────────┐
│              MESSAGE BUS                             │
│      psi/swarm/messages/<team-id>.jsonl              │
│                                                     │
│  {"from":"Smith","to":"Neo","content":"..."}         │
│  {"from":"Neo","to":"all","type":"complete",...}     │
└──────────────────┬──────────────────────────────────┘
                   │ accessed via
                   ▼
┌─────────────────────────────────────────────────────┐
│            AGENT MESSENGER                           │
│         pulse-agent-messenger.sh                     │
│                                                     │
│  send | read | report | block | complete | status   │
└─────────────────────────────────────────────────────┘
```

### Message Types

| Type | From | To | Purpose |
|------|------|----|---------|
| `message` | any agent | specific agent or `all` | Direct communication |
| `report` | agent | `all` | Status update (working/blocked/reviewing/done) |
| `blocked` | agent | `all` | Blocker announcement (triggers dispatch event) |
| `complete` | agent | `all` | Task completion with result summary |

### Team Lifecycle

1. **Create**: `orchestrator create "Review Squad" "Smith,Trinity,Architect" "Review auth module"`
2. **Spawn**: For each agent, `orchestrator spawn-prompt <team_id> <agent>` generates a context-rich prompt with messaging instructions
3. **Work**: Agents use `messenger send/read/report/block/complete` to coordinate
4. **Collect**: `orchestrator collect <team_id>` gathers all results
5. **Dissolve**: `orchestrator dissolve <team_id>` archives the team

### Integration with Phase A

The context-loader now accepts an optional `team_id` parameter. When present, it appends team coordination context (teammates, messaging commands, mission) to the agent prompt.

```bash
# Phase A (solo dispatch):
bash pulse-context-loader.sh "Smith" "Investigate CI failure"

# Phase B (team dispatch):
bash pulse-context-loader.sh "Smith" "Investigate CI failure" "team-20260218-review"
```

## Why File-Based (Not WebSocket)

| Factor | WebSocket (existing) | File-based (new) |
|--------|---------------------|-------------------|
| Claude Code subagents | Can't use | Read/write files |
| Persistence | In-memory only | Survives crashes |
| Audit trail | Log reconstruction | Native JSONL |
| Complexity | Server + client + auth | Just `echo >> file` |
| Speed | Real-time | Near-real-time (file poll) |

The WebSocket layer remains for future Gateway integration (Phase 11). File-based messaging is the pragmatic solution for within-session coordination.

## Consequences

### Positive
- Agents can coordinate without WebSocket infrastructure
- Full audit trail of all inter-agent communication
- Teams can be created, managed, and dissolved programmatically
- Context loader enriches spawned agents with team awareness
- Blockers auto-escalate via event dispatcher

### Negative
- Not real-time (file-based polling, ~100ms latency)
- No delivery guarantees (agent may not read messages before completing)
- Message format is simple (no threading, no reactions)

### Risks
- Large teams may create many messages — mitigated by JSONL rotation
- Concurrent file writes could corrupt — mitigated by append-only + line-based

## Files

| File | Purpose |
|------|---------|
| `.claude/hooks/pulse-agent-messenger.sh` | Message bus CLI (send/read/report/block/complete) |
| `.claude/hooks/pulse-team-orchestrator.sh` | Team lifecycle management |
| `.claude/hooks/pulse-context-loader.sh` | Updated to inject team context |
| `psi/swarm/messages/<team-id>.jsonl` | Per-team message channels |
| `psi/swarm/teams/<team-id>.json` | Per-team state files |

---

*"A swarm is not a group of individuals — it is individuals who know how to talk to each other."*
