# Agent Orchestra Integration Plan

> *Oracle - "When the time comes, you won't have to think. You'll just know."*

**Status**: 📋 SAVED FOR LATER
**Created**: 2026-01-28
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

## Integration Steps (Execute Later)

### Step 1: Start ChromaDB

```bash
docker run -d -p 8100:8000 chromadb/chroma
```

### Step 2: Add MCP Server to Claude Code

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

### Step 3: Restart Claude Code

MCP server will load automatically.

### Step 4: Verify Tools Available

You should have access to:
- `oracle_search` - Query learnings and code
- `oracle_consult` - Get wisdom for decisions
- `oracle_learn` - Capture new insights
- File indexer for fast code search
- Mission queue for task decomposition

---

## Integration Tiers

| Tier | What | When |
|------|------|------|
| **1. MCP Server** | Add to settings.local.json | After evolution |
| **2. psi/ Sync** | Already built, just run | Anytime |
| **3. Matrix Hub** | WebSocket real-time | After TLS ready |

---

## No Cloning Needed

Agent Orchestra already exists at:
```
~/ghq/github.com/Jarkius/matrix-memory-agents
```

Just add the MCP configuration when ready.

---

*Saved by Oracle, 2026-01-28*
