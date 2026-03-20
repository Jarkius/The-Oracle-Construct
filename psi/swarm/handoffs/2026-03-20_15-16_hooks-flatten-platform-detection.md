# Handoff: Hooks Flatten + Platform Detection

**Date**: 2026-03-20 15:16 GMT+7
**Branch**: main (all merged)
**Context**: ~60%

## What We Did
- Diagnosed Stop hook error — `$SCRIPT_DIR/../..` resolved to `.claude/` instead of project root due to subdirectory depth
- Flattened `.claude/hooks/{core,pulse,voice,util}/` back to `.claude/hooks/` (85 files)
- Updated all cross-references (settings.json, CLAUDE.md, BOOT.md, docs, TypeScript)
- Added platform auto-detection: `python3 --version` guard (Windows stub returns 49)
- Fixed `grep -c` multiline bug in reminders check
- All 4 registered hooks (Stop, Start, PreCompact, PostToolUse) return exit 0 on both macOS and Windows
- Saved feedback memory: always check docs before restructuring

## What Was Done in Prior Sessions (Sprint Summary)
- Consolidated `lib/matrix-memory-agents/` into root `src/` (single source of truth)
- Fixed 20+ stale imports, broken paths, logic bugs across all modules
- Merged PR #27, closed PR #26
- Renamed MMA_DIR → MATRIX_ROOT across 6 shell scripts
- 120 tests passing

## Pending
- [ ] Clean up stale remote branches (evolve/matrix-overhaul, feat/matrix-restructure-phase0-15)
- [ ] Control Center overhaul — currently minimal Hono dashboard
- [ ] Memory management — ChromaDB, SQLite, embeddings need platform-aware setup
- [ ] `sharp` module platform mismatch (bun cache has darwin-arm64 on Windows)
- [ ] Dead barrel exports cleanup (WRITE_TOOLS, EXEC_TOOLS, etc.) — harmless
- [ ] Stop hook `bun memory save` interactive prompt in non-interactive context

## Next Session
- [ ] Create `feat/control-center-v2` branch
- [ ] Overhaul Control Center: real-time dashboard with service health, memory status, error logs
- [ ] Memory management: platform-aware ChromaDB/SQLite/embedding setup
- [ ] Design frontend that can control backend services
- [ ] Surface `psi/state/pulse/memory-errors.log` in dashboard

## Key Files
- `src/daemons/control-center/control-center.ts` — Current minimal dashboard
- `src/memory/vector-db.ts` — ChromaDB integration
- `src/memory/embeddings/` — Transformers.js provider
- `src/core/db/` — 22 SQLite modules
- `.claude/hooks/matrix-services.sh` — Service lifecycle management
- `src/nerve/supervisor.ts` — Daemon health monitoring
