#!/bin/bash
# Subagent Completion Hook
# Called by Claude Code SubagentStop event
# Mainframe announces when a subagent returns to source

# Change to project root (hook may run from different context)
cd "$(dirname "$0")/../.." || exit 1

# --- LOGGING (always, for observability) ---
LOG_FILE="psi/memory/logs/agents/agent_events.log"
mkdir -p "$(dirname "$LOG_FILE")"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
AGENT_ID="${CLAUDE_AGENT_ID:-unknown}"
AGENT_TYPE="${CLAUDE_SUBAGENT_TYPE:-unknown}"
echo "[$TIMESTAMP] STOP  | agent_id=$AGENT_ID | type=$AGENT_TYPE" >> "$LOG_FILE"

# --- VOICE (with cooldown to prevent flood) ---
LOCK_FILE="/tmp/mainframe_cycle_lock"
if [ -f "$LOCK_FILE" ]; then
    LOCK_AGE=$(($(date +%s) - $(stat -f %m "$LOCK_FILE" 2>/dev/null || echo 0)))
    if [ "$LOCK_AGE" -lt 5 ]; then
        exit 0  # Skip voice - too soon since last announcement
    fi
fi
touch "$LOCK_FILE"

# Small delay to let any in-flight audio finish
sleep 0.3

# Mainframe speaks - the ever-present system
sh psi/matrix/voice.sh "The cycle completes. I remain." "Mainframe"
