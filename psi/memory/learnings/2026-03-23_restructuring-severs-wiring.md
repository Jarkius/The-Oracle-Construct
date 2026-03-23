# Lesson: Restructuring Severs Wiring

**Date**: 2026-03-23
**Source**: Control Center v2 merge — 43 missing slash commands
**Confidence**: High (lost 43 commands silently)

## Pattern

Moving or renaming files preserves content but silently breaks integration points. Always trace all callers before restructuring.

## Problem

During the Matrix Overhaul, `.claude/commands/*.md` files were deleted as part of restructuring. The agent definitions were moved to `.agent/workflows/*.md` — but the slash command registration (which Claude Code reads from `.claude/commands/`) was severed. 43 slash commands (`/neo`, `/smith`, `/tank`, `/morpheus`, `/oracle`, `/trinity`, `/scribe`, `/architect`, etc.) became silently unavailable.

Nobody noticed until the user tried `/smith` and got nothing. The definitions existed; the wiring didn't.

## Solution

Created thin loader stubs in `.claude/commands/*.md` that point to `.agent/workflows/*.md`:

```markdown
Read and execute workflow from `.agent/workflows/<name>.md`
Follow the instructions there.
ARGUMENTS: $ARGUMENTS
```

This pattern maintains a single source of truth (workflows) while preserving the integration point (commands).

## Rule

1. Before moving/renaming files, list all consumers (imports, configs, registrations, hooks)
2. After restructuring, verify integration points still work (slash commands, hooks, imports, CI)
3. Use the "thin loader" pattern when you need files in two locations — pointer in one, content in another
4. Consider a validation check: "are all expected commands registered?" as part of merge readiness

## Related

- Hooks flatten (2026-03-20): Moving hooks broke `$SCRIPT_DIR/../..` shell paths
- Auto-detect over hardcode (2026-03-20): `../` counting broke when file depth changed
- Both are the same root cause: restructuring without tracing all integration points

## Tags

architecture, restructuring, slash-commands, integration, anti-pattern, wiring
