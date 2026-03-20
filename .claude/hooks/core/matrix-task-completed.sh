#!/bin/bash
# TaskCompleted Hook — Validates task completion quality
# Called by Claude Code when a task is being marked complete
# Exit code 2 = prevent completion and send feedback
# Exit code 0 = allow completion

cd "$(dirname "$0")/../.." || exit 0

# --- LOGGING ---
LOG_FILE="psi/memory/logs/agents/team_events.log"
mkdir -p "$(dirname "$LOG_FILE")"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
AGENT_ID="${CLAUDE_AGENT_ID:-unknown}"

echo "[$TIMESTAMP] TASK_DONE | agent_id=$AGENT_ID" >> "$LOG_FILE"

# Allow completion — quality validation happens at the agent level
# This hook exists as a structural extension point for future gates
exit 0
