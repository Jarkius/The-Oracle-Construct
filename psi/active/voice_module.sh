#!/bin/bash
# Voice of the Matrix (Evolved)
# Uses AgentVibes for personality-infused architecture.

# Hooks Path
HOOKS_DIR=".claude/hooks"
PLAY_TTS="$HOOKS_DIR/play-tts.sh"
PERSONALITY_MGR="$HOOKS_DIR/personality-manager.sh"

# Input
MESSAGE="$1"
SPEAKER="${2:-System}"

if [ -z "$MESSAGE" ]; then
    echo "Usage: $0 \"Message\" [SpeakerName]"
    exit 1
fi

# Map Speaker to Personality & Voice (Portable Config)
CONFIG_FILE=".claude/config/voices.json"

if [ -f "$CONFIG_FILE" ]; then
    # Parse JSON using python3 for reliability
    PARSED_DATA=$(python3 -c "import sys, json; 
try:
    data = json.load(open('$CONFIG_FILE'))
    agent = data.get('$SPEAKER', data.get('System'))
    print(f\"{agent.get('personality')}|{agent.get('voice')}|{agent.get('fallback_macos', '')}\")
except:
    print('default||')
")
    IFS='|' read -r PERSONALITY VOICE_OVERRIDE MACOS_FALLBACK <<< "$PARSED_DATA"
else
    # Fallback if config matches
    PERSONALITY="default"
    VOICE_OVERRIDE=""
    MACOS_FALLBACK=""
fi

# SPECIAL BYPASS FOR NEO (Direct macOS Nathan)
if [ "$SPEAKER" = "Neo" ] && [ -n "$MACOS_FALLBACK" ] && [ "$(uname)" = "Darwin" ]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🗣️  Neo:"
    echo "   $MESSAGE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    /usr/bin/say -v "$MACOS_FALLBACK" -r 180 "$MESSAGE"
    exit 0
fi

# SPECIAL BYPASS FOR SMITH (Direct Pipeline)
if [ "$SPEAKER" = "Smith" ]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🗣️  Smith:"
    echo "   $MESSAGE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "$MESSAGE" | /Users/jarkius/.local/bin/piper --model /Users/jarkius/.claude/piper-voices/en_US-danny-low.onnx --output_file /tmp/smith_speech.wav 2>/dev/null
    if [ -f /tmp/smith_speech.wav ]; then
        # Apply Bass Boost manually (since we bypass the main processor)
        if command -v sox >/dev/null 2>&1; then
             sox /tmp/smith_speech.wav /tmp/smith_speech_fx.wav bass +10 2>/dev/null
             mv /tmp/smith_speech_fx.wav /tmp/smith_speech.wav
        fi
        afplay /tmp/smith_speech.wav
        rm /tmp/smith_speech.wav
    fi
    exit 0
fi

# SPECIAL BYPASS FOR MAINFRAME (Direct Pipeline - No Processor)
if [ "$SPEAKER" = "Mainframe" ]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🗣️  Mainframe:"
    echo "   $MESSAGE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    # Use direct piper call for maximum clarity (raw model output)
    echo "$MESSAGE" | /Users/jarkius/.local/bin/piper --model /Users/jarkius/.claude/piper-voices/en_US-norman-medium.onnx --output_file /tmp/mainframe_speech.wav 2>/dev/null
    if [ -f /tmp/mainframe_speech.wav ]; then
        afplay /tmp/mainframe_speech.wav
        rm /tmp/mainframe_speech.wav
    fi
    exit 0
fi


# 1. Set Personality
bash "$PERSONALITY_MGR" set "$PERSONALITY" > /dev/null 2>&1

# 2. ALWAYS echo text to terminal (text + voice communication)
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🗣️  $SPEAKER:"
echo "   $MESSAGE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 3. Speak with voice
if [ -n "$VOICE_OVERRIDE" ]; then
    # Export Agent Name for audio-processor context
    export AGENTVIBES_AGENT_NAME="$SPEAKER"

    # Play TTS (Hybrid Provider Support)
    if [ "$PROVIDER_OVERRIDE" = "macos" ]; then
        /usr/bin/say -v "$VOICE_OVERRIDE" "$MESSAGE"
    else
        # Default to AgentVibes/Piper
        bash "$PLAY_TTS" "$MESSAGE" "$VOICE_OVERRIDE"
    fi
else
    bash "$PLAY_TTS" "$MESSAGE"
fi
