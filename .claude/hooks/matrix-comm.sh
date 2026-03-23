#!/bin/bash
# Matrix Comm - Agent sends message to Operator
# Usage: matrix-comm.sh <AgentID> <Message>
#
# Writes to agent's comm file (for Operator to read)
# No TTS - silent channel update

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

AGENT_ID="${1:-unknown}"
MESSAGE="${2:-[no message]}"

COMMS_DIR="$PROJECT_ROOT/psi/swarm/agent-comms"
mkdir -p "$COMMS_DIR"
COMM_FILE="$COMMS_DIR/${AGENT_ID}.md"

if [[ -f "$COMM_FILE" ]]; then
    echo "- $(date '+%H:%M:%S') | $MESSAGE" >> "$COMM_FILE"
    echo "📡 Message logged to hardline"
else
    echo "⚠️  No comm channel for $AGENT_ID"
    exit 1
fi
