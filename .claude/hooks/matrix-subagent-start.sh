#!/bin/bash
# Subagent Start Hook
# Called by Claude Code SubagentStart event
# Logs agent spawn events for observability

# Change to project root
cd "$(dirname "$0")/../.." || exit 1

# Log directory
LOG_FILE="psi/memory/logs/agents/agent_events.log"
mkdir -p "$(dirname "$LOG_FILE")"

# Capture timestamp
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Capture Claude Code environment variables (if available)
AGENT_ID="${CLAUDE_AGENT_ID:-unknown}"
AGENT_TYPE="${CLAUDE_SUBAGENT_TYPE:-unknown}"

# Log the event
echo "[$TIMESTAMP] START | agent_id=$AGENT_ID | type=$AGENT_TYPE" >> "$LOG_FILE"
