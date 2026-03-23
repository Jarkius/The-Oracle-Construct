#!/bin/bash
# Subagent Completion Hook
# Called by Claude Code SubagentStop event
# Mainframe announces when a subagent returns to source

# Change to project root (hook may run from different context)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib-platform.sh"
cd "$SCRIPT_DIR/../.." || exit 1

# --- LOGGING (always, for observability) ---
LOG_FILE="psi/memory/logs/agents/agent_events.log"
mkdir -p "$(dirname "$LOG_FILE")"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
AGENT_ID="${CLAUDE_AGENT_ID:-unknown}"
AGENT_TYPE="${CLAUDE_SUBAGENT_TYPE:-unknown}"
echo "[$TIMESTAMP] STOP  | agent_id=$AGENT_ID | type=$AGENT_TYPE" >> "$LOG_FILE"

# --- COORDINATION: Update status + release locks (ADR-019) ---
COORD_DIR="$HOME/.matrix/coordination/agents"
STATUS_FILE="$COORD_DIR/${AGENT_ID}.status.json"
if [[ -f "$STATUS_FILE" ]]; then
    # Update status to complete
    TMP_FILE=$(mktemp)
    jq --arg ts "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
       '.status = "complete" | .progress = 1 | .lastUpdate = $ts' \
       "$STATUS_FILE" > "$TMP_FILE" 2>/dev/null && mv "$TMP_FILE" "$STATUS_FILE"
fi

# Release all file locks held by this agent
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
if command -v bun &>/dev/null && [[ -f "$PROJECT_DIR/scripts/coordination/release-agent-locks.ts" ]]; then
    bun run "$PROJECT_DIR/scripts/coordination/release-agent-locks.ts" "$AGENT_ID" 2>/dev/null &
fi

# --- VOICE (with cooldown to prevent flood) ---
LOCK_FILE="$MATRIX_TMPDIR/mainframe_cycle_lock"
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
bash scripts/voice/voice.sh "The cycle completes. I remain." "Mainframe"
