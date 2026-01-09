# Voice Standards & Troubleshooting

**Last Updated**: 2026-01-10

## Standards

### Speed
**Source**: `psi/memory/learnings/voice_preference_210wpm.md`
- **Standard Rate**: **210 WPM (approx 1x)**.
- **History**: Initial 300 WPM (1.5x) was deemed too fast.

### Configuration
- **Neo**: Ryan (Piper) - *Confirmed 2026-01-10*.
- **Scribe**: Lessac (Piper).
- **Oracle**: Kristin (Piper).

## Troubleshooting

### "The Chaos" (Missing Voices/Theme)
**Source**: `psi/memory/learnings/rca_chaos.md` / `Git Issue #6`
- **Symptom**: System state resets, voices vanish.
- **Root Cause**: Lack of persistence automation (`.claude/config/matrix.json`).
- **Resolution**:
    1.  Ensure voice models are not gitignored (or auto-downloaded).
    2.  Enforce state at session start.
