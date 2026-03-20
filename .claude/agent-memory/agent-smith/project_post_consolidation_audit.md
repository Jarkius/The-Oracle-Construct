---
name: post_consolidation_audit_march_2026
description: Audit findings from src/nerve, src/mcp, src/coordination, src/security, src/skills after lib/matrix-memory-agents consolidation. 15 confirmed issues including 7 CRITICAL broken imports.
type: project
---

## Audit: Post-Consolidation State (2026-03-20)

Consolidation moved lib/matrix-memory-agents/ into root src/. Several import paths were not updated.

### CRITICAL — Broken Imports (will fail at runtime)

1. `src/mcp/tools/handlers/{agents,context,query,results,task,analytics}.ts`
   - Import `from '../../core/config'` resolves to `src/mcp/core/config` — does not exist
   - Import `from '../../core/utils/response'` resolves to `src/mcp/core/utils/response` — does not exist
   - Import `from '../../core/utils/validation'` resolves to `src/mcp/core/utils/validation` — does not exist
   - Real paths: `../../config`, `../../utils/response`, `../../utils/validation` (one level shallower)

2. `src/mcp/tools/handlers/pty.ts:414`
   - `await import('../../../interfaces/mission')` — `src/interfaces/` does not exist
   - Real path: `src/core/types/mission.ts`

3. `src/mcp/tools/handlers/learning.ts:444` and `:536`
   - `await import('../../../learning')` — `src/learning/` does not exist
   - `await import('../../../learning/consolidation')` — same
   - Real path: `src/memory/learning/index.ts` and `src/memory/learning/consolidation.ts`

4. `src/mcp/tools/handlers/learning.ts:486`
   - `await import('../../../db')` — `src/db/` does not exist at root src level
   - Real path: `src/core/db`

### HIGH — Logic Bug

5. `src/nerve/supervisor.ts:157`
   - `if (daemon.level === 0 || transition)` — `transition` is never declared in `checkDaemon()` scope
   - The return value of `stateDetector.check()` is discarded on line 142; `transition` evaluates as `undefined`
   - Escalation guard condition is broken

### HIGH — Dead Barrel Exports (within these five modules)

6. `src/security/index.ts:17-23` — `WRITE_TOOLS`, `EXEC_TOOLS`, `SPAWN_TOOLS`, `READ_TOOLS` exported but never imported in any of the five audited directories
7. `src/mcp/tools/handlers/agent-query.ts:67` — `handleRpcResponse` exported, never imported in these dirs
8. `src/skills/index.ts:12` — `SemverParts` re-exported to nowhere within these modules
9. `src/coordination/index.ts:13` — `AgentStatusRecord` dead barrel export

### MEDIUM — Stale Path Strings

10. `src/skills/migration.ts:40-43` — four `..` hops from `src/skills/` escapes the project root; should be two hops
11. `src/mcp/tools/handlers/context.ts:183` — error string references `src/matrix-daemon.ts`; real path is `src/daemons/matrix-daemon.ts`

### LOW

12. `src/nerve/known-fixes.ts:10-11` — duplicate `node:fs/promises` import statements (two separate lines)

### CLEARED

- `src/mcp/startup-health.ts:7` — `getSystemStateQuick` import from `'../core/db'` resolves correctly via shim chain: `src/core/db.ts` -> `./db/index` -> `src/core/db/index.ts` -> `export * from './code-files'`
