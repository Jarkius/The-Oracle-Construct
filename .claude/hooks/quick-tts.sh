#!/usr/bin/env bash
#
# File: .claude/hooks/quick-tts.sh
#
# Quick TTS - Direct speech without file generation
# Perfect for testing voice quality quickly
#
# Usage:
#   ./quick-tts.sh "Hello world"                    # Use current voice
#   ./quick-tts.sh "Hello world" kristin            # Specify voice (shorthand)
#   ./quick-tts.sh "Hello world" en_US-ryan-high    # Specify full voice name
#   ./quick-tts.sh "Hello world" --macos Samantha   # Use macOS voice
#

set -euo pipefail
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VOICES_DIR="$HOME/.claude/piper-voices"

TEXT="${1:-}"
VOICE_ARG="${2:-}"
MACOS_VOICE="${3:-}"

if [[ -z "$TEXT" ]]; then
    echo "Usage: $0 \"text to speak\" [voice] [--macos voice_name]"
    echo ""
    echo "Examples:"
    echo "  $0 \"Hello world\"                     # Default voice"
    echo "  $0 \"Hello world\" kristin             # Piper shorthand"
    echo "  $0 \"Hello world\" en_US-ryan-high     # Piper full name"
    echo "  $0 \"Hello world\" --macos Samantha    # macOS voice"
    echo ""
    echo "Available Piper voices:"
    ls "$VOICES_DIR"/*.onnx 2>/dev/null | xargs -n1 basename | sed 's/.onnx$//' | sed 's/^/  /'
    echo ""
    echo "Available macOS voices:"
    say -v '?' 2>/dev/null | head -10 | sed 's/^/  /'
    echo "  ... (run 'say -v ?' for full list)"
    exit 1
fi

# macOS direct mode (fastest, no file at all)
if [[ "$VOICE_ARG" == "--macos" ]] || [[ "$VOICE_ARG" == "-m" ]]; then
    MACOS_VOICE="${MACOS_VOICE:-Samantha}"
    echo "🎤 Quick test: macOS '$MACOS_VOICE' (direct, no file)"
    /usr/bin/say -v "$MACOS_VOICE" "$TEXT"
    exit 0
fi

# Piper streaming mode
VOICE_MODEL=""

# Resolve voice shorthand to full path
if [[ -n "$VOICE_ARG" ]]; then
    # Check if it's already a full voice name
    if [[ -f "$VOICES_DIR/${VOICE_ARG}.onnx" ]]; then
        VOICE_MODEL="$VOICES_DIR/${VOICE_ARG}.onnx"
    else
        # Try to find by partial match
        MATCH=$(ls "$VOICES_DIR"/*"${VOICE_ARG}"*.onnx 2>/dev/null | head -1)
        if [[ -n "$MATCH" ]]; then
            VOICE_MODEL="$MATCH"
        fi
    fi
fi

# Default voice if not specified
if [[ -z "$VOICE_MODEL" ]]; then
    # Read from config or use default
    if [[ -f "$SCRIPT_DIR/../tts-voice.txt" ]]; then
        DEFAULT_VOICE=$(cat "$SCRIPT_DIR/../tts-voice.txt" | tr -d '[:space:]')
        VOICE_MODEL="$VOICES_DIR/${DEFAULT_VOICE}.onnx"
    else
        VOICE_MODEL="$VOICES_DIR/en_US-kristin-medium.onnx"
    fi
fi

if [[ ! -f "$VOICE_MODEL" ]]; then
    echo "❌ Voice model not found: $VOICE_MODEL"
    exit 1
fi

VOICE_NAME=$(basename "$VOICE_MODEL" .onnx)
echo "🎤 Quick test: Piper '$VOICE_NAME' (streaming, no file)"

# Get sample rate for this voice (most are 22050, some are 16000)
SAMPLE_RATE=22050
if [[ "$VOICE_NAME" == *"-low"* ]]; then
    SAMPLE_RATE=16000
fi

# Stream/play audio
# On macOS, afplay doesn't support stdin, so we use a minimal temp file approach
# This is still much faster than the full pipeline (no effects, no background music)

TEMP_WAV="/tmp/quick-tts-$$.wav"
trap "rm -f $TEMP_WAV" EXIT

echo "$TEXT" | piper --model "$VOICE_MODEL" --output_file "$TEMP_WAV" 2>/dev/null

if [[ ! -f "$TEMP_WAV" ]]; then
    echo "❌ Piper failed to generate audio"
    exit 1
fi

# Play immediately
if [[ "$(uname)" == "Darwin" ]]; then
    afplay "$TEMP_WAV"
elif command -v paplay &> /dev/null; then
    paplay "$TEMP_WAV"
elif command -v aplay &> /dev/null; then
    aplay -q "$TEMP_WAV"
elif command -v ffplay &> /dev/null; then
    ffplay -nodisp -autoexit -loglevel quiet "$TEMP_WAV"
else
    echo "❌ No audio player found"
    exit 1
fi

echo "✓ Done (temp file auto-deleted)"
