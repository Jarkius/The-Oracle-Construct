#!/bin/bash
# Matrix Spawn - Jack an agent into the Matrix
# Usage: matrix-spawn.sh <AgentName> [silent]
#
# Creates communication channel and plays jack-in sound
# Pass "silent" as second arg to skip TTS announcement

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

AGENT_NAME="${1:-Agent}"
SILENT="${2:-}"

# Paths
SFX_DIR="$PROJECT_ROOT/.claude/audio/sfx"
COMMS_DIR="$PROJECT_ROOT/psi/inbox/agent-comms"
ARTIFACTS_DIR="$PROJECT_ROOT/psi/inbox/artifacts"

# Generate session ID for this spawn
SESSION_ID="$(date +%s)-$$"
AGENT_ID="$(echo "$AGENT_NAME" | tr '[:upper:]' '[:lower:]')-${SESSION_ID}"

# Create agent's communication files
COMM_FILE="$COMMS_DIR/${AGENT_NAME}.md"
ARTIFACT_FILE="$ARTIFACTS_DIR/${AGENT_ID}.md"

# Header for new session (append)
{
    echo ""
    echo "### Session Start: $SESSION_ID"
    echo "**Status**: JACKED_IN"
    echo "**Started**: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
} >> "$COMM_FILE"

# Play jack-in sound (non-blocking) - prefer matrix version
JACK_SOUND="$SFX_DIR/jack_in.wav"
[[ -f "$SFX_DIR/jack_in_matrix.wav" ]] && JACK_SOUND="$SFX_DIR/jack_in_matrix.wav"
if [[ -f "$JACK_SOUND" ]]; then
    afplay "$JACK_SOUND" &
fi

# Short TTS announcement in AGENT'S OWN VOICE (unless silent)
if [[ "$SILENT" != "silent" ]]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "⚡ $AGENT_NAME jacking in..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    # Agent speaks in their OWN voice
    if [[ -f "$PROJECT_ROOT/psi/matrix/voice.sh" ]]; then
        sh "$PROJECT_ROOT/psi/matrix/voice.sh" "Jacking in." "$AGENT_NAME"
    fi
fi

# Output the agent ID for tracking
echo "$AGENT_ID"

# Export paths for the agent to use
export MATRIX_AGENT_ID="$AGENT_ID"
export MATRIX_COMM_FILE="$COMM_FILE"
export MATRIX_ARTIFACT_FILE="$ARTIFACT_FILE"
