# Handoff: Control Center v2 + Architect Review + Path Auto-Detection

**Date**: 2026-03-20 16:47 GMT+7
**Branch**: feat/control-center-v2 (2 commits ahead of main)
**Context**: ~40%

## What We Did

### Control Center v2 (Hono + HTMX + SSE)
- Built modular backend: 5 route modules (daemons, memory, logs, stream, config)
- Built frontend: 5 page views + 3 HTMX partials + dark Matrix theme
- Downloaded HTMX v2.0.4 (51KB) + SSE extension (9KB) via Bun fetch
- Port changed from 8100 → 8180 (avoids ChromaDB conflict)
- Server binds to 127.0.0.1 (localhost only)

### Architect Cross-Check (3 Critical Fixed)
- C2: Added missing POST endpoints (reindex, export, vacuum) in memory routes
- C3: Fixed SSE live tail URL mismatch (path param vs query param)
- W7: Bound server to localhost only for security
- W1/W2: Deduplicated daemon-check logic (4 copies → 1 shared `checkDaemonStatus`)
- Removed dead imports, unused code (`readFileOr`, `renderEventItem`, `config`)

### Path Auto-Detection (`src/core/paths.ts`)
- Created `findProjectRoot()` — walks up to find `CLAUDE.md + src/` or `package.json + .git`
- Replaced ALL `import.meta.dir + ../../../..` patterns with `PROJECT_ROOT`
- This kills the entire class of bugs from hooks flattening + control center

### Other
- Installed `tsc` globally (v5.9.3)
- Hooks flattened to `.claude/hooks/` (from prior session, committed)
- Platform auto-detection (python3 guard, voice guard) working
- Deep retrospective written with 5 parallel agents

## Pending

### Critical
- [ ] **Missing slash commands** — `/neo`, `/smith`, `/tank`, `/morpheus`, `/oracle`, `/trinity`, `/scribe`, `/architect` deleted from `.claude/commands/` during restructuring. Agent definitions exist in `.agent/workflows/` but aren't registered as slash commands
- [ ] **Dashboard vs Services page duplicate** — both render identical daemon cards. Dashboard should show summary, Services should show full control panel with logs
- [ ] **Heartbeat daemon won't start** — `matrix-services.sh start heartbeat` fails (service-level issue, not path issue). Check daemon-logs/heartbeat.log

### Important
- [ ] **ChromaDB on Windows** — unreachable (port 8100). Either start it or set `SKIP_VECTORDB=true`
- [ ] **Status line update** — user mentioned our matrix has code for this, needs checking
- [ ] **Multi-language architecture** — user wants to plan for Python layer formalization (9 scattered scripts, no requirements.txt)
- [ ] **API key centralization** — verify all services use `src/core/config.ts`, not raw `process.env`

### Architect Review Remaining (WARN level)
- [ ] W3: SSE byte-offset math broken for multi-byte UTF-8 (stream.ts lines 83-89)
- [ ] W4: `DB_PATH` is relative ("./agents.db") — may resolve wrong when run as daemon
- [ ] W8: `kill-orphans` has no self-protection (could kill own process)

### Nice to Have
- [ ] Extract shared `esc()` helper (duplicated in 3 partials)
- [ ] Static file serving regex only allows .js/.css (no future .svg/.png)
- [ ] `sharp` module platform mismatch (darwin-arm64 in bun cache on Windows)

## What Was Done in Prior Sessions (Sprint Summary)
- Consolidated `lib/matrix-memory-agents/` into root `src/` (single source of truth)
- Fixed 20+ stale imports, broken paths, logic bugs across all modules
- Merged PR #27, closed PR #26
- Flattened hooks from subdirectories back to `.claude/hooks/` (85 files)
- Added platform auto-detection (python3, voice, grep fixes)
- 120 tests passing

## Next Session
- [ ] Restore slash commands — create `.claude/commands/{neo,smith,tank,...}.md` that reference `.agent/workflows/`
- [ ] Differentiate Dashboard (summary) vs Services (full control) pages
- [ ] Fix W3 (UTF-8 SSE offset), W4 (DB_PATH), W8 (kill-orphans safety)
- [ ] Merge `feat/control-center-v2` → main (after testing)
- [ ] Plan multi-language evolution (formalize Python layer, centralize API keys)
- [ ] Consider `PROJECT_ROOT` adoption across entire `src/` codebase (not just control center)

## Key Files
- `src/core/paths.ts` — Project root auto-detection (NEW, critical utility)
- `src/daemons/control-center/control-center.ts` — Main dashboard entry (rewritten)
- `src/daemons/control-center/routes/*.ts` — 5 API route modules
- `src/daemons/control-center/views/*.ts` — 5 page views
- `src/daemons/control-center/partials/*.ts` — 3 HTMX fragments
- `.claude/hooks/matrix-services.sh` — Service lifecycle management
- `.agent/workflows/*.md` — Agent definitions (need slash command wiring)
- `psi/memory/retrospectives/2026-03/20/16.47_control-center-v2-deep.md` — Deep retro
- `psi/memory/learnings/2026-03-20_auto-detect-over-hardcode.md` — Key lesson
