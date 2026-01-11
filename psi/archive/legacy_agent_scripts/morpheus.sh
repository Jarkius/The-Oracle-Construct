#!/bin/bash
# Morpheus: The External Navigator
# Purpose: Signal the AI to perform a Web Search.

QUERY="$1"

if [ -z "$QUERY" ]; then
    echo "🕶️ Morpheus: 'You take the blue pill, the story ends.'"
    echo "   Usage: $0 \"search query\""
    exit 1
fi

# Voice
./psi/matrix/voice.sh "Searching the real world..." "Morpheus" > /dev/null

# Log
OUTPUT="psi/inbox/research_request.md"
echo "# 🕶️ Morpheus Request" > "$OUTPUT"
echo "**Query**: $QUERY" >> "$OUTPUT"
echo "**Date**: $(date)" >> "$OUTPUT"
echo "**Status**: PENDING_WEB_SEARCH" >> "$OUTPUT"

echo "🕶️ Morpheus: 'I am navigating the Real World for: \"$QUERY\"'"
echo "   -> Signal sent. The Operator will now execute search_web()."
