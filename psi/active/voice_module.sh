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

if [ "$SPEAKER" == "Oracle" ]; then
    # Oracle Mode: Slower, Calmer, Reassuring
    RATE=175
    VOICE_OPT="-v Samantha" # Standard macOS calm female voice
    echo "🔊 $SPEAKER (Calm): \"$MESSAGE\""
else
    # Default Mode
    VOICE_OPT=""
    echo "🔊 $SPEAKER: \"$MESSAGE\""
fi

say $VOICE_OPT -r $RATE "$MESSAGE"
