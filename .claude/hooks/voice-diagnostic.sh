#!/usr/bin/env bash
# File: psi/lab/voice_diagnostic.sh
# Smith Audio Diagnostic v2.0 - All anomalies neutralized by Neo

echo "🔍 Smith Audio Diagnostic v2.0"
echo "=============================="

errors=0

# 1. Check Dependencies
echo -n "Checking Piper binary... "
# Fix #2: Check specific path first, then fallback to command -v
PIPER_PATH="$HOME/.local/bin/piper"
if [[ -x "$PIPER_PATH" ]]; then
    echo "✅ Found ($PIPER_PATH)"
elif command -v piper &> /dev/null; then
    FOUND_PIPER=$(which piper)
    # Warn if it might be Python's piper
    if [[ "$FOUND_PIPER" == *"site-packages"* ]] || [[ "$FOUND_PIPER" == *"pip"* ]]; then
        echo "⚠️  Found but may be Python piper: $FOUND_PIPER"
    else
        echo "✅ Found ($FOUND_PIPER)"
    fi
else
    echo "❌ MISSING"
    errors=$((errors+1))
fi

echo -n "Checking Sox binary... "
if command -v sox &> /dev/null; then
    echo "✅ Found ($(which sox))"
else
    echo "⚠️  Missing (Audio effects disabled)"
fi

echo -n "Checking ffmpeg binary... "
if command -v ffmpeg &> /dev/null; then
    echo "✅ Found ($(which ffmpeg))"
else
    echo "⚠️  Missing (Background mixing/padding disabled)"
fi

# Fix #9: Check play-tts.sh exists
echo -n "Checking play-tts.sh hook... "
if [[ -f ".claude/hooks/play-tts.sh" ]]; then
    echo "✅ Found"
else
    echo "❌ MISSING (.claude/hooks/play-tts.sh)"
    errors=$((errors+1))
fi

# Fix #10: Check voices.json config
echo -n "Checking voices.json config... "
if [[ -f ".claude/config/voices.json" ]]; then
    echo "✅ Found"
else
    echo "⚠️  Missing (.claude/config/voices.json - using defaults)"
fi

# 2. Check Configuration
echo -n "Checking Voice Config... "
VOICE_FILE=".claude/tts-voice.txt"
if [[ -f "$VOICE_FILE" ]]; then
    VOICE=$(cat "$VOICE_FILE")
    # Fix #3: Validate VOICE is not empty
    if [[ -z "$VOICE" ]]; then
        VOICE="en_US-hfc_male-medium"
        echo "⚠️  Empty config, using default: $VOICE"
    else
        echo "✅ Active: $VOICE"
    fi
else
    # Fix #3: Provide fallback value
    VOICE="en_US-hfc_male-medium"
    echo "⚠️  Missing tts-voice.txt, using default: $VOICE"
fi

echo -n "Checking Personality... "
PERS_FILE=".claude/tts-personality.txt"
if [[ -f "$PERS_FILE" ]]; then
    PERS=$(cat "$PERS_FILE")
    echo "✅ Active: $PERS"
else
    echo "⚠️  Missing tts-personality.txt (using default)"
fi

# 3. Check Mute State
echo -n "Checking Mute Status... "
# Fix #4: Check project unmute override first
if [[ -f ".claude/agentvibes-unmuted" ]]; then
    echo "✅ Explicitly unmuted (project override)"
elif [[ -f ".claude/agentvibes-muted" ]]; then
    echo "🔇 MUTED (project)"
    echo "   - Run: rm .claude/agentvibes-muted"
    errors=$((errors+1))
elif [[ -f "$HOME/.agentvibes-muted" ]]; then
    echo "🔇 MUTED (global)"
    echo "   - Run: rm ~/.agentvibes-muted"
    errors=$((errors+1))
else
    echo "✅ Unmuted"
fi

