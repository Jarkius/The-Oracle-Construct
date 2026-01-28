#!/bin/bash
# ============================================================
# voice.sh - Voice CLIENT (The Mouth)
# ============================================================
#
# SHELL SAFETY: pipefail catches pipe errors, but we allow individual
# command failures (no -e) because some optional commands may fail gracefully
set -o pipefail

# ============================================================
# PORTABLE PATHS - Use environment variables or sensible defaults
# ============================================================
PIPER_BIN="${PIPER_BIN:-$HOME/.local/bin/piper}"
VOICE_DIR="${VOICE_DIR:-$HOME/.claude/piper-voices}"

# ============================================================
#
# PURPOSE:
#   The voice system for the Matrix. Makes agents speak using
#   Piper TTS with unique voices for each agent.
#
# ARCHITECTURE:
#   ┌─────────────┐      ┌──────────────────┐      ┌───────────┐
#   │  voice.sh   │ ──── │ voice_server.py  │ ──── │ Piper TTS │
#   │  (CLIENT)   │ TCP  │ (QUEUE DAEMON)   │ call │  (AUDIO)  │
#   └─────────────┘      └──────────────────┘      └───────────┘
#
# TWO MODES:
#   1. CLIENT MODE (default):
#      - Sends JSON request to voice_server.py via TCP
#      - Server queues the request for orderly playback
#      - Usage: sh voice.sh "Message" "AgentName"
#
#   2. WORKER MODE (--worker flag):
#      - Called BY the server to actually generate/play audio
#      - Runs Piper TTS and plays the WAV file
#      - Usage: sh voice.sh "Message" "AgentName" --worker
#
# FLAGS:
#   --panic / --now  : Bypass queue, play immediately (interrupts)
#   --worker         : Server callback mode (generates audio)
#
# AGENT VOICES:
#   Oracle    → kristin (warm, wise)
#   Neo       → ryan-high (determined)
#   Trinity   → jenny (strong)
#   Morpheus  → carlin-high (deep, commanding)
#   Smith     → danny-low + bass boost + Tron music
#   Tank      → bryce + Matrix jump sound
#   Architect → alan (British, precise)
#   Mainframe → norman + Flamenco music
#   System    → hfc_male (neutral)
#   Scribe    → lessac (clear)
#
# DEPENDENCIES:
#   - Piper TTS: $PIPER_BIN (default: ~/.local/bin/piper)
#   - Voice models: $VOICE_DIR (default: ~/.claude/piper-voices/*.onnx)
#   - afplay (macOS audio player)
#   - ffmpeg (for audio mixing, optional)
#   - sox (for bass boost, optional)
#
# ============================================================

# --- SERVER CONFIGURATION ---
# The voice_server.py listens on this port
SERVER_HOST="127.0.0.1"
SERVER_PORT=6969

# --- PATHS ---
HOOKS_DIR=".claude/hooks"
PLAY_TTS="$HOOKS_DIR/play-tts.sh"        # Fallback TTS script
PERSONALITY_MGR="$HOOKS_DIR/personality-manager.sh"

# --- ARGUMENTS ---
MESSAGE="$1"                    # The text to speak
SPEAKER="${2:-System}"          # Agent name (default: System)
FLAG="$3"                       # --panic, --now, or --worker

# ============================================================
# MODE SELECTION
# ============================================================
# If --worker flag: We're being called BY the server to play audio
# Otherwise: We're a CLIENT sending request TO the server

if [ "$FLAG" == "--worker" ]; then
    # WORKER MODE: Called by voice_server.py
    # Skip to audio generation below
    :
else
    # CLIENT MODE: Send request to voice_server.py

    # Check for panic/immediate mode
    IS_PANIC="false"
    if [[ "$FLAG" == "--panic" || "$FLAG" == "--now" ]]; then
        IS_PANIC="true"
    fi

    # Escape quotes for JSON
    ESCAPED_MSG=$(echo "$MESSAGE" | sed 's/"/\\"/g')

    # Build JSON payload
    JSON_PAYLOAD="{\"text\": \"$ESCAPED_MSG\", \"speaker\": \"$SPEAKER\", \"panic\": $IS_PANIC}"

    # Send to server via TCP socket
    python3 -c "
