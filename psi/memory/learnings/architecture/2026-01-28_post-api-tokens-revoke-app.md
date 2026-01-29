# 🏛️ // POST /api/tokens/revoke
app.

> **Category**: architecture
> **Confidence**: low
> **Created**: 2026-01-28
> **Source**: Agent Orchestra (matrix-memory-agents)

## Content

// POST /api/tokens/revoke
app.

**What happened:** Extracted from /Users/jarkius/ghq/github.com/Jarkius/matrix-memory-agents/docs/AUDIT-2026-01-28.md (section: 2.3 Token Revocation Endpoint)

**Lesson:** // POST /api/tokens/revoke
app.post('/api/tokens/revoke', (req, res) => {
  const { token } = req.body;
  revokedTokens.add(token);
  res.json({ success: true });
});


## Source

file:///Users/jarkius/ghq/github.com/Jarkius/matrix-memory-agents/docs/AUDIT-2026-01-28.md#L168


---

*Synced from Agent Orchestra SQLite on 2026-01-29T18:07:43.086Z*
*Learning ID: 253*
