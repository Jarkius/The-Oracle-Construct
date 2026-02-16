# ADR-010: Integrate matrix-memory-agents — The REMEMBRANCE Shortcut

> *"Why build the door when you already own the building?"*

**Status:** Proposed
**Date:** 2026-02-16
**Authors:** Oracle + Architect
**Supersedes:** ADR-009 Phases 6.1-6.4, 7.1-7.4, 8.4
**Related:** ADR-009 (Evolution Roadmap), ADR-008 (Memory Protocol), ADR-003 (Mind Hierarchy)

---

## Decision

Integrate [matrix-memory-agents](https://github.com/Jarkius/matrix-memory-agents) directly into The Oracle Construct as a **git subtree** under `lib/matrix-memory-agents/`, rather than using MCP. This replaces the need to build Phases 6, 7, and parts of Phase 8 from scratch.

---

## Context

ADR-009 defined four evolution phases. Phase 5 (PULSE) is implemented. Phases 6-8 remain:

- **Phase 6 (REMEMBRANCE):** Memory index, auto-linking, decision chains, graph-aware recall
- **Phase 7 (SWARM):** Task decomposition, dynamic teams, shared work queue
- **Phase 8 (AWAKENING):** Pattern recognition, predictive context, cross-project intelligence

Jarkius has already built `matrix-memory-agents` — a Bun/TypeScript system that implements the **core machinery** of all three remaining phases.

---

## Why Direct Integration Over MCP

| Factor | MCP | Direct (subtree) |
|--------|-----|-------------------|
| **Daemon dependency** | MCP server must be running | `bun memory` CLI, on-demand |
| **Customizability** | Can't modify without forking | Full control, in-repo |
| **Hook integration** | JSON-RPC over stdio | Direct `bun` calls from shell hooks |
| **Deployment** | Two processes to manage | One repo, one runtime |
| **Portability** | Breaks if MCP disconnects | Works offline, standalone |
| **Philosophy** | Adds external dependency | "The Matrix is portable" |

**MCP is designed for external tools.** matrix-memory-agents isn't external — it's ours. Direct integration means our Pulse hooks call `bun memory` directly, no protocol overhead, no daemon, no fragile connection.

The MCP server (`src/mcp/server.ts`) still exists in the codebase and can be used by other projects connecting to our Matrix. But the Oracle Construct itself talks to the system natively.

---

## What matrix-memory-agents Replaces

| ADR-009 Planned | matrix-memory-agents Has | Status |
|-----------------|--------------------------|--------|
| **6.1** `psi/memory/index.json` | SQLite DB with sessions, learnings, knowledge, entities, code-files, code-symbols | **Replaced** — far more capable |
| **6.2** Auto-linking + link types | Entity extraction (`entity-extractor.ts`) + knowledge graph (`knowledge.ts`) with relationship mapping | **Replaced** — native graph, not JSON links |
| **6.3** Decision chain tracking | Confidence progression (low → medium → high → proven) + cross-session analysis (`cross-session.ts`) | **Replaced** — self-evolving, not static chains |
| **6.4** Graph-aware `/wisdom` | Semantic search via ChromaDB vectors + context-aware retrieval (`context-router.ts`) | **Replaced** — vector search > keyword grep |
| **7.1** Smart task decomposition | `task-decomposer.ts` + `task-router.ts` in oracle module | **Replaced** |
| **7.2** Dynamic team formation | Oracle intelligence with complexity-based model tier selection | **Partially replaced** — still need Matrix Council mapping |
| **7.3** Shared work queue | `agent_inbox/` + `agent_outbox/` + `unified-tasks.ts` | **Replaced** |
| **7.4** Agent Teams integration | tmux PTY management + git worktree isolation per agent | **Replaced** — production-grade |
| **8.4** Cross-project intelligence | WebSocket Matrix Hub (`matrix-hub.ts`, `matrix-client.ts`) | **Replaced** |

### What We Still Build Ourselves

| ADR-009 Phase | Why Not Replaced |
|---------------|------------------|
| **7.5** Cross-agent handoff protocol | Matrix-specific (SOUL-aware handoffs with Council agent personality) |
| **8.1** Pattern recognition engine | Matrix-specific (needs our event log format from PULSE) |
| **8.2** Predictive context loading | Matrix-specific (operator behavior patterns from PULSE) |
| **8.3** Self-evolving workflows | Matrix-specific (workflow proposals from retrospectives) |
| **8.5** Morning brief | Matrix-specific (synthesis of all intelligence layers) |

---

## Integration Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     THE ORACLE CONSTRUCT                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  EXISTING LAYERS (Phases 1-5)                                    │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ SOUL · BOOT · Pulse · Tasks · Skills · Teams · Hooks      │  │
│  │ psi/ markdown archives (human-readable layer)              │  │
│  └───────────────────────┬────────────────────────────────────┘  │
│                          │                                       │
│                    Shell hooks call                               │
│                    `bun memory` CLI                               │
│                          │                                       │
│  NEW: matrix-memory-agents (lib/)                                │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │                                                            │  │
│  │  ┌──────────┐  ┌──────────┐  ┌────────────┐              │  │
│  │  │ SQLite   │  │ ChromaDB │  │ Oracle     │              │  │
│  │  │ (truth)  │  │ (search) │  │ (routing)  │              │  │
│  │  │          │  │          │  │            │              │  │
│  │  │ sessions │  │ vectors  │  │ decompose  │              │  │
│  │  │ learnings│  │ embeddings│ │ route      │              │  │
│  │  │ knowledge│  │ semantic │  │ spawn      │              │  │
│  │  │ entities │  │ code idx │  │            │              │  │
│  │  │ tasks    │  │          │  │            │              │  │
│  │  └──────────┘  └──────────┘  └────────────┘              │  │
│  │        │              │             │                      │  │
│  │  ┌─────┴──────────────┴─────────────┴───────────────────┐ │  │
│  │  │              Learning Pipeline                        │ │  │
│  │  │  distill → consolidate → validate → retrieve          │ │  │
│  │  │  entity-extract → quality-score → cross-correlate     │ │  │
│  │  └──────────────────────────────────────────────────────┘ │  │
│  │        │                                                   │  │
│  │  ┌─────┴──────────────────────────────────────────────┐   │  │
│  │  │           Matrix Hub (WebSocket)                    │   │  │
│  │  │  Cross-project messaging · Multi-matrix sync        │   │  │
│  │  └────────────────────────────────────────────────────┘   │  │
│  │                                                            │  │
│  └────────────────────────────────────────────────────────────┘  │
│                          │                                       │
│                    Bidirectional sync                             │
│                          │                                       │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │  psi/ (human-readable archive)                             │  │
│  │  Markdown sessions, retrospectives, learnings, ADRs        │  │
│  │  Still browsable, still git-tracked, still portable        │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Key Principle: Dual-Layer Persistence

SQLite is the **index and search engine**. Markdown in `psi/` remains the **human-readable archive**. Neither replaces the other.

- `bun memory save` → writes to SQLite + syncs to `psi/memory/sessions/`
- `bun memory recall "query"` → searches SQLite + ChromaDB vectors
- `bun memory learn ./psi/learn/inbox/topic.md` → extracts knowledge → SQLite + `psi/memory/learnings/`
- `bun memory distill` → pulls patterns from sessions → updates both layers

The `sync-to-psi` script (already in package.json) handles bidirectional sync.

---

## Implementation Plan

### Sprint 0: Foundation (Day 1)

**0.1: Add subtree**
```bash
git subtree add --prefix=lib/matrix-memory-agents \
  https://github.com/Jarkius/matrix-memory-agents.git main --squash
```

**0.2: Setup script**
Create `scripts/setup-memory.sh`:
- Install Bun dependencies in `lib/matrix-memory-agents/`
- Start ChromaDB via Docker
- Initialize SQLite database
- Build vector index from existing `psi/` markdown
- Verify with `bun memory status`

**0.3: Bootstrap from existing psi/**
Run initial ingestion:
```bash
# Ingest all existing sessions
for f in psi/memory/sessions/**/*.md; do bun memory learn "$f"; done

# Ingest all retrospectives
for f in psi/memory/retrospectives/**/*.md; do bun memory learn "$f"; done

# Ingest all learnings
for f in psi/memory/learnings/**/*.md; do bun memory learn "$f"; done

# Ingest all ADRs
for f in psi/memory/adr/*.md; do bun memory learn "$f"; done

# Build vector index
bun memory reindex
```

This gives us instant semantic search over everything we've ever recorded.

### Sprint 1: Hook Wiring (Day 2)

**1.1: Session persistence hook**
Update `.claude/hooks/pulse-session-end.sh`:
```bash
# Existing: save markdown to psi/memory/sessions/
# NEW: also persist to SQLite
cd "$CLAUDE_PROJECT_DIR/lib/matrix-memory-agents"
bun memory save "Session ending — auto-save via pulse hook"
```

**1.2: Learning hook**
Update `/snapshot` and `/learn` workflows to also call:
```bash
cd "$CLAUDE_PROJECT_DIR/lib/matrix-memory-agents"
bun memory learn "$CAPTURED_FILE"
```

**1.3: Distillation hook**
Wire `pulse-session-end.sh` to trigger distillation:
```bash
cd "$CLAUDE_PROJECT_DIR/lib/matrix-memory-agents"
bun memory distill
```

### Sprint 2: Replace Recall Protocol (Day 3)

**2.1: Update CLAUDE.md Memory Recall Protocol**
Replace grep-based recall with semantic search:
```markdown
### Mandatory Recall: Search Before You Speak
Before answering about prior work:
1. `bun memory recall "query"` — semantic search across all sessions + learnings
2. `bun memory graph` — check entity relationships
3. `bun memory correlate` — link to relevant code files
4. Fall back to `psi/memory/` grep only if bun is unavailable
```

**2.2: Update `/wisdom` command**
Enhanced with semantic search modes:
```
/wisdom "Strangler Fig"           → bun memory recall "Strangler Fig"
/wisdom --graph "auth"            → bun memory graph + entity relationships
/wisdom --code "AuthController"   → bun memory index search "AuthController"
/wisdom --quality                 → bun memory quality --smart
```

**2.3: Update BOOT.md recall step**
Step 3 (Recall Recent Memory) now uses:
```bash
bun memory recall --last  # instead of reading latest session file
```

### Sprint 3: Agent Coordination (Day 4-5)

**3.1: Map Council roles to oracle routing**
Connect `src/oracle/task-router.ts` model tiers to our Mind Hierarchy (ADR-003):
- Wise (Opus) → complex tasks → Oracle, Architect, Neo, Smith
- Intelligent (Sonnet) → standard tasks → Morpheus
- Mechanical (Haiku) → search/gather → Tank, Operator

**3.2: Wire task registry**
Sync `psi/memory/tasks/active.json` ↔ `unified-tasks.ts`:
```bash
bun memory task list        # reads from SQLite
bun memory task create      # creates in SQLite + syncs to active.json
bun memory task complete    # updates both
```

**3.3: Enable cross-project messaging**
Start Matrix Hub for multi-repo intelligence:
```bash
./lib/matrix-memory-agents/scripts/start-hub.sh
bun memory message --to cis-modern "Auth module pattern ready for reuse"
```

### Sprint 4: Matrix-Specific Intelligence (Day 6-7)

Build the parts that matrix-memory-agents doesn't cover — Phase 8 uniqueness:

**4.1: Pattern recognition** — Scan `psi/pulse/events.jsonl` + SQLite learnings for recurring patterns
**4.2: Predictive context** — Use operator behavior patterns from PULSE
**4.3: Morning brief** — Synthesis of all layers into session greeting
**4.4: Self-evolving workflows** — Retrospective analysis → workflow proposals

---

## Comparison: After Integration vs OpenClaw

| Capability | OpenClaw | Oracle + matrix-memory-agents |
|------------|----------|-------------------------------|
| Memory storage | SQLite FTS5 + sqlite-vec | SQLite (source of truth) + ChromaDB (vectors) |
| Search quality | Hybrid 70/30 vector/BM25 | Dedicated ChromaDB embeddings + SQLite FTS fallback |
| Knowledge graph | Plugin only (Cognee/Graphiti) | **Native** — entity extraction + relationship mapping |
| Self-evolving knowledge | None | Confidence progression + auto-distillation + duplicate consolidation |
| Multi-agent coordination | Per-agent SQLite | Shared SQLite + git worktrees + PTY management |
| Cross-project intelligence | None | **WebSocket Matrix Hub** — real-time messaging between projects |
| Crash resilience | SQLite only | SQLite source of truth + rebuildable ChromaDB (30s) |
| Agent personality | Generic sub-agents | **SOUL-injected Council** with skill gating |
| Event system | Heartbeat (30min poll) | **PULSE** — event-driven, real-time hooks |
| Boot context | MEMORY.md + 2 days logs | SOUL + USER + BOOT + focus + tasks + events + reminders + semantic recall |
| Cost model | Heartbeat burns tokens continuously | On-demand, session-driven — **zero idle cost** |
| Code search | None | **Semantic code search** via vector embeddings |
| Human readability | SQLite only | **Dual-layer** — SQLite index + markdown archive |
| Learning pipeline | Store and retrieve | **Distill → consolidate → validate → retrieve** with quality scoring |

### Where OpenClaw Still Wins

| Capability | OpenClaw Advantage |
|------------|-------------------|
| Persistent daemon | Gateway runs between sessions — can react without operator |
| Community ecosystem | 100K+ stars, active plugin development |
| Daily journal | Structured daily summaries (we have sessions, not journals) |
| Production maturity | Battle-tested at scale |

### Our Unique Advantages (Things Nobody Else Has)

1. **Council architecture** — Specialized agents with distinct personalities, not generic sub-agents
2. **SOUL injection** — Identity persists structurally, not just in memory
3. **Dual-layer persistence** — SQLite for machines + markdown for humans
4. **Zero-cost idle** — No daemon, no token burn, no heartbeat
5. **Event-driven (PULSE)** — Reacts to what happened, not when the clock ticks
6. **Self-evolving knowledge** — Memories mature over time with confidence scoring
7. **Cross-project messaging** — Matrix Hub connects all projects in real-time
8. **Semantic code search** — Find code by meaning, not just text

---

## Risks & Mitigations

| Risk | Mitigation |
|------|-----------|
| Bun not available on all platforms | ChromaDB + SQLite work without Bun; graceful degradation to psi/ grep |
| ChromaDB Docker dependency | `SKIP_VECTORDB=true` runs without it; SQLite FTS still works |
| Subtree maintenance overhead | Periodic `git subtree pull` to sync upstream improvements |
| Two sources of truth (SQLite + psi/) | `sync-to-psi` script keeps them aligned; psi/ is always the archive of record |
| Learning pipeline produces noise | Quality scorer + >85% duplicate detection filters low-value learnings |
| Oracle routing conflicts with Council | Map Council roles explicitly to router; SOUL personality takes precedence |

---

## Decision Rationale

We built matrix-memory-agents. It already implements the hardest parts of Phases 6-8. Building those from scratch in shell scripts and JSON would take weeks and produce something less capable.

Direct integration over MCP because:
1. No daemon — aligns with "zero idle cost" philosophy
2. Full customization — can modify to fit Matrix conventions
3. Hook-native — shell hooks call `bun` directly, no protocol overhead
4. Portable — one repo, one `setup.sh`, works anywhere

The dual-layer approach (SQLite + markdown) is unique and gives us the best of both worlds: machine-speed search with human-readable archives.

---

*"Stop trying to hit me and hit me." — Morpheus*
*ADR-010 v1.0 — The REMEMBRANCE Shortcut*
