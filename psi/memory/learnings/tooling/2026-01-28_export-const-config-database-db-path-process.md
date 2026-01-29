# 🔧 export const CONFIG = {
  // Database
  DB_PATH: process.

> **Category**: tooling
> **Confidence**: low
> **Created**: 2026-01-28
> **Source**: Agent Orchestra (matrix-memory-agents)

## Content

export const CONFIG = {
  // Database
  DB_PATH: process.

**What happened:** Extracted from /Users/jarkius/ghq/github.com/Jarkius/matrix-memory-agents/docs/AUDIT-2026-01-28.md (section: 4.1 Create Central Config)

**Lesson:** export const CONFIG = {
  // Database
  DB_PATH: process.env.AGENTS_DB || './agents.db',
  DB_LOCK_TIMEOUT: 30_000,

  // ChromaDB
  CHROMA_URL: process.env.CHROMA_URL || 'http://localhost:8100',
  CHROMA_TIMEOUT: 5_000,
  CHROMA_CIRCUIT_THRESHOLD: 3,

  // WebSocket
  WS_PORT: parseInt(process.env.WS_PORT || '8080'),
  WS_TOKEN_EXPIRY: 24 * 60 * 60 * 1000, // 24 hours

  // Matrix Hub
  HUB_PORT: parseInt(process.env.MATRIX_HUB_PORT || '8081'),
  HUB_HOST: process.env.MATRIX_HUB_HOST || 'localhost',

  // Embedding
  EMBEDDING_PROVIDER: process.env.EMBEDDING_PROVIDER || 'transformers',
  EMBEDDING_MODEL: process.env.EMBEDDING_MODEL || 'bge-m3',

  // Daemon
  DAEMON_PORT_RANGE: [37900, 38899],
} as const;


## Source

file:///Users/jarkius/ghq/github.com/Jarkius/matrix-memory-agents/docs/AUDIT-2026-01-28.md#L224


---

*Synced from Agent Orchestra SQLite on 2026-01-29T18:07:43.086Z*
*Learning ID: 259*
