# 🏛️ Hybrid Search Architecture - SQLite FTS5 + ChromaDB Vectors

> **Category**: architecture
> **Confidence**: proven
> **Created**: 2026-01-28
> **Source**: Agent Orchestra (matrix-memory-agents)

## Content

Our system implements a dual-index hybrid search architecture:

**Dual Storage:**
- SQLite FTS5 (`learnings_fts` table) - Fast exact keyword matching
- ChromaDB - Semantic vector embeddings for conceptual search

**Query-Aware Routing (src/indexer/hybrid-search.ts):**
- Short queries → Prioritize FTS5 (looking for specific terms)
- Long/complex queries → Prioritize ChromaDB (conceptual search)
- Configurable via `VECTOR_WEIGHT` env var (default 0.7)

**Graceful Degradation:**
- Circuit breaker in vector-db.ts falls back to 100% FTS if ChromaDB fails
- Ensures memory remains accessible even with partial system failure

**Key Files:**
- `src/indexer/hybrid-search.ts` - Query routing logic
- `src/services/recall-service.ts` - hybridSearchLearnings()
- `src/db/core.ts:775` - FTS5 virtual table creation
- `src/config.ts` - vectorWeight/keywordWeight settings

**Future Improvements:**
- Add search_log table for query analytics
- Track document access frequency for popularity boosting
- Auto-tune weights based on search-validation.ts recommendations




---

*Synced from Agent Orchestra SQLite on 2026-01-29T18:07:34.371Z*
*Learning ID: 380*
