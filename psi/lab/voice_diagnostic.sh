#!/bin/bash

echo "🔍 Smith Audio Diagnostic v1.0"
echo "=============================="

errors=0

# 1. Check Dependencies
echo -n "Checking Piper binary... "
if command -v piper &> /dev/null; then
    echo "✅ Found ($(which piper))"
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

# 2. Check Configuration
echo -n "Checking Voice Config... "
VOICE_FILE=".claude/tts-voice.txt"
if [[ -f "$VOICE_FILE" ]]; then
    VOICE=$(cat "$VOICE_FILE")
    echo "✅ Active: $VOICE"
else
    echo "❌ Missing tts-voice.txt"
    errors=$((errors+1))
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
if [[ -f "$HOME/.agentvibes-muted" ]] || [[ -f ".claude/agentvibes-muted" ]]; then
    echo "🔇 MUTED (File detected)"
    echo "   - Run: .claude/hooks/play-tts.sh --unmute"
    errors=$((errors+1))
else
    echo "✅ Unmuted"
fi

# 4. Check Locks
echo -n "Checking Lock Files... "
if [[ -f "/tmp/agentvibes-audio.lock" ]]; then
    echo "❌ LOCKED (/tmp/agentvibes-audio.lock exists)"
    echo "   - Action: Removing stale lock..."
    rm "/tmp/agentvibes-audio.lock"
    echo "   - Lock removed."
else
    echo "✅ Clear"
fi

# 5. Check Voice Model
echo -n "Checking Voice Model File... "
# Resolve path (simplified logic for diagnostic)
VOICE_PATH="$HOME/.claude/piper-voices/$VOICE.onnx"
if [[ -f "$VOICE_PATH" ]]; then
    SIZE=$(du -h "$VOICE_PATH" | cut -f1)
    echo "✅ Found ($SIZE)"
    
    # Check for corruption (too small)
    BYTES=$(wc -c < "$VOICE_PATH")
    if [[ "$BYTES" -lt 1000 ]]; then
        echo "   ❌ CORRUPT (File too small: $BYTES bytes)"
        errors=$((errors+1))
    fi
else
    echo "❌ MISSING ($VOICE_PATH)"
     # Check local proj
    LOCAL_VOICE_PATH=".claude/piper-voices/$VOICE.onnx"
    if [[ -f "$LOCAL_VOICE_PATH" ]]; then
        echo "   ⚠️  Found in local project instead: $LOCAL_VOICE_PATH"
    else
        errors=$((errors+1))
    fi
fi

# 6. Audio Driver Test
echo -n "Checking Audio Output (afplay)... "
if command -v afplay &> /dev/null; then
    echo "✅ Available"
    # Try generating a test tone if sox exists
    if command -v sox &> /dev/null; then
        echo "   🔊 Attempting 1s test tone..."
        sox -n -d synth 1 sine 440 gain -10 &
        PID=$!
        sleep 1
        kill $PID 2>/dev/null
    fi
else
    echo "❌ afplay missing (Are you on macOS?)"
fi

echo "=============================="
if [[ "$errors" -eq 0 ]]; then
    echo "✅ System Nominal. Silence may be system volume or incorrect output device."
else
    echo "❌ $errors Issues Found. Detection complete."
fi
