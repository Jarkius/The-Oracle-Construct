# Lesson: Large Restructures Need Post-Move Path Audits

**Date**: 2026-03-23
**Source**: rrr — recap fix + path reconciliation session
**Tags**: restructure, paths, self-healing, audit

## Context

The March 16 restructure moved 111 files into a new directory structure. 24 path references across the codebase were not updated, including 6 CRITICAL failures (Nerve daemon registration, unicode symlink defaults). The self-healing system (Nerve) couldn't restart daemons because it registered them at paths that didn't exist. This went undetected for 7 days.

## Lesson

After any restructure that moves more than 10 files:
1. **Grep for all old paths** across .sh, .ts, .py, .json, .md files
2. **Run the moved files as a list** and check each old path for remaining references
3. **Smoke test all services** — start heartbeat, gateway, hub, indexer
4. **Check self-healing references** — the healer must reference correct paths too

## Applied

- Fixed all 24 broken references in commit `0bc3812`
- Enriched recap skill to detect event failures (early warning)
- Saved to auto-memory for cross-session persistence
