# Memory System Fix Plan — 3 Surgical Fixes

> *"Don't build Phase 18. Fix what's broken."*

**Date**: 2026-02-21
**Priority**: CRITICAL — blocks all real project work
**Estimated effort**: ~30 minutes total

---

## Fix 1: Recall Fallback (10 min)

**Problem**: `bun memory recall "query"` crashes when ChromaDB is down. No try/catch around `initVectorDB()`. FTS exists but is unreachable.

**File**: `lib/matrix-memory-agents/src/services/recall-service.ts`

**Fix**:
```typescript
// Line 630-632: wrap initVectorDB in try/catch, fall back to FTS-only
if (!isInitialized()) {
  try {
    await initVectorDB();
  } catch (e) {
    console.log('[Recall] Vector DB unavailable, using FTS-only mode');
    // Continue — hybridSearchLearnings will use FTS when vector fails
  }
}
```

**Also fix**: `hybridSearchLearnings()` must handle the case where vector search throws. Return FTS results only when ChromaDB is down.

**Test**: `bun memory recall "authentication MD5"` should return FTS results instead of crashing.

**Impact**: Recall becomes functional. Keyword search works. "Search before you speak" protocol becomes possible.

---

## Fix 2: Stop Hook Reliability (5 min)

**Problem**: Stop hook is `async: true` — SQLite save races against session exit. Errors masked by `2>/dev/null || true`.

**File**: `.claude/settings.json` line 44

**Fix**:
```json
// Change async to false (or remove the key)
{
  "type": "command",
  "command": "bash \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/pulse-session-end.sh",
  "timeout": 10000
}
```

**Also fix**: In `pulse-session-end.sh`, replace `2>/dev/null || true` with proper error logging:
```bash
# Line 90: Log errors instead of hiding them
bun memory save "Auto-saved session via pulse hook" 2>>"$PROJECT_ROOT/psi/pulse/memory-errors.log" || echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] bun memory save failed" >> "$PROJECT_ROOT/psi/pulse/memory-errors.log"
```

**Test**: End a session, check that `agents.db` has a new session record AND `memory-errors.log` captures any failures.

**Impact**: Every session reliably persists to SQLite. Failures become visible.

---

## Fix 3: Purge Garbage Learnings + Backfill Real Data (15 min)

**Problem**: 119 "learnings" are all `"Auto-captured by session-memory-save hook"` — zero insight, pollute search.

**Fix (3 steps)**:

### Step 3a: Purge fake learnings
```bash
cd lib/matrix-memory-agents
# Delete all auto-captured garbage from SQLite
bun run -e "
import { getDb } from './src/db/index.ts';
const db = getDb();
const result = db.run(\"DELETE FROM learnings WHERE title LIKE '%Auto-captured%'\");
console.log('Deleted', result.changes, 'garbage learnings');
"
```

### Step 3b: Backfill real retrospectives into SQLite
```bash
# Ingest the 71 real retrospectives (these have actual insights)
for file in psi/memory/retrospectives/**/*.md; do
  bun memory learn "$file" 2>&1 | tail -1
done
```

### Step 3c: Backfill real learnings into SQLite
```bash
# Ingest the 46 curated learnings
for file in psi/memory/learnings/**/*.md; do
  bun memory learn "$file" 2>&1 | tail -1
done
```

**Test**: `bun memory list learnings` should show real titles, not "Auto-captured". `bun memory recall "authentication"` (after Fix 1) should find the auth blueprint.

**Impact**: Search returns real knowledge. FTS can match meaningful content.

---

## What This Does NOT Fix (Deferred)

| Issue | Why Deferred |
|-------|-------------|
| ChromaDB semantic search | Docker not available in this env. FTS fallback is sufficient for now. |
| LLM-powered distillation | Needs API key + design work. Manual learnings are fine. |
| Task ↔ Learning linking | Schema exists. Will populate as real CIS tasks are created. |
| Proactive recall at boot | Fix 1 enables it. Wire into BOOT.md after fixes land. |

---

## Verification Checklist

After all 3 fixes:

- [ ] `bun memory recall "authentication MD5"` → returns results (not crash)
- [ ] `bun memory recall "CIS modernization"` → returns results
- [ ] `bun memory list learnings` → shows real titles (not "Auto-captured")
- [ ] End a session → `agents.db` has new record (check timestamp)
- [ ] `psi/pulse/memory-errors.log` exists (may be empty if no errors)
- [ ] Stop hook runs synchronously (session waits for save to complete)

---

## After Verification: Wire Recall Into Boot

Once these 3 fixes land, update `BOOT.md` step 3:

```bash
# Primary: FTS recall (works without ChromaDB)
cd lib/matrix-memory-agents
FOCUS=$(cat psi/inbox/focus.md | head -5)
bun memory recall "$FOCUS" 2>/dev/null | head -20
```

This makes the morning brief automatically surface past work related to today's focus. Not semantic search, but keyword FTS against real learnings — far better than nothing.

---

*"Fix the filing cabinet before building the library." — 2026-02-21*
