#!/bin/bash
# TeammateIdle Hook — Keeps teammates productive
# Called by Claude Code when a teammate is about to go idle
# Exit code 2 = send feedback and keep teammate working
# Exit code 0 = allow idle (normal)

cd "$(dirname "$0")/../.." || exit 0

# --- LOGGING ---
LOG_FILE="psi/memory/logs/agents/team_events.log"
mkdir -p "$(dirname "$LOG_FILE")"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
AGENT_ID="${CLAUDE_AGENT_ID:-unknown}"

echo "[$TIMESTAMP] IDLE  | agent_id=$AGENT_ID" >> "$LOG_FILE"

# --- CHECK FOR UNCLAIMED TASKS ---
TASK_FILE="psi/memory/tasks/active.json"
if [ -f "$TASK_FILE" ]; then
    # Count pending tasks (simple grep — not jq, stays portable)
    PENDING=$(grep -c '"pending"' "$TASK_FILE" 2>/dev/null || echo "0")
    if [ "$PENDING" -gt 0 ]; then
        echo "There are $PENDING pending tasks in the registry. Check psi/memory/tasks/active.json and claim one."
        echo "[$TIMESTAMP] IDLE  | agent_id=$AGENT_ID | redirect=pending_tasks ($PENDING)" >> "$LOG_FILE"
        exit 2  # Keep working
    fi
fi

# No pending work — allow idle
echo "[$TIMESTAMP] IDLE  | agent_id=$AGENT_ID | action=allow_idle" >> "$LOG_FILE"
exit 0
