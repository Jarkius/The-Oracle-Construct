#!/usr/bin/env bash
#
# File: .claude/hooks/matrix-activate-agent.sh
#
# The Matrix - AI Development Environment
# Repository: https://github.com/Jarkius/The-Oracle-Construct
#
# Co-created by Jarkius with Claude AI (The Council)
# "Know Thyself." - The Oracle
#
# ---
#
# @fileoverview Agent Voice Activator - Switch active agent voice
# @context Sets voice from voices.json (single source of truth)
# @agent Any - used to switch between agents
#
# USAGE:
#   .claude/hooks/matrix-activate-agent.sh <agent_name>
#   .claude/hooks/matrix-activate-agent.sh Smith
#   .claude/hooks/matrix-activate-agent.sh Oracle
#
# WRITES TO:
#   - tts-voice.txt (active voice model)
#   - tts-personality.txt (active personality)
#
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Source of truth
VOICES_JSON="$PROJECT_ROOT/.claude/config/voices.json"
VOICE_FILE="$PROJECT_ROOT/tts-voice.txt"
PERSONALITY_FILE="$PROJECT_ROOT/tts-personality.txt"

# Agent name (case-insensitive lookup)
AGENT_NAME="${1:-}"

if [[ -z "$AGENT_NAME" ]]; then
    echo "Usage: $0 <agent_name>"
    echo "Example: $0 Smith"
    echo ""
    echo "Available agents:"
    jq -r 'keys[]' "$VOICES_JSON" 2>/dev/null || echo "  (voices.json not found)"
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
