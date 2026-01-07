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

# Map Speaker to Personality & Voice (Piper Upgrade)
# Voices: kristin (US Female), jenny (Irish Female), 16Speakers (US/UK Male/Female)
PERSONALITY="default"
VOICE_OVERRIDE=""

case "$SPEAKER" in
    "Oracle")
        PERSONALITY="wise"
        VOICE_OVERRIDE="kristin"
        ;;
    "Smith")
        PERSONALITY="sarcastic"
        # Using Alan (British) for distinct, sophisticated/evil tone
        VOICE_OVERRIDE="en_GB-alan-medium"
        ;;
    "Neo")
        PERSONALITY="focused"
        # Using Ryan Low (Warm/Deep Male)
        VOICE_OVERRIDE="en_US-ryan-low"
        ;;
    "Trinity"|"Woman in Red")
        PERSONALITY="pleasing" 
        VOICE_OVERRIDE="jenny"
        ;;
    "Morpheus")
        PERSONALITY="wise"
        # Using George Carlin (Cynical/Wise)
        VOICE_OVERRIDE="en_US-carlin-high"
        ;;
    "Tank")
        PERSONALITY="excited"
        # Using Ryan (Standard Male) - Effects will distinguish him from Neo
        VOICE_OVERRIDE="en_US-ryan-medium"
        ;;
    "Architect"|"Trump")
        PERSONALITY="commanding"
        # Using Trump (High Quality)
        VOICE_OVERRIDE="en_US-trump-high"
        ;;
    *)
        PERSONALITY="default"
        ;;
esac

# SPECIAL BYPASS FOR NEO (Direct macOS Nathan)
if [ "$SPEAKER" = "Neo" ]; then
    echo "🔊 NEO (Native): $MESSAGE"
    /usr/bin/say -v Nathan -r 180 "$MESSAGE"
    exit 0
fi

# SPECIAL BYPASS FOR SMITH (Direct Pipeline) - Moved to top to avoid hangs
if [ "$SPEAKER" = "Smith" ]; then
    echo "🔊 SMITH (Direct): $MESSAGE"
    echo "$MESSAGE" | /Users/jarkius/.local/bin/piper --model /Users/jarkius/.claude/piper-voices/en_GB-alan-medium.onnx --output_file /tmp/smith_speech.wav
    if [ -f /tmp/smith_speech.wav ]; then
        # Apply Bass Boost manually (since we bypass the main processor)
        if command -v sox >/dev/null 2>&1; then
             sox /tmp/smith_speech.wav /tmp/smith_speech_fx.wav bass +10
             mv /tmp/smith_speech_fx.wav /tmp/smith_speech.wav
        fi
        afplay /tmp/smith_speech.wav
        rm /tmp/smith_speech.wav
    fi
    exit 0
fi

# 1. Set Personality
bash "$PERSONALITY_MGR" set "$PERSONALITY" > /dev/null 2>&1

# 2. Speak
if [ -n "$VOICE_OVERRIDE" ]; then
    # Select voice (using override or default)
    
    # Export Agent Name for audio-processor context
    export AGENTVIBES_AGENT_NAME="$SPEAKER"

    # Play TTS (Hybrid Provider Support)
    if [ "$PROVIDER_OVERRIDE" = "macos" ]; then
        # Direct fallback to macOS say for specific characters
        echo "DEBUG: Using MacOS Native Provider for $VOICE_OVERRIDE"
        /usr/bin/say -v "$VOICE_OVERRIDE" "🔊 $SPEAKER: $MESSAGE"
    else
        # Default to AgentVibes/Piper
        bash "$PLAY_TTS" "🔊 $SPEAKER: $MESSAGE" "$VOICE_OVERRIDE"
    fi
else
    bash "$PLAY_TTS" "🔊 $SPEAKER: $MESSAGE"
fi
