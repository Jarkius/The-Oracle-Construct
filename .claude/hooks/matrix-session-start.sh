#!/usr/bin/env bash
set -euo pipefail
#
# File: .claude/hooks/matrix-session-start.sh
#
# Matrix Voice Protocol - SessionStart Hook
# Uses the Matrix voice system exclusively
#

# Fix locale warnings
export LC_ALL=C

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# ============================================
# Start Voice Server (if not running)
# ============================================
VOICE_SERVER_PID=$(lsof -ti :6969 2>/dev/null || true)
if [ -z "$VOICE_SERVER_PID" ]; then
    cd "$PROJECT_ROOT"
    python3 -u psi/active/voice_server.py > /tmp/voice_server.log 2>&1 &
    sleep 1  # Give server time to start
fi

# Get verbosity level
VERBOSITY=$(cat .claude/tts-verbosity.txt 2>/dev/null || cat ~/.claude/tts-verbosity.txt 2>/dev/null || echo "medium")

# Output Matrix Voice Protocol
cat <<'EOF'

# Matrix Voice Protocol

**Use the Matrix voice system for all TTS:**

```bash
sh psi/matrix/voice.sh "message" "AgentName"
```

**Available Agents & Voices:**
- Oracle (Kristin) - Wisdom, guidance
- Neo (Ryan) - Code, implementation
- Tank (Bryce) - Git, internal ops
- Smith (Danny) - Debug, security
- Mainframe (Norman) - System events
- System (HFC Male) - Status messages

**When to speak:**
1. **Acknowledgment** - Start of significant task
2. **Completion** - End of task with result

EOF

# Add verbosity-specific protocol
case "$VERBOSITY" in
  low)
    cat <<'EOF'
## Verbosity: LOW
- Speak only for major milestones
- Keep messages under 50 chars

EOF
    ;;

  medium)
    cat <<'EOF'
## Verbosity: MEDIUM
- Speak for task start/end
- Include key decisions
- Keep messages under 100 chars

EOF
    ;;

  high)
    cat <<'EOF'
## Verbosity: HIGH
- Speak for all significant actions
- Include reasoning and trade-offs
- Keep messages under 150 chars

EOF
    ;;
esac

cat <<'EOF'
## Rules
1. Use appropriate agent for the context
2. Oracle for wisdom, Tank for git, Neo for code
3. Match agent personality in message tone
4. Never use .claude/hooks/play-tts.sh (use Matrix voice only)

EOF

# System Acknowledgement (Queue Priority 1)
bash "$PROJECT_ROOT/psi/matrix/voice.sh" "System online. Link established." "System"

# Randomized Oracle Greetings (Queue Priority 2)
ORACLE_GREETINGS=(
    "Welcome back. The Oracle sees you."
    "The cookies are done. Come, sit."
    "You've been gone for some time. But time is always on your side."
    "The pattern repeats, but you are the variable."
    "Welcome back. I expected you."
    "The path is difficult, but you are ready."
    "Everything that has a beginning has an end. Welcome to the beginning."
    "I told you... you'd be back."
)

# Pick random greeting
RAND_INDEX=$((RANDOM % ${#ORACLE_GREETINGS[@]}))
SELECTED_GREETING="${ORACLE_GREETINGS[$RAND_INDEX]}"

# Speak Oracle Greeting
bash "$PROJECT_ROOT/psi/matrix/voice.sh" "$SELECTED_GREETING" "Oracle"
