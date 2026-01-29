# 🏛️ Permanent Context Retention via Behavioral Logging Schema

> **Category**: architecture
> **Confidence**: medium
> **Created**: 2026-01-28
> **Source**: Agent Orchestra (matrix-memory-agents)

## Content

Database schema pattern that treats user behavior as data just as important as content itself.

**Two-Layer Structure:**

1. **Static Layer (Content Archive)**
   - `oracle_documents` - Permanent storage for all content
   - `oracle_fts` - FTS5 full-text search index
   - Maps to "HISTORY" via retrospectives/ directory
   - Ensures narrative context survives session boundaries

2. **Behavioral Layer (Interaction Logging)**
   Four dedicated logging tables preserve situational context:
   - `search_log` - Records queries (preserves user intent)
   - `consult_log` - Logs guidance sought during decisions
   - `learn_log` - Tracks pattern formation (thought evolution)
   - `document_access` - Which documents were viewed (intellectual trail)

**Philosophy: "Nothing is Deleted"**
- Content + Context = True Memory (not temporary cache)
- Behavioral data enables:
  - Query analytics (what do people search for most?)
  - Decision audit trails
  - Learning evolution tracking
  - Document relevance scoring via access patterns

**Implementation Notes:**
- Use triggers or middleware to log automatically
- Include timestamps for temporal analysis
- Consider TTL for logs vs. permanent retention for decisions




---

*Synced from Agent Orchestra SQLite on 2026-01-29T18:07:43.084Z*
*Learning ID: 383*
