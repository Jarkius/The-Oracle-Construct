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
    VOICE_OPT="-v Samantha"
    echo "🔊 $SPEAKER (Calm): \"$MESSAGE\""

elif [ "$SPEAKER" == "Architect" ]; then
    # Architect: Precision, History, Control.
    RATE=190
    VOICE_OPT="-v Daniel"
    echo "🔊 $SPEAKER (Precise): \"$MESSAGE\""

elif [ "$SPEAKER" == "Neo" ]; then
    # Neo: Curiosity, Focus, Determination.
    RATE=200
    VOICE_OPT="-v Reed" # Guaranteed US Male
    echo "🔊 $SPEAKER (Focused): \"$MESSAGE\""

elif [ "$SPEAKER" == "Trinity" ] || [ "$SPEAKER" == "Woman in Red" ]; then
    # Trinity: Action, Directness, Empathy.
    RATE=200
    VOICE_OPT="-v Moira" # Irish Female - High Quality
    echo "🔊 $SPEAKER (Direct): \"$MESSAGE\""

elif [ "$SPEAKER" == "Morpheus" ]; then
    # Morpheus: Wisdom, Belief, Gravity.
    RATE=160
    VOICE_OPT="-v Ralph" # Deep, Resonant
    echo "🔊 $SPEAKER (Wise): \"$MESSAGE\""

elif [ "$SPEAKER" == "Tank" ]; then
    # Tank: Support, Technical, Fast.
    RATE=220
    VOICE_OPT="-v Rocko" # Energetic/Rough
    echo "🔊 $SPEAKER (Technical): \"$MESSAGE\""

elif [ "$SPEAKER" == "Smith" ]; then
    # Smith: Cold, Bureaucratic, Inevitable.
    RATE=170
    VOICE_OPT="-v Fred" # Robotic/Distinct
    echo "🔊 $SPEAKER (Cold): \"$MESSAGE\""

else
    # Default (System/Unknown)
    VOICE_OPT=""
    echo "🔊 $SPEAKER: \"$MESSAGE\""
fi

say $VOICE_OPT -r $RATE "$MESSAGE"
