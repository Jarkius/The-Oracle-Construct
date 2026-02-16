# WEP-001: Add Hook Permission Guard to Prevent Silent Failures

**Status**: applied
**Applied**: 2026-02-16
**Detected**: 2026-02-16
**Pattern**: 49 of 56 hooks were non-executable, causing silent failures when invoked by settings.json
**Confidence**: 0.95

## Problem

Hooks registered in `.claude/settings.json` fail silently when they lack execute permissions. This was discovered during a system health audit — 88% of hooks were broken. No error was raised. No alert fired. The system appeared healthy while most of its nervous system was dead.

## Proposed Change

Add a **permission verification step** to the session-start hook that checks all registered hooks are executable. If any hook lacks `+x`, either:
1. Auto-fix it (`chmod +x`) and log the event, or
2. Announce the broken hooks to the operator

This prevents the "everything looks fine" failure mode where hooks exist but never fire.

## Implementation

Add to `.claude/hooks/matrix-session-start.sh`:
```bash
# Verify all hooks are executable
for hook in "$PROJECT_ROOT"/.claude/hooks/*.sh; do
  if [ -f "$hook" ] && [ ! -x "$hook" ]; then
    chmod +x "$hook"
    echo "[hook-guard] Fixed: $(basename $hook) was not executable" >&2
    bash "$PROJECT_ROOT/.claude/hooks/pulse-event-writer.sh" "error:hook-permission" "System" "{\"hook\":\"$(basename $hook)\"}"
  fi
done
```

## Affected Workflows

- `.claude/hooks/matrix-session-start.sh`

## Evidence

- System health audit found 49/56 hooks non-executable
- Pattern: hooks created via Write tool get `644` permissions (no execute)
- All hooks registered in settings.json expected to be executable
- Zero alerting existed for this failure mode

## Risk Assessment

**Risk**: low
**Reversibility**: easy — remove the guard block
**Impact**: All hooks benefit; no behavior change when permissions are correct
