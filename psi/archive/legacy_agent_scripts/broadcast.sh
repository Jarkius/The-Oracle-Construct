#!/bin/bash
# broadcast.sh - Matrix Communication System
# Usage: ./broadcast.sh "Message" "AgentName"
#
# Writes to:
# 1. psi/inbox/agent-comms/[Agent].md (Agent Log)
# 2. psi/inbox/agent-comms/matrix_frequency.md (Global Log)

MESSAGE="$1"
AGENT="${2:-System}"
TIMESTAMP=$(date +"%H:%M:%S")

COMMS_DIR="psi/inbox/agent-comms"
mkdir -p "$COMMS_DIR"

# File paths
AGENT_LOG="$COMMS_DIR/${AGENT}.md"
GLOBAL_LOG="$COMMS_DIR/matrix_frequency.md"

# Ensure files have headers
if [ ! -f "$GLOBAL_LOG" ]; then
    echo "# Matrix Frequency (Global Comms)" > "$GLOBAL_LOG"
    echo "Listening..." >> "$GLOBAL_LOG"
    echo "" >> "$GLOBAL_LOG"
fi

if [ ! -f "$AGENT_LOG" ]; then
    echo "# Comms Log: $AGENT" > "$AGENT_LOG"
    echo "" >> "$AGENT_LOG"
fi

# Format the entry
ENTRY="[${TIMESTAMP}] **${AGENT}**: ${MESSAGE}"

# 1. Write to Global Log (prepend to top after header? No, append is safer for strict logging, but reading latest is easier if appended. `tail` works.)
echo "$ENTRY" >> "$GLOBAL_LOG"

# 2. Write to Agent Log
echo "$ENTRY" >> "$AGENT_LOG"

# 3. Optional: Echo to stdout for CLI visibility
echo "📡 $ENTRY"
