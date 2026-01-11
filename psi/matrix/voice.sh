#!/bin/bash
# ============================================================
# voice.sh - Voice CLIENT (The Mouth)
# ============================================================
# Role: Sends voice requests to the queue server
# Pair: voice_server.py (the queue daemon that plays audio)
#
# Usage: sh psi/matrix/voice.sh "Message" "AgentName"
#
# Architecture:
#   voice.sh (CLIENT) --> voice_server.py (SERVER) --> Piper TTS
# ============================================================

# Server Configuration
SERVER_HOST="127.0.0.1"
SERVER_PORT=6969

# Hooks Path
HOOKS_DIR=".claude/hooks"
PLAY_TTS="$HOOKS_DIR/play-tts.sh"
PERSONALITY_MGR="$HOOKS_DIR/personality-manager.sh"

# Arguments
MESSAGE="$1"
SPEAKER="${2:-System}"
FLAG="$3"  # --panic, --now, or --worker

# --- MODE SELECTION ---
if [ "$FLAG" == "--worker" ]; then
    # WORKER MODE: Called by the Server.
    # Proceed to audio generation.
    :
else
    # CLIENT MODE: Send to Python Server.
    IS_PANIC="false"
    if [[ "$FLAG" == "--panic" || "$FLAG" == "--now" ]]; then
        IS_PANIC="true"
    fi

    # Escape message for JSON
    ESCAPED_MSG=$(echo "$MESSAGE" | sed 's/"/\\"/g')
    
    # JSON Payload
    JSON_PAYLOAD="{\"text\": \"$ESCAPED_MSG\", \"speaker\": \"$SPEAKER\", \"panic\": $IS_PANIC}"
    
    # Send to Server
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

# --- WORKER MODE LOGIC ---

safe_play() {
    "$@"
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
    echo "$MESSAGE" | /Users/jarkius/.local/bin/piper --model /Users/jarkius/.claude/piper-voices/en_US-ryan-high.onnx --output_file /tmp/neo_$$.wav 2>/dev/null
    if [ -f /tmp/neo_$$.wav ]; then
        safe_play afplay /tmp/neo_$$.wav
        rm /tmp/neo_$$.wav
    fi
    exit 0
fi

# TRINITY
if [ "$SPEAKER" = "Trinity" ]; then
    # jenny
    echo "$MESSAGE" | /Users/jarkius/.local/bin/piper --model /Users/jarkius/.claude/piper-voices/jenny.onnx --output_file /tmp/trinity_$$.wav 2>/dev/null
    if [ -f /tmp/trinity_$$.wav ]; then
        safe_play afplay /tmp/trinity_$$.wav
        rm /tmp/trinity_$$.wav
    fi
    exit 0
fi

# MORPHEUS
if [ "$SPEAKER" = "Morpheus" ]; then
    # carlin-high (Original Approved Voice)
    echo "$MESSAGE" | /Users/jarkius/.local/bin/piper --model /Users/jarkius/.claude/piper-voices/en_US-carlin-high.onnx --output_file /tmp/morpheus_$$.wav 2>/dev/null
    if [ -f /tmp/morpheus_$$.wav ]; then
        safe_play afplay /tmp/morpheus_$$.wav
        rm /tmp/morpheus_$$.wav
    fi
    exit 0
fi

# ORACLE
if [ "$SPEAKER" = "Oracle" ]; then
    # kristin (Official Voice)
    echo "$MESSAGE" | /Users/jarkius/.local/bin/piper --model /Users/jarkius/.claude/piper-voices/en_US-kristin-medium.onnx --output_file /tmp/oracle_$$.wav 2>/dev/null
    if [ -f /tmp/oracle_$$.wav ]; then
        safe_play afplay /tmp/oracle_$$.wav
        rm /tmp/oracle_$$.wav
    fi
    exit 0
fi

# SYSTEM
if [ "$SPEAKER" = "System" ]; then
    # hfc_male
    echo "$MESSAGE" | /Users/jarkius/.local/bin/piper --model /Users/jarkius/.claude/piper-voices/en_US-hfc_male-medium.onnx --output_file /tmp/system_$$.wav 2>/dev/null
    if [ -f /tmp/system_$$.wav ]; then
        safe_play afplay /tmp/system_$$.wav
        rm /tmp/system_$$.wav
    fi
    exit 0
fi

# MAINFRAME
if [ "$SPEAKER" = "Mainframe" ]; then
    # norman (Official Voice)
    echo "$MESSAGE" | /Users/jarkius/.local/bin/piper --model /Users/jarkius/.claude/piper-voices/en_US-norman-medium.onnx --output_file /tmp/mainframe_$$.wav 2>/dev/null
    if [ -f /tmp/mainframe_$$.wav ]; then
        # Mix with Flamenco background music at 50% volume (1.5s music intro)
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
        FLAMENCO_MUSIC="$PROJECT_ROOT/.claude/audio/tracks/agentvibes_soft_flamenco_loop.mp3"
        if [ -f "$FLAMENCO_MUSIC" ]; then
            DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 /tmp/mainframe_$$.wav 2>/dev/null)
            TOTAL_DUR=$(echo "$DURATION + 1.5" | bc)
            ffmpeg -y -i /tmp/mainframe_$$.wav -stream_loop -1 -i "$FLAMENCO_MUSIC" \
                -filter_complex "[1:a]volume=0.50[bg];[0:a]adelay=1500|1500[v];[v][bg]amix=inputs=2:duration=longest[out]" \
                -map "[out]" -t "$TOTAL_DUR" /tmp/mainframe_mixed_$$.wav 2>/dev/null
            if [ -f /tmp/mainframe_mixed_$$.wav ]; then
                safe_play afplay /tmp/mainframe_mixed_$$.wav
                rm /tmp/mainframe_mixed_$$.wav
            else
                safe_play afplay /tmp/mainframe_$$.wav
            fi
        else
            safe_play afplay /tmp/mainframe_$$.wav
        fi
        rm /tmp/mainframe_$$.wav
    fi
    exit 0
