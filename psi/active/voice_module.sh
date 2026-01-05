#!/bin/bash

# Voice of the Matrix (Simplified)
# - Rate: 300 (1.5x)
# - Voice: System Default (Safest)

DEFAULT_RATE=210
RATE=${RATE:-$DEFAULT_RATE}

# Execute
MESSAGE="$1"
SPEAKER="${2:-System}" # Default to System if no name provided

if [ -z "$MESSAGE" ]; then
    echo "Usage: $0 \"Message\" [SpeakerName]"
    exit 1
fi

echo "🔊 $SPEAKER: \"$MESSAGE\""
say -r $RATE "$MESSAGE"
