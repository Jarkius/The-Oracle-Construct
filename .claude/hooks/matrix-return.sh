#!/bin/bash
# Matrix Return - Agent exits the Matrix
# Usage: matrix-return.sh <AgentID> <ResultSummary>
#
# Plays jack-out sound and announces result via Operator (Tank)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

AGENT_ID="${1:-unknown}"
RESULT="${2:-Task complete}"

# Extract agent name from ID (format: agentname-timestamp-pid)
AGENT_NAME=$(echo "$AGENT_ID" | cut -d'-' -f1)
# Capitalize first letter
AGENT_NAME="$(tr '[:lower:]' '[:upper:]' <<< ${AGENT_NAME:0:1})${AGENT_NAME:1}"

# Paths
SFX_DIR="$PROJECT_ROOT/.claude/audio/sfx"
COMMS_DIR="$PROJECT_ROOT/psi/inbox/agent-comms"
VOICE_MODULE="$PROJECT_ROOT/psi/matrix/voice.sh"

# Update communication file
COMM_FILE="$COMMS_DIR/${AGENT_ID}.md"
if [[ -f "$COMM_FILE" ]]; then
    cat >> "$COMM_FILE" << EOF

## Exit
**Status**: JACKED_OUT
**Ended**: $(date '+%Y-%m-%d %H:%M:%S')
**Result**: $RESULT
EOF
fi

# No sound effect needed - the agent's voice IS the exit signal

# Visual indicator
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📞 $AGENT_NAME is out: $RESULT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Agent speaks in their OWN voice on exit
if [[ -f "$VOICE_MODULE" ]]; then
    sh "$VOICE_MODULE" "I'm out. ${RESULT}" "$AGENT_NAME"
fi