# 4. Check Locks
echo -n "Checking Lock Files... "
LOCK_FILE="/tmp/agentvibes-audio.lock"
if [[ -f "$LOCK_FILE" ]]; then
    # Fix #5: Check if lock is stale before removing (race condition fix)
    if command -v fuser &> /dev/null; then
        if fuser "$LOCK_FILE" &> /dev/null; then
            LOCK_PID=$(fuser "$LOCK_FILE" 2>&1 | awk '{print $2}')
            echo "⚠️  LOCKED (active process PID: $LOCK_PID)"
            echo "   - Lock is held by running process, not removing"
        else
            echo "⚠️  Stale lock detected"
            echo "   - Action: Removing stale lock..."
            rm -f "$LOCK_FILE"
            echo "   - Lock removed."
        fi
    else
        # No fuser available, check lock age instead
        LOCK_AGE=$(($(date +%s) - $(stat -f %m "$LOCK_FILE" 2>/dev/null || stat -c %Y "$LOCK_FILE" 2>/dev/null || echo 0)))
        if [[ "$LOCK_AGE" -gt 300 ]]; then  # 5 minutes = likely stale
            echo "⚠️  Stale lock detected (age: ${LOCK_AGE}s)"
            rm -f "$LOCK_FILE"
            echo "   - Lock removed."
        else
            echo "⚠️  LOCKED (age: ${LOCK_AGE}s, may be active)"
        fi
    fi
else
    echo "✅ Clear"
fi

# 5. Check Voice Model
echo -n "Checking Voice Model File... "
# Fix #6: Check multiple possible paths for voice model
VOICE_FOUND=false
VOICE_PATHS=(
    "$HOME/.claude/piper-voices/${VOICE}.onnx"
    ".claude/piper-voices/${VOICE}.onnx"
    "$HOME/.claude/piper-voices/${VOICE##*-}.onnx"  # Try without prefix (e.g., kristin.onnx)
    ".claude/piper-voices/${VOICE##*-}.onnx"
)

for VOICE_PATH in "${VOICE_PATHS[@]}"; do
    if [[ -f "$VOICE_PATH" ]]; then
        SIZE=$(du -h "$VOICE_PATH" | cut -f1)
        echo "✅ Found: $VOICE_PATH ($SIZE)"
        VOICE_FOUND=true

        # Fix #7: Use realistic corruption threshold (ONNX models are typically >10MB)
        BYTES=$(wc -c < "$VOICE_PATH")
        if [[ "$BYTES" -lt 100000 ]]; then  # 100KB minimum
            echo "   ❌ CORRUPT (File too small: $BYTES bytes, expected >100KB)"
            errors=$((errors+1))
        fi
        break
    fi
done

if [[ "$VOICE_FOUND" == "false" ]]; then
    echo "❌ MISSING (checked: ${VOICE_PATHS[0]})"
    errors=$((errors+1))
fi

# 6. Audio Driver Test
echo -n "Checking Audio Output... "
if [[ "$(uname)" == "Darwin" ]]; then
    if command -v afplay &> /dev/null; then
        echo "✅ afplay available (macOS)"
        # Fix #8: Use timeout instead of manual kill to avoid zombie
        if command -v sox &> /dev/null; then
            echo "   🔊 Attempting 1s test tone..."
            if command -v timeout &> /dev/null; then
                timeout 2 sox -n -d synth 1 sine 440 gain -10 2>/dev/null || true
            elif command -v gtimeout &> /dev/null; then
                gtimeout 2 sox -n -d synth 1 sine 440 gain -10 2>/dev/null || true
            else
                # Fallback: background with proper cleanup
                sox -n -d synth 1 sine 440 gain -10 2>/dev/null &
                SOX_PID=$!
                sleep 1.5
                kill $SOX_PID 2>/dev/null || true
                wait $SOX_PID 2>/dev/null || true  # Reap zombie
            fi
        fi
    else
        echo "❌ afplay missing"
        errors=$((errors+1))
    fi
else
    # Linux
    if command -v paplay &> /dev/null || command -v aplay &> /dev/null; then
        echo "✅ Audio player available (Linux)"
    else
        echo "⚠️  No audio player found (paplay/aplay)"
    fi
fi

echo "=============================="
if [[ "$errors" -eq 0 ]]; then
    echo "✅ System Nominal. Silence may be system volume or incorrect output device."
else
    echo "❌ $errors Issues Found. Detection complete."
fi
