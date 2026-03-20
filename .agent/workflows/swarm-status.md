---
name: swarm-status
description: Show real-time status of all coordinating agents, file locks, merge queue, and recent messages
agent: oracle-keeper
user_invocable: true
---

# /swarm-status — Agent Coordination Dashboard

Read the coordination state from `~/.matrix/coordination/` and display a summary.

## Steps

1. Read all agent status files from `~/.matrix/coordination/agents/*.status.json`
2. Read all lock files from `~/.matrix/coordination/locks/*.lock`
3. Read the handshake session from `~/.matrix/coordination/handshake.json` (if exists)
4. Read recent messages from `~/.matrix/coordination/messages/` (last 5)
5. Display in this format:

```
SESSION: {description} [{phase}]
  Started: {startedAt}  |  Tasks: {n}/{total} complete

ACTIVE AGENTS:
  {name} ({agentId})  {STATUS}  "{currentTask}"  [{progress bar}] {progress}%  branch: {branch}

FILE LOCKS:
  {path}  → {owner}  expires: {remaining}

MERGE QUEUE:
  1. {branch} → main  ({status})

MESSAGES (last 5):
  [{time}] {from} → {to}: {subject}
```

6. If no coordination session is active, display: "No active coordination session. Use /coordinate to start one."

## Notes
- Progress bar: use block characters to show 0-100%
- Expired locks should be noted as "(EXPIRED)"
- Sort agents by status: working > blocked > idle > complete