import socket
import sys
try:
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(5)
    s.connect(('$SERVER_HOST', $SERVER_PORT))
    s.sendall('''$JSON_PAYLOAD'''.encode('utf-8'))
    s.close()
except Exception as e:
    print(f'❌ Voice Server Down: {e}', file=sys.stderr)
    sys.exit(1)
"
    exit $?
fi

# ============================================================
# WORKER MODE - AUDIO GENERATION
# ============================================================
# This section runs when called with --worker flag
# It generates audio using Piper and plays it

# Create unique temp files using mktemp (safer than $$)
TEMP_WAV=$(mktemp /tmp/matrix_voice_XXXXXX.wav)
TEMP_WAV_MIXED=$(mktemp /tmp/matrix_voice_mixed_XXXXXX.wav)
TEMP_WAV_FX=$(mktemp /tmp/matrix_voice_fx_XXXXXX.wav)

# Cleanup trap - removes temp files on exit (success or failure)
cleanup_temp() {
    rm -f "$TEMP_WAV" "$TEMP_WAV_MIXED" "$TEMP_WAV_FX" 2>/dev/null
}
trap cleanup_temp EXIT

# Wrapper for audio playback
safe_play() {
    "$@"
}

# Fallback to macOS say when piper fails
say_fallback() {
    local msg="$1"
    local voice="${2:-Samantha}"
    echo "⚠️  FALLBACK MODE: Piper TTS failed, using macOS say ($voice)"
    echo "   Run: .claude/hooks/bootstrap-voice.sh --force"
    say -v "$voice" "$msg" 2>/dev/null
}

if [ -z "$MESSAGE" ]; then
    echo "Usage: $0 \"Message\" [SpeakerName] --worker"
    exit 1
fi


