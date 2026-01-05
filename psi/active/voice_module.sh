#!/bin/bash

# Voice of the Matrix (Simplified)
# - Rate: 300 (1.5x)
# - Voice: System Default (Safest)

DEFAULT_RATE=300
RATE=${RATE:-$DEFAULT_RATE}

# Execute
MESSAGE="$1"

if [ -z "$MESSAGE" ]; then
    echo "Usage: $0 \"Message to speak\""
    exit 1
fi

echo "🔊 Speaking (Default @ $RATE): $MESSAGE"
say -r $RATE "$MESSAGE"
