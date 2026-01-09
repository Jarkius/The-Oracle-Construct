#!/bin/bash
# Voice of the Matrix (Evolved)
# Uses AgentVibes for personality-infused architecture.
# Restored from Oracle-Construct bcea289 + Architect bypass added

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
                afplay /tmp/smith_mixed.wav
                rm /tmp/smith_mixed.wav
            else
                afplay /tmp/smith_speech.wav
            fi
        else
            afplay /tmp/smith_speech.wav
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
                afplay /tmp/mainframe_mixed.wav
                rm /tmp/mainframe_mixed.wav
            else
                afplay /tmp/mainframe_speech.wav
            fi
        else
            afplay /tmp/mainframe_speech.wav
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
                afplay /tmp/tank_mixed.wav
                rm /tmp/tank_mixed.wav
            else
                afplay /tmp/tank_speech.wav
            fi
        else
            afplay /tmp/tank_speech.wav
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
        afplay /tmp/oracle_speech.wav
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
        afplay /tmp/trinity_speech.wav
        rm /tmp/trinity_speech.wav
    fi
    exit 0
fi

# SPECIAL BYPASS FOR SYSTEM (Direct Pipeline - Matrix core, SYNCHRONOUS for startup sequence)
if [ "$SPEAKER" = "System" ]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🗣️  System:"
    echo "   $MESSAGE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    # Direct piper call - hfc_male voice, SYNCHRONOUS (no &) for proper greeting sequence
    echo "$MESSAGE" | /Users/jarkius/.local/bin/piper --model /Users/jarkius/.claude/piper-voices/en_US-hfc_male-medium.onnx --output_file /tmp/system_speech.wav 2>/dev/null
    if [ -f /tmp/system_speech.wav ]; then
        afplay /tmp/system_speech.wav  # BLOCKING - ensures Matrix speaks before Oracle
        rm /tmp/system_speech.wav
    fi
    exit 0
fi

# SPECIAL BYPASS FOR ARCHITECT (Direct Pipeline - British, Formal, Commanding)
if [ "$SPEAKER" = "Architect" ]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🗣️  Architect:"
    echo "   $MESSAGE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    # Direct piper call - British Alan voice, formal delivery
    echo "$MESSAGE" | /Users/jarkius/.local/bin/piper --model /Users/jarkius/.claude/piper-voices/en_GB-alan-medium.onnx --output_file /tmp/architect_speech.wav 2>/dev/null
    if [ -f /tmp/architect_speech.wav ]; then
        afplay /tmp/architect_speech.wav
        rm /tmp/architect_speech.wav
    fi
    exit 0
fi

# GENERIC FALLBACK (for System, Scribe, Morpheus, etc.)
# 1. ALWAYS echo text to terminal (text + voice communication)
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🗣️  $SPEAKER:"
echo "   $MESSAGE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 2. Speak with voice (no personality reset - that caused voice chaos)
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