fi

# SCRIBE
if [ "$SPEAKER" = "Scribe" ]; then
    # lessac (Official Voice)
    echo "$MESSAGE" | /Users/jarkius/.local/bin/piper --model /Users/jarkius/.claude/piper-voices/en_US-lessac-medium.onnx --output_file /tmp/scribe_$$.wav 2>/dev/null
    if [ -f /tmp/scribe_$$.wav ]; then
        safe_play afplay /tmp/scribe_$$.wav
        rm /tmp/scribe_$$.wav
    fi
    exit 0
fi

# WOMAN IN RED
if [ "$SPEAKER" = "Woman in Red" ]; then
    # jenny (Official Voice)
    echo "$MESSAGE" | /Users/jarkius/.local/bin/piper --model /Users/jarkius/.claude/piper-voices/jenny.onnx --output_file /tmp/womaninred_$$.wav 2>/dev/null
    if [ -f /tmp/womaninred_$$.wav ]; then
        safe_play afplay /tmp/womaninred_$$.wav
        rm /tmp/womaninred_$$.wav
    fi
    exit 0
fi

# TRUMP
if [ "$SPEAKER" = "Trump" ]; then
    # trump-high (Official Voice)
    echo "$MESSAGE" | /Users/jarkius/.local/bin/piper --model /Users/jarkius/.claude/piper-voices/en_US-trump-high.onnx --output_file /tmp/trump_$$.wav 2>/dev/null
    if [ -f /tmp/trump_$$.wav ]; then
        safe_play afplay /tmp/trump_$$.wav
        rm /tmp/trump_$$.wav
    fi
    exit 0
fi

# ARCHITECT
if [ "$SPEAKER" = "Architect" ]; then
    # alan
    echo "$MESSAGE" | /Users/jarkius/.local/bin/piper --model /Users/jarkius/.claude/piper-voices/en_GB-alan-medium.onnx --output_file /tmp/architect_$$.wav 2>/dev/null
    if [ -f /tmp/architect_$$.wav ]; then
        safe_play afplay /tmp/architect_$$.wav
        rm /tmp/architect_$$.wav
    fi
    exit 0
