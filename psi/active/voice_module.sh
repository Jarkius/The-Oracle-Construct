#!/bin/bash

# Voice of the Matrix
# Wraps macOS 'say' command with Oracle Philosophy defaults
# - Rate: 300 (1.5x)
# - Voice: Kanya (Thai/Presence) or System Default

DEFAULT_RATE=300
PREFERRED_VOICE="Kanya"

# Function to check if a voice exists
voice_exists() {
    say -v ? | grep -q "$1"
}

# Determine voice
if voice_exists "$PREFERRED_VOICE"; then
    VOICE_FLAG="-v $PREFERRED_VOICE"
else
    # Fallback to default (no flag)
    VOICE_FLAG=""
fi

# Determine Rate (allow override via RATE env var)
RATE=${RATE:-$DEFAULT_RATE}

# Execute
# $1: The message to speak
MESSAGE="$1"

if [ -z "$MESSAGE" ]; then
    echo "Usage: $0 \"Message to speak\""
    exit 1
fi

# Echo what is being spoken for logs
echo "🔊 Speaking ($PREFERRED_VOICE @ $RATE): $MESSAGE"

# Speak
say $VOICE_FLAG -r $RATE "$MESSAGE"
