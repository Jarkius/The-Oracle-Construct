#!/usr/bin/env bash
# ============================================================
# voice-diagnostic.sh - Matrix Voice System Diagnostic
# ============================================================
#
# PURPOSE:
#   Comprehensive check of the Matrix voice system health.
#   Run this when voice issues occur.
#
# USAGE:
#   ./.claude/hooks/voice-diagnostic.sh
#
# CHECKS:
#   - Dependencies (Piper, Sox, ffmpeg, afplay)
#   - Matrix voice scripts (voice.sh, voice_server.py)
#   - Voice server daemon status
#   - Voice models (all 10 agent voices)
#   - Lock files and stale locks
#   - Audio output test
#
# ============================================================

echo "🔍 Matrix Voice Diagnostic v3.0"
echo "================================"

errors=0
warnings=0

# Get project root (assume script is in .claude/hooks/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# ============================================
# 1. DEPENDENCIES
# ============================================
echo ""
echo "## Dependencies"

echo -n "  Piper binary... "
PIPER_PATH="$HOME/.local/bin/piper"
if [[ -x "$PIPER_PATH" ]]; then
    echo "✅ Found ($PIPER_PATH)"
elif command -v piper &> /dev/null; then
    FOUND_PIPER=$(which piper)
    if [[ "$FOUND_PIPER" == *"site-packages"* ]] || [[ "$FOUND_PIPER" == *"pip"* ]]; then
        echo "⚠️  Found but may be Python piper: $FOUND_PIPER"
        warnings=$((warnings+1))
    else
        echo "✅ Found ($FOUND_PIPER)"
    fi
else
    echo "❌ MISSING"
    errors=$((errors+1))
fi

echo -n "  Sox binary... "
if command -v sox &> /dev/null; then
    echo "✅ Found ($(which sox))"
else
    echo "⚠️  Missing (bass boost disabled)"
    warnings=$((warnings+1))
fi

echo -n "  ffmpeg binary... "
if command -v ffmpeg &> /dev/null; then
    echo "✅ Found ($(which ffmpeg))"
else
    echo "⚠️  Missing (background music mixing disabled)"
    warnings=$((warnings+1))
fi

echo -n "  afplay (macOS)... "
if [[ "$(uname)" == "Darwin" ]]; then
    if command -v afplay &> /dev/null; then
        echo "✅ Found"
    else
        echo "❌ MISSING"
        errors=$((errors+1))
    fi
else
    echo "⏭️  Skipped (not macOS)"
fi

# ============================================
# 2. MATRIX VOICE SYSTEM
# ============================================
echo ""
echo "## Matrix Voice System"

echo -n "  voice.sh (client)... "
if [[ -f "$PROJECT_ROOT/psi/matrix/voice.sh" ]]; then
    echo "✅ Found"
else
    echo "❌ MISSING (psi/matrix/voice.sh)"
    errors=$((errors+1))
fi

echo -n "  voice_server.py (daemon)... "
if [[ -f "$PROJECT_ROOT/psi/matrix/voice_server.py" ]]; then
    echo "✅ Found"
else
    echo "❌ MISSING (psi/matrix/voice_server.py)"
    errors=$((errors+1))
fi

echo -n "  Voice Server Status... "
SERVER_PID=$(pgrep -f "voice_server.py" 2>/dev/null | head -1)
if [[ -n "$SERVER_PID" ]]; then
    echo "✅ Running (PID: $SERVER_PID, Port: 6969)"
else
    echo "❌ NOT RUNNING"
    echo "     Start with: python3 psi/matrix/voice_server.py &"
    errors=$((errors+1))
fi

echo -n "  Server Lock File... "
LOCK_FILE="/tmp/matrix_voice_server.lock"
if [[ -f "$LOCK_FILE" ]]; then
    LOCK_PID=$(cat "$LOCK_FILE" 2>/dev/null)
    if kill -0 "$LOCK_PID" 2>/dev/null; then
        echo "✅ Valid (PID: $LOCK_PID)"
    else
        echo "⚠️  Stale lock (removing)"
        rm -f "$LOCK_FILE"
    fi
else
    if [[ -n "$SERVER_PID" ]]; then
        echo "⚠️  Missing but server running"
        warnings=$((warnings+1))
    else
        echo "✅ Clear (server not running)"
    fi