fi

# TANK (Complex Mix)
if [ "$SPEAKER" = "Tank" ]; then
    # bryce medium (Official Voice)
    echo "$MESSAGE" | /Users/jarkius/.local/bin/piper --model /Users/jarkius/.claude/piper-voices/en_US-bryce-medium.onnx --output_file /tmp/tank_$$.wav 2>/dev/null
    if [ -f /tmp/tank_$$.wav ]; then
        # Mix with Matrix Jump sound effect at 40% volume
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
        JUMP_SOUND="$PROJECT_ROOT/.claude/audio/tracks/matrix_jump_sound.mp3"
        if [ -f "$JUMP_SOUND" ]; then
            DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 /tmp/tank_$$.wav 2>/dev/null)
            ffmpeg -y -i /tmp/tank_$$.wav -stream_loop -1 -i "$JUMP_SOUND" \
                -filter_complex "[1:a]volume=0.40[bg];[0:a][bg]amix=inputs=2:duration=first[out]" \
                -map "[out]" -t "$DURATION" /tmp/tank_mixed_$$.wav 2>/dev/null
            if [ -f /tmp/tank_mixed_$$.wav ]; then
                safe_play afplay /tmp/tank_mixed_$$.wav
                rm /tmp/tank_mixed_$$.wav
            else
                safe_play afplay /tmp/tank_$$.wav
            fi
        else
            safe_play afplay /tmp/tank_$$.wav
        fi
        rm /tmp/tank_$$.wav
    fi
    exit 0
fi

# SMITH (Complex Mix)
if [ "$SPEAKER" = "Smith" ]; then
    # danny low slow
    echo "$MESSAGE" | /Users/jarkius/.local/bin/piper --model /Users/jarkius/.claude/piper-voices/en_US-danny-low.onnx --length-scale 1.3 --output_file /tmp/smith_$$.wav 2>/dev/null
    if [ -f /tmp/smith_$$.wav ]; then
        # Apply bass boost if sox exists
        if command -v sox >/dev/null 2>&1; then
             sox /tmp/smith_$$.wav /tmp/smith_fx_$$.wav bass +10 2>/dev/null
             mv /tmp/smith_fx_$$.wav /tmp/smith_$$.wav
        fi
        # Mix with Tron synth loop at 40% volume (1.5s music intro before voice)
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
        TRON_MUSIC="$PROJECT_ROOT/.claude/audio/tracks/tron_synth_loop.mp3"
        if [ -f "$TRON_MUSIC" ]; then
            DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 /tmp/smith_$$.wav 2>/dev/null)
            TOTAL_DUR=$(echo "$DURATION + 1.5" | bc)
            ffmpeg -y -i /tmp/smith_$$.wav -stream_loop -1 -i "$TRON_MUSIC" \
                -filter_complex "[1:a]volume=0.40[bg];[0:a]adelay=1500|1500[v];[v][bg]amix=inputs=2:duration=longest[out]" \
                -map "[out]" -t "$TOTAL_DUR" /tmp/smith_mixed_$$.wav 2>/dev/null
            if [ -f /tmp/smith_mixed_$$.wav ]; then
                safe_play afplay /tmp/smith_mixed_$$.wav
                rm /tmp/smith_mixed_$$.wav
            else
                safe_play afplay /tmp/smith_$$.wav
            fi
        else
            safe_play afplay /tmp/smith_$$.wav
        fi
        rm /tmp/smith_$$.wav
    fi
    exit 0
fi

# GENERIC FALLBACK (Using play-tts shim)
if [ -n "$VOICE_OVERRIDE" ]; then
    safe_play bash "$PLAY_TTS" "$MESSAGE" "$VOICE_OVERRIDE"
else
    safe_play bash "$PLAY_TTS" "$MESSAGE"
fi
