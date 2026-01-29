# Agent Orchestra Integration Plan

> *Oracle - "When the time comes, you won't have to think. You'll just know."*

**Status**: 📋 SAVED FOR LATER
**Created**: 2026-01-28
**Updated**: 2026-01-29 (Architect Review - Full Capabilities)
**Execute When**: After Agent Orchestra evolution phase completes

---

## Prerequisites

**Already Done** ✅
- Agent Orchestra cloned: `~/ghq/github.com/Jarkius/matrix-memory-agents`
- Symlink exists: `~/workspace/The-matrix/psi/projects/matrix-memory-agents`
- Soul seeded with standalone operation capability
- Bidirectional sync protocol implemented

**Needs to Complete** ⏳
- Agent Orchestra evolution phase (TLS, config centralization)
- ChromaDB running (for vector search)

---

## Full Capabilities Available

| Category | Feature | Benefit to Matrix |
|----------|---------|-------------------|
| **Multi-Agent** | PTY Management | Spawn parallel Claude agents in tmux |
| **Multi-Agent** | Git Worktree Isolation | Each agent works on own branch, no conflicts |
| **Multi-Agent** | Role-Based Agents | Coder, tester, analyst, oracle, debugger |
| **Multi-Agent** | Model Tier Selection | Auto-select haiku/sonnet/opus by complexity |
| **Intelligence** | Proactive Spawning | Spawn agents before queue backs up |
| **Intelligence** | Task Decomposition | Break complex tasks into subtasks |
| **Intelligence** | Pre-Task Briefing | Patterns, pitfalls, success criteria |
| **Memory** | Session Persistence | Sessions survive across conversations |
| **Memory** | Semantic Search | Find by meaning, not keywords |
| **Memory** | Knowledge Graph | Entity extraction, relationships |
| **Memory** | Code Search | Vector-based code understanding |
| **Learning** | Confidence Tracking | Low → medium → high → proven |
| **Learning** | Consolidation | Auto-merge duplicate learnings |
| **Communication** | WebSocket | Real-time task delivery |
| **Communication** | Matrix Hub | Cross-machine multi-matrix |
| **Communication** | SSE Streaming | Live message visibility |

---

## Integration Tiers

### Tier 1: MCP Tools (Immediate)

**Effort**: Low | **Benefit**: Oracle tools in Claude Code

#### Step 1: Start ChromaDB

```bash
docker run -d -p 8100:8000 chromadb/chroma
```

#### Step 2: Add MCP Server to Claude Code

Edit `~/.claude/settings.local.json`:

```json
{
  "mcpServers": {
    "agent-orchestra": {
      "command": "bun",
      "args": ["run", "~/ghq/github.com/Jarkius/matrix-memory-agents/src/index.ts"],
      "env": {
        "MATRIX_PATH": "~/workspace/The-matrix",
        "CHROMA_URL": "http://localhost:8100"
      }
    }
  }
}
```

#### Step 3: Restart Claude Code

MCP server will load automatically.

#### Step 4: Verify Tools Available

You should have access to:
- `oracle_search` - Semantic search across learnings
- `oracle_consult` - Decision guidance synthesis
- `oracle_learn` - Capture new patterns
- `oracle_trace` - Deep-dig traceability
- `oracle_reflect` - Random wisdom (serendipity)
- `oracle_graph` - Knowledge graph queries
- File indexer for fast code location

---

### Tier 2: psi/ Sync (Already Done)

**Effort**: Done | **Benefit**: Bidirectional learning flow

The sync protocol is already implemented:
- Push local learnings (orchestra_*.md) to Matrix
- Pull Matrix learnings (matrix_*.md) to local
- Run anytime with `syncWithMatrix()`

---

### Tier 3: Multi-Agent Orchestration (Power User)

**Effort**: Medium | **Benefit**: 3-5x faster complex tasks

#### Start Agent Pool

```bash
bun run src/spawn-pool.ts --count 3 --roles coder,tester,analyst
```

#### Submit Tasks to Queue

```bash
bun run src/cli.ts task add "Implement user authentication" --priority high
```

#### Watch Agents Work

```bash
tmux attach -t matrix-agents
```

**What you get:**
- **3-5x faster** complex tasks
- **No file conflicts** (worktree isolation)
- **Auto-scaling** based on queue depth
- **Specialized agents** for different tasks

---

### Tier 4: Matrix Hub (Multi-Machine)

**Effort**: High | **Benefit**: Distributed agents across machines

#### On Main Matrix Machine

```bash
MATRIX_HUB_HOST=0.0.0.0 bun run src/matrix-hub.ts
```

#### On Other Machines

```bash
MATRIX_HUB_HOST=192.168.1.100 bun memory status
```

**What you get:**
- **Distributed agents** across machines
- **Real-time sync** of learnings
- **Cross-machine task routing**

---

### Tier 5: Self-Evolving Knowledge

**Effort**: Low | **Benefit**: Learnings improve over time

#### View Learning Confidence

```bash
bun run src/cli.ts learnings list --min-confidence high
```

#### Trigger Consolidation

```bash
bun run src/cli.ts learnings consolidate
```

**What you get:**
- **Confidence tracking**: Low → medium → high → proven
- **Duplicate detection** and merging
- **Pattern extraction** from sessions

---

## Quick Start Checklist

### After Evolution Completes

- [ ] Start ChromaDB: `docker run -d -p 8100:8000 chromadb/chroma`
- [ ] Add MCP config to `~/.claude/settings.local.json`
- [ ] Restart Claude Code
- [ ] Verify: `oracle_search("test")` works

### Power Usage

- [ ] Start agent pool: `bun run spawn-pool.ts --count 3`
- [ ] Submit complex tasks to queue
- [ ] Watch agents parallelize work

### Advanced

- [ ] Enable Matrix Hub for multi-machine
- [ ] Configure proactive spawning thresholds
- [ ] Set up automatic learning consolidation

---

## No Cloning Needed

Agent Orchestra already exists at:
```
~/ghq/github.com/Jarkius/matrix-memory-agents
```

Just add the MCP configuration when ready.

---

*"There are two doors. The door to your right leads to the Source, and the salvation of Zion."*

*Updated by Architect, 2026-01-29*
*Originally saved by Oracle, 2026-01-28*
