---
description: Spawn parallel agents via Agent Orchestra
---

# /orchestra - Parallel Agent Orchestration

> *Oracle - "The One becomes many. Each with purpose."*

## Purpose

Spawn and coordinate multiple Claude agents in parallel using **Agent Orchestra**. Each agent runs in isolated tmux panes with dedicated git worktrees.

## Usage

- `/orchestra status` - Show running agents and queue
- `/orchestra spawn 3` - Spawn 3 generalist agents
- `/orchestra spawn coder tester` - Spawn specific roles
- `/orchestra task "description"` - Add task to queue
- `/orchestra stop` - Stop all agents gracefully

## Prerequisites

Agent Orchestra must be running:
```bash
cd ~/workspace/matrix-memory-agents
bun memory status      # Check health
bun memory init        # Start services if needed
```

## Steps

### Check Status

```bash
cd /Users/jarkius/ghq/github.com/Jarkius/matrix-memory-agents
bun memory status
```

### Spawn Agents

```bash
# Spawn by count (generalist role)
./scripts/spawn/spawn_claude_agents.sh 3

# Or via mission queue
bun memory task:create "Implement feature X" --role coder
bun memory task:create "Write tests for feature X" --role tester
```

### Monitor Agents

```bash
# View tmux sessions
tmux list-sessions | grep agent

# Attach to watch an agent
tmux attach -t agent-1
```

### Distribute Work

```bash
# Add task to queue
bun memory task:create "Your task description" --priority high

# Oracle will auto-route to optimal agent based on:
# - Task complexity (haiku → sonnet → opus)
# - Agent availability
# - Role specialization
```

## Agent Roles

| Role | Model | Best For |
|------|-------|----------|
| `coder` | sonnet | Implementation, features |
| `tester` | sonnet | Tests, coverage |
| `debugger` | sonnet | Bug investigation |
| `analyst` | sonnet | Requirements, breakdown |
| `reviewer` | sonnet | Code review |
| `oracle` | opus | Complex routing, decomposition |
| `generalist` | sonnet | General tasks |

## Worktree Isolation

Each agent works on its own git branch:
```
main
├── agent-1/work-mission-123
├── agent-2/work-mission-124
└── agent-3/work-mission-125
```

No file conflicts. Merge results back when complete.

## Integration with Matrix

The Oracle in Agent Orchestra follows the same Mind Hierarchy:
- **Opus** for complex decomposition
- **Sonnet** for execution
- **Haiku** for fast routing

Results feed back to The Matrix via:
- `/memory-sync` - Import session data
- `/rrr` - Capture retrospectives

## Example Workflow

```bash
# 1. Start Agent Orchestra
cd ~/workspace/matrix-memory-agents
bun memory init

# 2. Spawn agents
./scripts/spawn/spawn_claude_agents.sh 3

# 3. Add complex task (Oracle decomposes)
bun memory task:create "Refactor authentication system" --priority high

# 4. Monitor progress
bun memory task:list

# 5. Sync results to Matrix
bun memory sync-to-psi

# 6. Capture retrospective in Matrix
/rrr
```

## Related Commands

| Command | Purpose |
|---------|---------|
| `/memory-sync` | Sync memory between systems |
| `/neo` | Single-agent implementation (Matrix) |
| `bun memory task` | Task management (Orchestra) |
| `bun memory recall` | Search across all agents |

---

*"The One becomes many. Each with purpose."*