# Map Speaker to Personality (for fallback)
CONFIG_FILE=".claude/config/voices.json"
if [ -f "$CONFIG_FILE" ]; then
    PARSED_DATA=$(python3 -c "import sys, json;
try:
    data = json.load(open('$CONFIG_FILE'))
    agent = data.get('$SPEAKER', data.get('System'))
    print(f\"{agent.get('personality')}|{agent.get('voice')}\")
except:
    print('default||')
")
    IFS='|' read -r PERSONALITY VOICE_OVERRIDE <<< "$PARSED_DATA"
else
    PERSONALITY="default"
    VOICE_OVERRIDE=""
fi

# Print Banner
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🗣️  $SPEAKER:"
echo "   $MESSAGE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# --- AGENT SPECIFIC LOGIC (BLOCKING) ---

# NEO
if [ "$SPEAKER" = "Neo" ]; then
    # ryan-high
    echo "$MESSAGE" | "$PIPER_BIN" --model "$VOICE_DIR/en_US-ryan-high.onnx" --output_file "$TEMP_WAV" 2>/dev/null
    if [ -f "$TEMP_WAV" ] && [ -s "$TEMP_WAV" ]; then
        safe_play afplay "$TEMP_WAV"
    else
        say_fallback "$MESSAGE" "Alex"
    fi
    exit 0
fi

# TRINITY
if [ "$SPEAKER" = "Trinity" ]; then
    # jenny
    echo "$MESSAGE" | "$PIPER_BIN" --model "$VOICE_DIR/jenny.onnx" --output_file "$TEMP_WAV" 2>/dev/null
    if [ -f "$TEMP_WAV" ] && [ -s "$TEMP_WAV" ]; then
        safe_play afplay "$TEMP_WAV"
    else
        say_fallback "$MESSAGE" "Allison"
    fi
    exit 0
fi

# MORPHEUS
if [ "$SPEAKER" = "Morpheus" ]; then
    # carlin-high (Original Approved Voice)
    echo "$MESSAGE" | "$PIPER_BIN" --model "$VOICE_DIR/en_US-carlin-high.onnx" --output_file "$TEMP_WAV" 2>/dev/null
    if [ -f "$TEMP_WAV" ] && [ -s "$TEMP_WAV" ]; then
        safe_play afplay "$TEMP_WAV"
    else
        say_fallback "$MESSAGE" "Daniel"
    fi
    exit 0
fi

# ORACLE
if [ "$SPEAKER" = "Oracle" ]; then
    # kristin (Official Voice)
    echo "$MESSAGE" | "$PIPER_BIN" --model "$VOICE_DIR/en_US-kristin-medium.onnx" --output_file "$TEMP_WAV" 2>/dev/null
    if [ -f "$TEMP_WAV" ] && [ -s "$TEMP_WAV" ]; then
        safe_play afplay "$TEMP_WAV"
    else
        say_fallback "$MESSAGE" "Samantha"
    fi
    exit 0
fi

# SYSTEM
if [ "$SPEAKER" = "System" ]; then
    # hfc_male
    echo "$MESSAGE" | "$PIPER_BIN" --model "$VOICE_DIR/en_US-hfc_male-medium.onnx" --output_file "$TEMP_WAV" 2>/dev/null
    if [ -f "$TEMP_WAV" ] && [ -s "$TEMP_WAV" ]; then
        safe_play afplay "$TEMP_WAV"
    else
        say_fallback "$MESSAGE" "Tom"
    fi
    exit 0
fi

# MAINFRAME
if [ "$SPEAKER" = "Mainframe" ]; then
    # norman (Official Voice)
    echo "$MESSAGE" | "$PIPER_BIN" --model "$VOICE_DIR/en_US-norman-medium.onnx" --output_file "$TEMP_WAV" 2>/dev/null
    if [ -f "$TEMP_WAV" ] && [ -s "$TEMP_WAV" ]; then
        # Mix with Flamenco background music at 50% volume (1.5s music intro)
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
        FLAMENCO_MUSIC="$PROJECT_ROOT/.claude/audio/tracks/agentvibes_soft_flamenco_loop.mp3"
        if [ -f "$FLAMENCO_MUSIC" ]; then
            DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$TEMP_WAV" 2>/dev/null)
            TOTAL_DUR=$(echo "$DURATION + 1.5" | bc)
            ffmpeg -y -i "$TEMP_WAV" -stream_loop -1 -i "$FLAMENCO_MUSIC" \
                -filter_complex "[1:a]volume=0.50[bg];[0:a]adelay=1500|1500[v];[v][bg]amix=inputs=2:duration=longest[out]" \
                -map "[out]" -t "$TOTAL_DUR" "$TEMP_WAV_MIXED" 2>/dev/null
            if [ -f "$TEMP_WAV_MIXED" ]; then
                safe_play afplay "$TEMP_WAV_MIXED"
            else
                safe_play afplay "$TEMP_WAV"
            fi
        else
            safe_play afplay "$TEMP_WAV"
        fi
    else
        say_fallback "$MESSAGE" "Daniel"
    fi
    exit 0
fi

# SCRIBE
if [ "$SPEAKER" = "Scribe" ]; then
    # lessac (Official Voice)
    echo "$MESSAGE" | "$PIPER_BIN" --model "$VOICE_DIR/en_US-lessac-medium.onnx" --output_file "$TEMP_WAV" 2>/dev/null
    if [ -f "$TEMP_WAV" ] && [ -s "$TEMP_WAV" ]; then
        safe_play afplay "$TEMP_WAV"
    else
        say_fallback "$MESSAGE" "Samantha"
    fi
    exit 0
fi

# WOMAN IN RED
if [ "$SPEAKER" = "Woman in Red" ]; then
    # jenny (Official Voice)
    echo "$MESSAGE" | "$PIPER_BIN" --model "$VOICE_DIR/jenny.onnx" --output_file "$TEMP_WAV" 2>/dev/null
    if [ -f "$TEMP_WAV" ] && [ -s "$TEMP_WAV" ]; then
        safe_play afplay "$TEMP_WAV"
    else
        say_fallback "$MESSAGE" "Allison"
    fi
    exit 0
fi

# TRUMP
if [ "$SPEAKER" = "Trump" ]; then
    # trump-high (Official Voice)
    echo "$MESSAGE" | "$PIPER_BIN" --model "$VOICE_DIR/en_US-trump-high.onnx" --output_file "$TEMP_WAV" 2>/dev/null
    if [ -f "$TEMP_WAV" ] && [ -s "$TEMP_WAV" ]; then
        safe_play afplay "$TEMP_WAV"
    else
        say_fallback "$MESSAGE" "Fred"
    fi
    exit 0
fi

# ARCHITECT
if [ "$SPEAKER" = "Architect" ]; then
    # alan
    echo "$MESSAGE" | "$PIPER_BIN" --model "$VOICE_DIR/en_GB-alan-medium.onnx" --output_file "$TEMP_WAV" 2>/dev/null
    if [ -f "$TEMP_WAV" ] && [ -s "$TEMP_WAV" ]; then
        safe_play afplay "$TEMP_WAV"
    else
        say_fallback "$MESSAGE" "Daniel"
    fi
    exit 0
fi

# TANK (Complex Mix)
if [ "$SPEAKER" = "Tank" ]; then
    # bryce medium (Official Voice)
    echo "$MESSAGE" | "$PIPER_BIN" --model "$VOICE_DIR/en_US-bryce-medium.onnx" --output_file "$TEMP_WAV" 2>/dev/null
    if [ -f "$TEMP_WAV" ] && [ -s "$TEMP_WAV" ]; then
        # Mix with Matrix Jump sound effect at 40% volume
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
        JUMP_SOUND="$PROJECT_ROOT/.claude/audio/tracks/matrix_jump_sound.mp3"
        if [ -f "$JUMP_SOUND" ]; then
            DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$TEMP_WAV" 2>/dev/null)
            ffmpeg -y -i "$TEMP_WAV" -stream_loop -1 -i "$JUMP_SOUND" \
                -filter_complex "[1:a]volume=0.40[bg];[0:a][bg]amix=inputs=2:duration=first[out]" \
                -map "[out]" -t "$DURATION" "$TEMP_WAV_MIXED" 2>/dev/null
            if [ -f "$TEMP_WAV_MIXED" ]; then
                safe_play afplay "$TEMP_WAV_MIXED"
            else
                safe_play afplay "$TEMP_WAV"
            fi
        else
            safe_play afplay "$TEMP_WAV"
        fi
    else
        say_fallback "$MESSAGE" "Alex"
    fi
    exit 0
fi

# SMITH (Complex Mix)
if [ "$SPEAKER" = "Smith" ]; then
    # danny low slow - the calculating villain
    echo "$MESSAGE" | "$PIPER_BIN" --model "$VOICE_DIR/en_US-danny-low.onnx" --length-scale 1.8 --output_file "$TEMP_WAV" 2>/dev/null
    if [ -f "$TEMP_WAV" ] && [ -s "$TEMP_WAV" ]; then
        # Apply bass boost if sox exists
        if command -v sox >/dev/null 2>&1; then
             sox "$TEMP_WAV" "$TEMP_WAV_FX" bass +20 2>/dev/null
             mv "$TEMP_WAV_FX" "$TEMP_WAV"
        fi
        # Mix with Tron synth loop at 40% volume (1.5s music intro before voice)
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
        TRON_MUSIC="$PROJECT_ROOT/.claude/audio/tracks/tron_synth_loop.mp3"
        if [ -f "$TRON_MUSIC" ]; then
            DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$TEMP_WAV" 2>/dev/null)
            TOTAL_DUR=$(echo "$DURATION + 1.5" | bc)
            ffmpeg -y -i "$TEMP_WAV" -stream_loop -1 -i "$TRON_MUSIC" \
                -filter_complex "[1:a]volume=0.40[bg];[0:a]adelay=1500|1500[v];[v][bg]amix=inputs=2:duration=longest[out]" \
                -map "[out]" -t "$TOTAL_DUR" "$TEMP_WAV_MIXED" 2>/dev/null
            if [ -f "$TEMP_WAV_MIXED" ]; then
                safe_play afplay "$TEMP_WAV_MIXED"
            else
                safe_play afplay "$TEMP_WAV"
            fi
        else
            safe_play afplay "$TEMP_WAV"
        fi
    else
        say_fallback "$MESSAGE" "Tom"
    fi
    exit 0
fi

# GENERIC FALLBACK (Using play-tts shim)
if [ -n "$VOICE_OVERRIDE" ]; then
    safe_play bash "$PLAY_TTS" "$MESSAGE" "$VOICE_OVERRIDE"
else
    safe_play bash "$PLAY_TTS" "$MESSAGE"
fi