fi

# ============================================
# 3. VOICE CONFIG
# ============================================
echo ""
echo "## Voice Configuration"

echo -n "  voices.json... "
if [[ -f "$PROJECT_ROOT/.claude/config/voices.json" ]]; then
    AGENT_COUNT=$(grep -c '"personality"' "$PROJECT_ROOT/.claude/config/voices.json" 2>/dev/null || echo "?")
    echo "✅ Found ($AGENT_COUNT agents configured)"
else
    echo "⚠️  Missing (using hardcoded voices)"
    warnings=$((warnings+1))
fi

# ============================================
# 4. VOICE MODELS
# ============================================
echo ""
echo "## Voice Models (~/.claude/piper-voices/)"

PIPER_VOICE_DIR="$HOME/.claude/piper-voices"
AGENT_VOICES=(
    "Oracle:en_US-kristin-medium.onnx"
    "Neo:en_US-ryan-high.onnx"
    "Trinity:jenny.onnx"
    "Morpheus:en_US-carlin-high.onnx"
    "Smith:en_US-danny-low.onnx"
    "Tank:en_US-bryce-medium.onnx"
    "Architect:en_GB-alan-medium.onnx"
    "Mainframe:en_US-norman-medium.onnx"
    "System:en_US-hfc_male-medium.onnx"
    "Scribe:en_US-lessac-medium.onnx"
)

missing_voices=0
for entry in "${AGENT_VOICES[@]}"; do
    agent="${entry%%:*}"
    voice_file="${entry##*:}"
    voice_path="$PIPER_VOICE_DIR/$voice_file"

    printf "  %-10s " "$agent:"
    if [[ -f "$voice_path" ]]; then
        SIZE=$(du -h "$voice_path" 2>/dev/null | cut -f1)
        echo "✅ $voice_file ($SIZE)"
    else
        echo "❌ MISSING $voice_file"
        missing_voices=$((missing_voices+1))
    fi
done

if [[ $missing_voices -gt 0 ]]; then
    errors=$((errors+missing_voices))
    echo ""
    echo "  ⚠️  $missing_voices voice model(s) missing"
fi

# ============================================
# 5. AUDIO OUTPUT TEST
# ============================================
echo ""
echo "## Audio Output Test"

if [[ "$(uname)" == "Darwin" ]] && command -v sox &> /dev/null; then
    echo -n "  Test tone (440Hz, 1s)... "
    if command -v gtimeout &> /dev/null; then
        gtimeout 2 sox -n -d synth 1 sine 440 gain -10 2>/dev/null && echo "✅ Played" || echo "⚠️  Failed"
    else
        sox -n -d synth 1 sine 440 gain -10 2>/dev/null &
        SOX_PID=$!
        sleep 1.5
        kill $SOX_PID 2>/dev/null || true
        wait $SOX_PID 2>/dev/null || true
        echo "✅ Played"
    fi
else
    echo "  ⏭️  Skipped (sox not available or not macOS)"
fi

# ============================================
# 6. QUICK VOICE TEST
# ============================================
echo ""
echo "## Quick Voice Test"

if [[ -n "$SERVER_PID" ]] && [[ -f "$PROJECT_ROOT/psi/matrix/voice.sh" ]]; then
    echo -n "  Sending test message to Oracle... "
    cd "$PROJECT_ROOT"
    sh psi/matrix/voice.sh "Diagnostic complete." "Oracle" 2>/dev/null
    echo "✅ Sent (check audio)"
else
    echo "  ⏭️  Skipped (server not running)"
fi

# ============================================
# SUMMARY
# ============================================
echo ""
echo "================================"
if [[ "$errors" -eq 0 ]] && [[ "$warnings" -eq 0 ]]; then
    echo "✅ MATRIX VOICE SYSTEM HEALTHY"
elif [[ "$errors" -eq 0 ]]; then
    echo "⚠️  STABLE ($warnings warning(s))"
else
    echo "❌ $errors ERROR(S), $warnings WARNING(S)"
    echo ""
    echo "Common fixes:"
    echo "  - Start server: python3 psi/matrix/voice_server.py &"
    echo "  - Download voices: Check ~/.claude/piper-voices/"
fi
echo "================================"

exit $errors
