# Current Focus: Voice Queue Repair & Handoff

**Status**: Voice Queue Broken (shlock failed) ⚠️
**Last Session**: January 8, 2026 @ 22:24 - Voice Queue Fix Attempt + Unplug
**Handoff**: Active

## What Was Done (This Session)
- **Issue #5**: Verified Dynamic Greetings (System + Oracle) working.
- **Issue #6**: Attempted `flock` -> `shlock` replacement for voice queue.
    - `shlock` failed with `link` errors during verification.
    - `session-start-tts.sh` modified to sequential calls (System plays, then Oracle).
- **Unplug**: Prompted by user during fix.

## Open Issues
- **Issue #6**: Voice Queue Mechanism (Broken)
    - Need to replace `shlock` with `mkdir` atomic lock pattern.
    - Current `voice_module.sh` has `shlock` implementation which errors.

## Next Session Priorities
1. [ ] **Fix Voice Queue**: Replace `shlock` with `mkdir` in `voice_module.sh`.
2. [ ] **Verify**: Ensure specific "System" -> "Oracle" playback order without errors.
3. [ ] **Resume**: HTTP API planning.

## Current Branch
`main` (local changes uncommitted)

## Key Files
- `psi/active/voice_module.sh` (Needs repair)
- `.claude/hooks/session-start-tts.sh` (Sequential logic verified)
