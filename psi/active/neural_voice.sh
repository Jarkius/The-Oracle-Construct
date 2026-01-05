#!/bin/bash
# Neural Voice Engine (Piper TTS Wrapper)
# Provides high-quality neural speech synthesis locally.
# Inspired by AgentVibes architecture.

TEXT="$1"
VOICE_MODEL="${2:-en_US-ryan-high.onnx}" # Default to Neo's voice
CACHE_DIR="psi/active/piper_engine/cache"
PIPER_BIN="psi/active/piper_engine/venv/bin/piper"
MODEL_PATH="psi/active/piper_engine/$VOICE_MODEL"

# Ensure cache exists
mkdir -p "$CACHE_DIR"

# Generate hash for caching
HASH=$(echo "$TEXT" | md5)
AUDIO_FILE="$CACHE_DIR/${HASH}.wav"

# Check if cached
if [ ! -f "$AUDIO_FILE" ]; then
    # Generate Audio
    echo "$TEXT" | "$PIPER_BIN" --model "$MODEL_PATH" --output_file "$AUDIO_FILE"
fi

# Play Audio
afplay "$AUDIO_FILE"
