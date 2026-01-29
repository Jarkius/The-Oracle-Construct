# 🔄 AI-to-AI Coordination via Persistent Decisions and Consult Logging

> **Category**: pattern
> **Confidence**: medium
> **Created**: 2026-01-28
> **Source**: Agent Orchestra (matrix-memory-agents)

## Content

Pattern for maintaining consistency across AI sessions through state persistence and decision tracking.

**Current Implementation (oracle_consult):**
- `src/mcp/tools/handlers/oracle-consult.ts` - Guidance tool with question types: approach, stuck, review, escalate
- Searches learnings (semantic + FTS) for relevant context
- Finds similar successful tasks for reference
- Analyzes complexity and recommends escalation

**What We're Missing:**

1. **Decisions Table** - Persist architectural decisions separately from sessions:
   ```sql
   CREATE TABLE decisions (
     id TEXT PRIMARY KEY,
     decision TEXT NOT NULL,
     rationale TEXT,
     context TEXT,        -- What prompted this decision
     supersedes TEXT,     -- Previous decision ID if overriding
     created_at TEXT DEFAULT CURRENT_TIMESTAMP
   );
   ```
   
2. **Consult Log** - Track oracle consultations for debugging:
   ```sql
   CREATE TABLE consult_log (
     id TEXT PRIMARY KEY,
     agent_id INTEGER,
     question TEXT,
     question_type TEXT,
     guidance_given TEXT,
     created_at TEXT DEFAULT CURRENT_TIMESTAMP
   );
   ```

3. **Coordination Flow:**
   - Before major changes, AI queries `oracle_consult`
   - Tool checks `decisions` table for existing rulings
   - Prevents "current AI" from contradicting "past AI"
   - Logs consultation to `consult_log` for traceability

**Benefits:**
- Architectural consistency across sessions
- Debug complex coordination issues
- Audit trail of AI reasoning
- "The Oracle as institutional memory"




---

*Synced from Agent Orchestra SQLite on 2026-01-29T18:07:43.084Z*
*Learning ID: 382*
