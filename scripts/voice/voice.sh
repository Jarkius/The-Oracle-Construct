#!/bin/bash
# ============================================================
# voice.sh - Voice CLIENT (The Mouth)
# ============================================================
#
# SHELL SAFETY: pipefail catches pipe errors, but we allow individual
# command failures (no -e) because some optional commands may fail gracefully
# Note: pipefail is bash-only; skip if running under dash/sh
(set -o pipefail 2>/dev/null) && set -o pipefail

# ============================================================
# PORTABLE PATHS - Use environment variables or sensible defaults
# ============================================================
VOICE_DIR="${VOICE_DIR:-$HOME/.claude/piper-voices}"

# Auto-detect Piper binary: env override > venv > system
if [ -n "${PIPER_BIN:-}" ]; then
    : # User override
elif [ -f "$(dirname "${BASH_SOURCE[0]}")/../../.venv/Scripts/piper.exe" ]; then
    PIPER_BIN="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/.venv/Scripts/piper.exe"
elif [ -f "$HOME/.local/bin/piper" ]; then
    PIPER_BIN="$HOME/.local/bin/piper"
elif command -v piper &>/dev/null; then
    PIPER_BIN="piper"
else
    PIPER_BIN=""
fi

# Platform detection
MATRIX_OS="unknown"
case "$(uname -s)" in
    Darwin) MATRIX_OS="macos" ;;
    MINGW*|MSYS*|CYGWIN*)
        MATRIX_OS="windows"
        # Add winget-installed tools to PATH if not already available
        for pkg_dir in "$HOME/AppData/Local/Microsoft/WinGet/Packages"/*/; do
            bin_dir=$(find "$pkg_dir" -name "bin" -type d 2>/dev/null | head -1)
            [ -n "$bin_dir" ] && export PATH="$PATH:$bin_dir"
        done
        # SoX default install location
        [ -d "/c/Program Files (x86)/sox-14-4-2" ] && export PATH="$PATH:/c/Program Files (x86)/sox-14-4-2"
        ;;
    Linux) MATRIX_OS="linux" ;;
esac

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
    $(command -v python3 2>/dev/null || command -v python 2>/dev/null || echo python3) -c "
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
MATRIX_TMPDIR="${TMPDIR:-${TEMP:-/tmp}}"
TEMP_WAV=$(mktemp "$MATRIX_TMPDIR/matrix_voice_XXXXXX.wav")
TEMP_WAV_MIXED=$(mktemp "$MATRIX_TMPDIR/matrix_voice_mixed_XXXXXX.wav")
TEMP_WAV_FX=$(mktemp "$MATRIX_TMPDIR/matrix_voice_fx_XXXXXX.wav")

# Cleanup trap - removes temp files on exit (success or failure)
cleanup_temp() {
    rm -f "$TEMP_WAV" "$TEMP_WAV_MIXED" "$TEMP_WAV_FX" 2>/dev/null
}
trap cleanup_temp EXIT

# Cross-platform audio playback
safe_play() {
    local wav_file="$1"
    if [[ "$MATRIX_OS" == "macos" ]]; then
        afplay "$wav_file"
    elif [[ "$MATRIX_OS" == "windows" ]]; then
        local win_path
        win_path=$(cygpath -w "$wav_file" 2>/dev/null || echo "$wav_file")
        powershell.exe -Command "(New-Object Media.SoundPlayer '$win_path').PlaySync()" 2>/dev/null
    elif command -v aplay &>/dev/null; then
        aplay "$wav_file" 2>/dev/null
    elif command -v paplay &>/dev/null; then
        paplay "$wav_file" 2>/dev/null
    else
        echo "⚠️  No audio player found" >&2
    fi
}

# Fallback TTS when piper fails
say_fallback() {
    local msg="$1"
    local voice="${2:-Samantha}"
    echo "⚠️  FALLBACK MODE: Piper TTS failed" >&2
    if [[ "$MATRIX_OS" == "macos" ]]; then
        say -v "$voice" "$msg" 2>/dev/null
    elif [[ "$MATRIX_OS" == "windows" ]]; then
        powershell.exe -Command "Add-Type -AssemblyName System.Speech; (New-Object System.Speech.Synthesis.SpeechSynthesizer).Speak('$msg')" 2>/dev/null
    else
        echo "   Run: .claude/hooks/bootstrap-voice.sh --force" >&2
    fi
}

if [ -z "$MESSAGE" ]; then
    echo "Usage: $0 \"Message\" [SpeakerName] --worker"
    exit 1
fi


# Map Speaker to Personality (for fallback)
CONFIG_FILE=".claude/config/voices.json"
if [ -f "$CONFIG_FILE" ]; then
    PYTHON_CMD="$(python3 --version &>/dev/null && echo python3 || echo python)"
    PARSED_DATA=$($PYTHON_CMD -c "import sys, json;
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
        safe_play "$TEMP_WAV"
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
        safe_play "$TEMP_WAV"
    else
        say_fallback "$MESSAGE" "Allison"
    fi
    exit 0
fi

# MORPHEUS
if [ "$SPEAKER" = "Morpheus" ]; then
    # joe-medium (deep commanding voice — replaces carlin-high which is not in standard Piper)
    echo "$MESSAGE" | "$PIPER_BIN" --model "$VOICE_DIR/en_US-joe-medium.onnx" --output_file "$TEMP_WAV" 2>/dev/null
    if [ -f "$TEMP_WAV" ] && [ -s "$TEMP_WAV" ]; then
        safe_play "$TEMP_WAV"
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
        safe_play "$TEMP_WAV"
    else
        say_fallback "$MESSAGE" "Samantha"
    fi
    exit 0
fi

# SYSTEM (The Matrix's own voice — KITT scanning pulse)
if [ "$SPEAKER" = "System" ]; then
    # hfc_male + Knight Rider scanning loop at 30% volume
    echo "$MESSAGE" | "$PIPER_BIN" --model "$VOICE_DIR/en_US-hfc_male-medium.onnx" --output_file "$TEMP_WAV" 2>/dev/null
    if [ -f "$TEMP_WAV" ] && [ -s "$TEMP_WAV" ]; then
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
        KITT_LOOP="$PROJECT_ROOT/.claude/audio/tracks/kitt_knight_rider_loop.mp3"
        if [ -f "$KITT_LOOP" ] && command -v ffmpeg >/dev/null 2>&1; then
            DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$TEMP_WAV" 2>/dev/null)
            ffmpeg -y -i "$TEMP_WAV" -stream_loop -1 -i "$KITT_LOOP" \
                -filter_complex "[1:a]volume=0.30[bg];[0:a][bg]amix=inputs=2:duration=first[out]" \
                -map "[out]" -t "$DURATION" "$TEMP_WAV_MIXED" 2>/dev/null
            if [ -f "$TEMP_WAV_MIXED" ] && [ -s "$TEMP_WAV_MIXED" ]; then
                safe_play "$TEMP_WAV_MIXED"
            else
                safe_play "$TEMP_WAV"
            fi
        else
            safe_play "$TEMP_WAV"
        fi
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
            TOTAL_DUR=$(awk "BEGIN{printf \"%.1f\", $DURATION + 1.5}")
            ffmpeg -y -i "$TEMP_WAV" -stream_loop -1 -i "$FLAMENCO_MUSIC" \
                -filter_complex "[1:a]volume=0.50[bg];[0:a]adelay=1500|1500[v];[v][bg]amix=inputs=2:duration=longest[out]" \
                -map "[out]" -t "$TOTAL_DUR" "$TEMP_WAV_MIXED" 2>/dev/null
            if [ -f "$TEMP_WAV_MIXED" ]; then
                safe_play "$TEMP_WAV_MIXED"
            else
                safe_play "$TEMP_WAV"
            fi
        else
            safe_play "$TEMP_WAV"
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
        safe_play "$TEMP_WAV"
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
        safe_play "$TEMP_WAV"
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
        safe_play "$TEMP_WAV"
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
        safe_play "$TEMP_WAV"
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
                safe_play "$TEMP_WAV_MIXED"
            else
                safe_play "$TEMP_WAV"
            fi
        else
            safe_play "$TEMP_WAV"
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
        # Apply bass boost (sox preferred, ffmpeg fallback)
        if command -v sox >/dev/null 2>&1; then
             sox "$TEMP_WAV" "$TEMP_WAV_FX" bass +20 2>/dev/null
             [ -f "$TEMP_WAV_FX" ] && [ -s "$TEMP_WAV_FX" ] && mv "$TEMP_WAV_FX" "$TEMP_WAV"
        elif command -v ffmpeg >/dev/null 2>&1; then
             ffmpeg -y -i "$TEMP_WAV" -af "bass=g=20:f=100" "$TEMP_WAV_FX" 2>/dev/null
             [ -f "$TEMP_WAV_FX" ] && [ -s "$TEMP_WAV_FX" ] && mv "$TEMP_WAV_FX" "$TEMP_WAV"
        fi
        # Mix with Tron synth loop at 40% volume (1.5s music intro before voice)
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
        TRON_MUSIC="$PROJECT_ROOT/.claude/audio/tracks/tron_synth_loop.mp3"
        if [ -f "$TRON_MUSIC" ]; then
            DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$TEMP_WAV" 2>/dev/null)
            TOTAL_DUR=$(awk "BEGIN{printf \"%.1f\", $DURATION + 1.5}")
            ffmpeg -y -i "$TEMP_WAV" -stream_loop -1 -i "$TRON_MUSIC" \
                -filter_complex "[1:a]volume=0.40[bg];[0:a]adelay=1500|1500[v];[v][bg]amix=inputs=2:duration=longest[out]" \
                -map "[out]" -t "$TOTAL_DUR" "$TEMP_WAV_MIXED" 2>/dev/null
            if [ -f "$TEMP_WAV_MIXED" ]; then
                safe_play "$TEMP_WAV_MIXED"
            else
                safe_play "$TEMP_WAV"
            fi
        else
            safe_play "$TEMP_WAV"
        fi
    else
        say_fallback "$MESSAGE" "Tom"
    fi
    exit 0
fi

# GENERIC FALLBACK (Using play-tts shim)
if [ -n "$VOICE_OVERRIDE" ]; then
    bash "$PLAY_TTS" "$MESSAGE" "$VOICE_OVERRIDE"
else
    bash "$PLAY_TTS" "$MESSAGE"
fi
