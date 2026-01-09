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

# Function to acquire lock
acquire_lock() {
    local TIMEOUT=30 # Seconds to wait before forcing
    local COUNT=0
    while ! shlock -f "$LOCK_FILE" -p $$; do
        sleep 0.1
        COUNT=$((COUNT + 1))
        # If waiting too long (3s), check if lock is stale mechanically or just force it?
        # shlock -p checks for PID existence, so stale locks from crashed processes are handled.
        # This timeout is just for blocked queue.
        if [ "$COUNT" -ge "$((TIMEOUT * 10))" ]; then
             # Break lock if stuck too long? Or just proceed?
             # Let's just proceed to avoid hanging forever.
             break
        fi
    done
}

# Function to release lock
release_lock() {
    rm -f "$LOCK_FILE"
}

# Function to play audio safely (Queued)
safe_play() {
    local AUDIO_FILE="$1"
    local CMD="$2" # Optional command (defaults to afplay)
    
    if [ -z "$CMD" ]; then
        if [ "$(uname)" = "Darwin" ]; then
            CMD="afplay"
        else
            CMD="aplay"
        fi
    fi

    # QUEUED EXECUTION
    acquire_lock
    if [ -n "$AUDIO_FILE" ] && [ -f "$AUDIO_FILE" ]; then
         $CMD "$AUDIO_FILE"
    fi
    release_lock
}

# Function to speak text safely (Queued)
safe_speak() {
    local OPT_VOICE="$1"
    local OPT_TEXT="$2"
    
    # QUEUED EXECUTION
    acquire_lock
    /usr/bin/say -v "$OPT_VOICE" "$OPT_TEXT"
    release_lock
}

# Function to handle AgentVibes Generate-Then-Play
safe_play_agentvibes() {
    local MSG="$1"
    local VOICE="$2"
    
    # 1. Generate (No Playback) - run in subshell to keep env clean
    local OUTPUT
    if [ -n "$VOICE" ]; then
        OUTPUT=$(export AGENTVIBES_NO_PLAYBACK=true; bash "$PLAY_TTS" "$MSG" "$VOICE")
    else
        OUTPUT=$(export AGENTVIBES_NO_PLAYBACK=true; bash "$PLAY_TTS" "$MSG")
    fi
    
    # 2. Parse filename (handle ANSI color codes if any, though AgentVibes usually clear)
    # Extract path after "Saved to: "
    local FILE=$(echo "$OUTPUT" | grep "Saved to:" | sed 's/.*Saved to: //')
    
    # 3. Play safely
    if [ -n "$FILE" ] && [ -f "$FILE" ]; then
        safe_play "$FILE"
    else
        # Fallback if generation failed or silent
        echo "$OUTPUT" # Show error
    fi
}

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
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    safe_speak "$MACOS_FALLBACK" "$MESSAGE"
    exit 0
fi

# SPECIAL BYPASS FOR SMITH (Direct Pipeline - Slow, Menacing + Tron Synth)
if [ "$SPEAKER" = "Smith" ]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🗣️  Smith:"
    echo "   $MESSAGE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    # --length-scale 1.3 = 30% slower (deliberate, menacing delivery)
    echo "$MESSAGE" | /Users/jarkius/.local/bin/piper --model /Users/jarkius/.claude/piper-voices/en_US-danny-low.onnx --length-scale 1.3 --output_file /tmp/smith_speech.wav 2>/dev/null
    if [ -f /tmp/smith_speech.wav ]; then
        # Apply Bass Boost for menacing depth
        if command -v sox >/dev/null 2>&1; then
             sox /tmp/smith_speech.wav /tmp/smith_speech_fx.wav bass +10 2>/dev/null
             mv /tmp/smith_speech_fx.wav /tmp/smith_speech.wav
        fi
        # Mix with Tron synth loop at 40% volume (1.5s music intro before voice)
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
        TRON_MUSIC="$PROJECT_ROOT/.claude/audio/tracks/tron_synth_loop.mp3"
        if [ -f "$TRON_MUSIC" ]; then
            DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 /tmp/smith_speech.wav 2>/dev/null)
            TOTAL_DUR=$(echo "$DURATION + 1.5" | bc)
            ffmpeg -y -i /tmp/smith_speech.wav -stream_loop -1 -i "$TRON_MUSIC" \
                -filter_complex "[1:a]volume=0.40[bg];[0:a]adelay=1500|1500[v];[v][bg]amix=inputs=2:duration=longest[out]" \
                -map "[out]" -t "$TOTAL_DUR" /tmp/smith_mixed.wav 2>/dev/null
            if [ -f /tmp/smith_mixed.wav ]; then
                safe_play /tmp/smith_mixed.wav
                rm /tmp/smith_mixed.wav
            else
                safe_play /tmp/smith_speech.wav
            fi
        else
            safe_play /tmp/smith_speech.wav
        fi
        rm -f /tmp/smith_speech.wav
    fi
    exit 0
