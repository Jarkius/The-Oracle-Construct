# Voice Source of Truth: Lessons Learned

> *"One source of truth. No more drift."*

## The Problem (2026-01-08)

### Symptoms
- Smith's voice sounded female instead of male (Danny Low)
- MCP `set_voice()` reported success but voice didn't change
- Voices worked via `voice_module.sh` but not via `play-tts.sh`

### Root Cause: Configuration Drift

**Three separate systems, no synchronization:**

| System | Config Location | Used By |
|--------|-----------------|---------|
| `voices.json` | `.claude/config/` | `voice_module.sh` (source of truth) |
| `tts-voice.txt` | `.claude/` | Shell hooks (`play-tts.sh`) |
| MCP internal state | Memory only | AgentVibes MCP tools |

When switching agents:
1. MCP tool sets its internal state → ✅
2. MCP doesn't write to `tts-voice.txt` → ❌
3. Shell hooks read stale `tts-voice.txt` → Wrong voice!

### Why It Worked Last Night

`voice_module.sh` has **hardcoded bypasses** for each agent:

```bash
# Lines 53-71: Smith bypass
if [ "$SPEAKER" = "Smith" ]; then
    echo "$MESSAGE" | piper --model ~/.claude/piper-voices/en_US-danny-low.onnx ...
    exit 0
fi
```

This works because it reads directly from `voices.json` and ignores `tts-voice.txt`.

### Why It Broke This Morning

We used MCP `set_voice("en_US-danny-low")` directly, which:
1. Changed MCP internal state
2. Did NOT write to `tts-voice.txt`
3. Next `play-tts.sh` call read stale voice from file

## The Solution

### 1. Source of Truth: `voices.json`

```json
{
  "Smith": {
    "voice": "en_US-danny-low",
    "personality": "sarcastic"
  }
}
```

**This is the ONLY place agent voices should be defined.**

### 2. Activation Script: `activate-agent.sh`

```bash
# Syncs from source of truth to active config
.claude/hooks/activate-agent.sh Smith
# Output:
# ✅ Agent activated: Smith
#    Voice: en_US-danny-low
#    Personality: sarcastic
#    Source: voices.json (single source of truth)
```

This writes to `tts-voice.txt` so shell hooks stay in sync.

### 3. Verification Script: `verify-voices.sh`

```bash
# Part of /patrol duties
.claude/hooks/verify-voices.sh
# Checks: voices.json ↔ tts-voice.txt alignment
# Checks: All voice models exist
```

## Rules Going Forward

1. **NEVER manually edit `tts-voice.txt`** - Use `activate-agent.sh`
2. **Add new agents to `voices.json`** - The single source of truth
3. **Run `/patrol` regularly** - Smith detects voice drift
4. **Use `voice_module.sh` for agent speech** - It has correct bypasses

## Architecture Diagram

```
                    SOURCE OF TRUTH
                   ┌──────────────────┐
                   │   voices.json    │
                   │ (agent → voice)  │
                   └────────┬─────────┘
                            │
           ┌────────────────┼────────────────┐
           │                │                │
           ▼                ▼                ▼
    ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
    │voice_module  │ │activate-agent│ │verify-voices │
    │    .sh       │ │    .sh       │ │    .sh       │
    │(hardcoded    │ │(syncs to     │ │(checks       │
    │ bypasses)    │ │ tts-voice)   │ │ alignment)   │
    └──────────────┘ └──────┬───────┘ └──────────────┘
                            │
                            ▼
                   ┌──────────────────┐
                   │  tts-voice.txt   │
                   │ (active voice)   │
                   └────────┬─────────┘
                            │
                            ▼
                   ┌──────────────────┐
                   │   play-tts.sh    │
                   │ (shell hooks)    │
                   └──────────────────┘
```

## Related Files

- `.claude/config/voices.json` - Source of truth
- `.claude/hooks/activate-agent.sh` - Sync script
- `.claude/hooks/verify-voices.sh` - Audit script
- `psi/matrix/voice.sh` - Agent speech with bypasses
- `.agent/workflows/patrol.md` - Smith's monitoring duties

---

*Lesson learned: 2026-01-08*
*"Configuration drift is a silent virus. One source of truth is the cure."*
