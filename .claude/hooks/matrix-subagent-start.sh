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

# --- COORDINATION: Write initial status file (ADR-019) ---
COORD_DIR="$HOME/.matrix/coordination/agents"
if [[ -d "$HOME/.matrix/coordination" ]]; then
    mkdir -p "$COORD_DIR"
    BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
    cat > "$COORD_DIR/${AGENT_ID}.status.json" <<STATUSEOF
{
  "agentId": "$AGENT_ID",
  "name": "$AGENT_TYPE",
  "worktree": "$(pwd)",
  "branch": "$BRANCH",
  "status": "starting",
  "currentTask": "",
  "progress": 0,
  "filesOwned": [],
  "blockedBy": null,
  "lastUpdate": "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
}
STATUSEOF
fi