fi

# SPECIAL BYPASS FOR MAINFRAME (Direct Pipeline + Flamenco Background Music)
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
        # Mix with Flamenco background music at 50% volume (1.5s music intro)
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
        FLAMENCO_MUSIC="$PROJECT_ROOT/.claude/audio/tracks/agentvibes_soft_flamenco_loop.mp3"
        if [ -f "$FLAMENCO_MUSIC" ]; then
            DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 /tmp/mainframe_speech.wav 2>/dev/null)
            TOTAL_DUR=$(echo "$DURATION + 1.5" | bc)
            ffmpeg -y -i /tmp/mainframe_speech.wav -stream_loop -1 -i "$FLAMENCO_MUSIC" \
                -filter_complex "[1:a]volume=0.50[bg];[0:a]adelay=1500|1500[v];[v][bg]amix=inputs=2:duration=longest[out]" \
                -map "[out]" -t "$TOTAL_DUR" /tmp/mainframe_mixed.wav 2>/dev/null
            if [ -f /tmp/mainframe_mixed.wav ]; then
                safe_play /tmp/mainframe_mixed.wav
                rm /tmp/mainframe_mixed.wav
            else
                safe_play /tmp/mainframe_speech.wav
            fi
        else
            safe_play /tmp/mainframe_speech.wav
        fi
        rm -f /tmp/mainframe_speech.wav
    fi
    exit 0
fi

# SPECIAL BYPASS FOR TANK (Direct Pipeline - FAST + Jump Sound Effect)
if [ "$SPEAKER" = "Tank" ]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🗣️  Tank:"
    echo "   $MESSAGE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    # Use direct piper call for maximum clarity (raw model output)
    # --length-scale 0.85 = 15% faster (energetic operator!)
    echo "$MESSAGE" | /Users/jarkius/.local/bin/piper --model /Users/jarkius/.claude/piper-voices/en_US-bryce-medium.onnx --length-scale 0.85 --output_file /tmp/tank_speech.wav 2>/dev/null
    if [ -f /tmp/tank_speech.wav ]; then
        # Mix with Matrix Jump sound effect at 40% volume
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
        JUMP_SOUND="$PROJECT_ROOT/.claude/audio/tracks/matrix_jump_sound.mp3"
        if [ -f "$JUMP_SOUND" ]; then
            DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 /tmp/tank_speech.wav 2>/dev/null)
            ffmpeg -y -i /tmp/tank_speech.wav -stream_loop -1 -i "$JUMP_SOUND" \
                -filter_complex "[1:a]volume=0.40[bg];[0:a][bg]amix=inputs=2:duration=first[out]" \
                -map "[out]" -t "$DURATION" /tmp/tank_mixed.wav 2>/dev/null
            if [ -f /tmp/tank_mixed.wav ]; then
                safe_play /tmp/tank_mixed.wav
                rm /tmp/tank_mixed.wav
            else
                safe_play /tmp/tank_speech.wav
            fi
        else
            safe_play /tmp/tank_speech.wav
        fi
        rm -f /tmp/tank_speech.wav
    fi
    exit 0
fi

# SPECIAL BYPASS FOR ORACLE (Direct Pipeline - Calm, wise, 60yo woman)
if [ "$SPEAKER" = "Oracle" ]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🗣️  Oracle:"
    echo "   $MESSAGE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    # Direct piper call - slow, calm delivery (length-scale 1.15 = 15% slower)
    echo "$MESSAGE" | /Users/jarkius/.local/bin/piper --model /Users/jarkius/.claude/piper-voices/en_US-kristin-medium.onnx --length-scale 1.15 --output_file /tmp/oracle_speech.wav 2>/dev/null
    if [ -f /tmp/oracle_speech.wav ]; then
        safe_play /tmp/oracle_speech.wav
        rm /tmp/oracle_speech.wav
    fi
    exit 0
fi

# SPECIAL BYPASS FOR TRINITY (Direct Pipeline - Clear, confident)
if [ "$SPEAKER" = "Trinity" ]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🗣️  Trinity:"
    echo "   $MESSAGE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    # Direct piper call for clarity (jenny voice)
    echo "$MESSAGE" | /Users/jarkius/.local/bin/piper --model /Users/jarkius/.claude/piper-voices/jenny.onnx --output_file /tmp/trinity_speech.wav 2>/dev/null
    if [ -f /tmp/trinity_speech.wav ]; then
        safe_play /tmp/trinity_speech.wav
        rm /tmp/trinity_speech.wav
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
        safe_speak "$VOICE_OVERRIDE" "$MESSAGE"
    else
        # Default to AgentVibes/Piper (Queued via Generate-Then-Play)
        safe_play_agentvibes "$MESSAGE" "$VOICE_OVERRIDE"
    fi
else
    safe_play_agentvibes "$MESSAGE"
fi
