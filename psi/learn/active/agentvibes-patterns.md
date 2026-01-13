# AgentVibes Pattern Extraction

**Date**: 2026-01-13
**Source**: `psi/lab/research/AgentVibes_Research/`
**Status**: Extracted before MCP removal
**Token Savings**: ~3.5k per session

---

## 1. SessionStart Hook Injection Pattern

**Problem**: Output styles are unreliable - Claude may not see TTS instructions.

**Solution**: Use Claude Code's SessionStart hook to inject protocol at session start.

```
SessionStart hook → Inject into context → 100% reliable
```

**Key Files**:
- `.claude/hooks/session-start-tts.sh` - The hook
- `.claude/settings.json` - Hook configuration

**Why It Works**:
| Feature | Output Style | SessionStart Hook |
|---------|-------------|------------------|
| Reliability | Inconsistent | 100% reliable |
| Automatic | Manual activation | Works immediately |
| Context Injection | May not be injected | Injected every session |

**Matrix Status**: Already implemented via `psi/matrix/voice.sh` + voice_server.py

---

## 2. Provider Abstraction Pattern

**Architecture**:
```
┌─────────────────┐
│  play-tts.sh    │  ← Router (entry point)
│    (Router)     │
└────────┬────────┘
         │
    ┌────┴────┐
    ▼         ▼
┌────────┐ ┌────────┐
│ Piper  │ │ macOS  │  ← Provider implementations
│ TTS    │ │ TTS    │
└────────┘ └────────┘
```

**Design Principles**:
1. **Provider Abstraction** - Single entry point hides complexity
2. **Loose Coupling** - Providers are standalone scripts
3. **File-Based State** - `.claude/tts-provider.txt` (human-readable, git-friendly)
4. **Backward Compatibility** - Old format still works

**State Management**:
```
Project-local (.claude/tts-provider.txt)
         ↓
Global fallback (~/.claude/tts-provider.txt)
         ↓
Default (piper)
```

**Matrix Status**: Could adopt if we need multiple TTS backends in future.

---

## 3. Personality vs Sentiment Distinction

**Terminology**:
- **Personality** = Changes voice + style (full transformation)
- **Sentiment** = Keeps your voice + adds style overlay

**Example**:
```bash
# Personality: Switch to Pirate Marshal voice + pirate speak
/agent-vibes:personality pirate

# Sentiment: Keep current voice + add sarcasm
/agent-vibes:sentiment sarcastic
```

**Matrix Equivalent**:
- Agent voices (Oracle=Kristin, Neo=Ryan) = Personalities
- Audio effects (Smith=bass boost) = Sentiment-like overlays

---

## 4. Shell Script Security Patterns

**Best Practices from AgentVibes CLAUDE.md**:

```bash
# REQUIRED: Always use strict mode
set -euo pipefail

# REQUIRED: Use secure temp directories
if [[ -n "${XDG_RUNTIME_DIR:-}" ]] && [[ -d "$XDG_RUNTIME_DIR" ]]; then
  TEMP_DIR="$XDG_RUNTIME_DIR/matrix-voice"
else
  TEMP_DIR="/tmp/matrix-voice-$USER"
fi

# REQUIRED: Set restrictive permissions
mkdir -p "$TEMP_DIR"
chmod 700 "$TEMP_DIR"

# REQUIRED: Verify ownership before processing
if [[ "$(stat -f '%u' "$DIR" 2>/dev/null)" != "$(id -u)" ]]; then
  echo "Error: Directory not owned by current user" >&2
  exit 1
fi

# REQUIRED: Use single quotes in trap (defer expansion)
trap 'rm -f "$PID_FILE"' EXIT

# REQUIRED: Validate numeric input
if [[ "$VALUE" =~ ^[0-9]+$ ]]; then
  # Safe to use
fi

# REQUIRED: Quote all variables
echo "$VARIABLE"  # Good
echo $VARIABLE    # Bad - word splitting/globbing risk
```

**Action Item**: Apply `set -euo pipefail` to `psi/matrix/voice.sh`

---

## 5. Language Learning Mode (Novel Feature)

**Concept**: Learn languages while coding by hearing TTS twice:
1. English (native)
2. Target language (learning)

**Use Case**:
```
User: "Run the tests"
English: "Running your test suite now!"
Spanish: "¡Ejecutando tu suite de pruebas ahora!"
```

**Implementation**:
- Auto-translation via Google Translate
- Adjustable speed for target language (2x, 3x slower)
- Provider-aware voice selection

**Matrix Potential**: Could enable bilingual sessions in future.

---

## 6. Verbosity Levels

**Three-tier system**:

| Level | Speaks | Use Case |
|-------|--------|----------|
| LOW | Start + End only | Quiet work |
| MEDIUM | + Major decisions | Balanced |
| HIGH | + All reasoning | Full transparency |

**Matrix Status**: Already implemented via SessionStart hook injection.

---

## Summary

| Pattern | Extracted | Matrix Status |
|---------|-----------|---------------|
| SessionStart Hook | Yes | Implemented |
| Provider Abstraction | Yes | Reference for future |
| Personality/Sentiment | Yes | Terminology adopted |
| Security Patterns | Yes | **Action: Apply to voice.sh** |
| Language Learning | Yes | Archive for future |
| Verbosity Levels | Yes | Implemented |

---

## References

- Source repo: `psi/lab/research/AgentVibes_Research/`
- Key docs: `docs/how-hooks-work.md`, `docs/architecture/provider-system.md`
- Package: `agentvibes@3.0.0` on npm
- Author: paulgprei

---

*Extracted by Oracle before MCP removal. Nothing is deleted.*
