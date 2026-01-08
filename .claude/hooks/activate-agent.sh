#!/bin/bash
# activate-agent.sh - Set active agent voice from source of truth (voices.json)
# This ensures shell hooks and MCP tools use the same voice

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$SCRIPT_DIR/.." && pwd)}"

# Source of truth
VOICES_JSON="$PROJECT_ROOT/config/voices.json"
VOICE_FILE="$PROJECT_ROOT/tts-voice.txt"
PERSONALITY_FILE="$PROJECT_ROOT/tts-personality.txt"

# Agent name (case-insensitive lookup)
AGENT_NAME="$1"

if [[ -z "$AGENT_NAME" ]]; then
    echo "Usage: $0 <agent_name>"
    echo "Example: $0 Smith"
    echo ""
    echo "Available agents:"
    jq -r 'keys[]' "$VOICES_JSON" 2>/dev/null
    exit 1
fi

if [[ ! -f "$VOICES_JSON" ]]; then
    echo "❌ Source of truth not found: $VOICES_JSON"
    exit 1
fi

# Look up agent (case-insensitive)
AGENT_KEY=$(jq -r --arg name "$AGENT_NAME" 'keys[] | select(. | ascii_downcase == ($name | ascii_downcase))' "$VOICES_JSON" 2>/dev/null | head -1)

if [[ -z "$AGENT_KEY" ]]; then
    echo "❌ Agent not found: $AGENT_NAME"
    echo ""
    echo "Available agents:"
    jq -r 'keys[]' "$VOICES_JSON" 2>/dev/null
    exit 1
fi

# Extract voice and personality from source of truth
VOICE=$(jq -r --arg key "$AGENT_KEY" '.[$key].voice // empty' "$VOICES_JSON")
PERSONALITY=$(jq -r --arg key "$AGENT_KEY" '.[$key].personality // "normal"' "$VOICES_JSON")

if [[ -z "$VOICE" ]]; then
    echo "❌ No voice defined for agent: $AGENT_KEY"
    exit 1
fi

# Write to active config files (sync from source of truth)
echo "$VOICE" > "$VOICE_FILE"
echo "$PERSONALITY" > "$PERSONALITY_FILE"

echo "✅ Agent activated: $AGENT_KEY"
echo "   Voice: $VOICE"
echo "   Personality: $PERSONALITY"
echo "   Source: voices.json (single source of truth)"
