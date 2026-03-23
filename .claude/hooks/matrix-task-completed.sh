#!/bin/bash
# TaskCompleted Hook — Updates task registry when agent marks task done
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

# --- AUTO-ARCHIVE completed tasks on each task completion ---
# This prevents completed tasks from piling up in active.json
SYNC_SCRIPT=".claude/hooks/pulse-task-sync.sh"
if [ -f "$SYNC_SCRIPT" ]; then
    bash "$SYNC_SCRIPT" archive 2>/dev/null &
fi

exit 0
