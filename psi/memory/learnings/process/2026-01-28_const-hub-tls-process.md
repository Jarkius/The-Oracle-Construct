# 📋 const HUB_TLS = process.

> **Category**: process
> **Confidence**: low
> **Created**: 2026-01-28
> **Source**: Agent Orchestra (matrix-memory-agents)

## Content

const HUB_TLS = process.

**What happened:** Extracted from /Users/jarkius/ghq/github.com/Jarkius/matrix-memory-agents/docs/AUDIT-2026-01-28.md (section: 2.2 Enable TLS for Matrix Hub)

**Lesson:** const HUB_TLS = process.env.MATRIX_HUB_TLS === 'true';
const HUB_CERT = process.env.MATRIX_HUB_CERT;
const HUB_KEY = process.env.MATRIX_HUB_KEY;

// Use wss:// when TLS enabled


## Source

file:///Users/jarkius/ghq/github.com/Jarkius/matrix-memory-agents/docs/AUDIT-2026-01-28.md#L156


---

*Synced from Agent Orchestra SQLite on 2026-01-29T18:07:43.087Z*
*Learning ID: 252*
