# Handoff: Control Center v2 Merged — Next Evolution Planning

**Date**: 2026-03-23 10:00 GMT+7
**Branch**: main (up to date with origin)
**Context**: ~30%

## What We Did

### Control Center v2 → main (Merged)
- Verified background agent diffs (W3/W4/W8 fixes + dashboard differentiation)
- Committed architect WARN fixes: SSE line-count tracking, DB_PATH absolute, kill-orphans PID safety
- Committed 43 restored slash commands as thin loader stubs
- Fast-forward merged `feat/control-center-v2` (5 commits) into main
- Pushed to origin, deleted feature branch (local + remote)
- Clean state on main

### Deep Retrospective (/rrr --deep)
- 5 parallel agents analyzed git, files, timeline, patterns, Oracle connections
- Key lesson: "Restructuring severs wiring" — always trace callers before moving files
- Written to `psi/memory/retrospectives/2026-03/23/09.57_cc-v2-merge-complete.md`

### What's on Main Now
- Control Center v2: Hono + HTMX + SSE, modular routes, dark Matrix theme, port 8180
- `src/core/paths.ts`: PROJECT_ROOT auto-detection (replaces all `../` counting)
- 43 slash commands wired to `.agent/workflows/` definitions
- Dashboard shows compact daemon summary, Services shows full control cards
- All 3 architect critical issues + 3 WARN items fixed
- 120 tests passing

## Pending

### Architecture
- [ ] **Multi-language evolution plan** — Python layer formalization (9 scattered scripts, no requirements.txt). TypeScript = core runtime, Python = ML/analysis, Shell = hooks
- [ ] **PROJECT_ROOT adoption** — Grep remaining `import.meta.dir + ../` across entire `src/`. Replace with `PROJECT_ROOT`
- [ ] **API key centralization audit** — Verify all services use `src/core/config.ts`, not raw `process.env`

### Infrastructure
- [ ] **Heartbeat daemon won't start** — Check `psi/state/pulse/daemon-logs/heartbeat.log`
- [ ] **ChromaDB on Windows** — Unreachable (port 8100). Either start it or set `SKIP_VECTORDB=true`
- [ ] **Status line integration** — User mentioned matrix has code for this
- [ ] **memory-errors.log rotation** — 2318 lines and growing, needs cleanup/rotation

### Nice to Have
- [ ] Extract shared `esc()` helper (duplicated in 3 partials)
- [ ] Static file regex: only allows .js/.css (no .svg/.png)
- [ ] `sharp` module platform mismatch (darwin-arm64 in bun cache on Windows)
- [ ] CI check for slash command registration (prevent silent loss)

### Mission
- [ ] **CIS Modernization** — React SPA + Laravel API (the main project mission, blocked by Matrix infra)

## Next Session

1. [ ] Plan multi-language architecture (Python layer: `scripts/python/` with `requirements.txt`)
2. [ ] `PROJECT_ROOT` adoption across entire `src/` (grep + replace)
3. [ ] API key centralization audit
4. [ ] Fix heartbeat daemon startup
5. [ ] Consider starting CIS Modernization work (the actual mission)

## Key Files

- `src/core/paths.ts` — Project root auto-detection
- `src/core/db/core.ts` — Database with absolute paths
- `src/daemons/control-center/` — Full v2 dashboard (routes/, views/, partials/)
- `.claude/commands/*.md` — 43 slash command stubs
- `.agent/workflows/*.md` — Agent definitions (canonical)
- `psi/memory/retrospectives/2026-03/23/09.57_cc-v2-merge-complete.md` — Deep retro
- `psi/memory/learnings/2026-03-23_restructuring-severs-wiring.md` — Key lesson
- `psi/memory/learnings/2026-03-20_auto-detect-over-hardcode.md` — Prior key lesson
