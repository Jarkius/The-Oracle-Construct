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
# WEP-001: Hook Permission Guard
# Auto-fix non-executable hooks to prevent silent failures
# ============================================
FIXED_HOOKS=0
for hook in "$PROJECT_ROOT"/.claude/hooks/*.sh; do
    if [ -f "$hook" ] && [ ! -x "$hook" ]; then
        chmod +x "$hook"
        FIXED_HOOKS=$((FIXED_HOOKS + 1))
    fi
done
if [ "$FIXED_HOOKS" -gt 0 ]; then
    echo "# Hook Guard: Fixed $FIXED_HOOKS non-executable hook(s)" >&2
fi

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

# ============================================
# SOUL.md — Structural Personality Injection
# Phase 3.1: Role Enforcement (ADR-008)
# ============================================
SOUL_FILE="$PROJECT_ROOT/SOUL.md"
if [ -f "$SOUL_FILE" ]; then
    echo ""
    echo "# Soul (auto-injected)"
    echo ""
    cat "$SOUL_FILE"
    echo ""
fi

# ============================================
# USER.md — Operator Profile Injection
# Phase 3.4: Know Thy Operator (OpenClaw Pattern)
# ============================================
USER_FILE="$PROJECT_ROOT/USER.md"
if [ -f "$USER_FILE" ]; then
    echo ""
    echo "# Operator Profile (auto-injected)"
    echo ""
    cat "$USER_FILE"
    echo ""
fi

# ============================================
# BOOT.md — Startup Checklist Injection
# Phase 1: Memory & Persistence (ADR-008)
# ============================================
BOOT_FILE="$PROJECT_ROOT/BOOT.md"
if [ -f "$BOOT_FILE" ]; then
    echo ""
    echo "# Boot Checklist"
    echo ""
    cat "$BOOT_FILE"
    echo ""
fi

# ============================================
# Focus Injection — Current priorities
# ============================================
FOCUS_FILE="$PROJECT_ROOT/psi/inbox/focus.md"
if [ -f "$FOCUS_FILE" ]; then
    echo ""
    echo "# Current Focus (auto-injected)"
    echo ""
    cat "$FOCUS_FILE"
    echo ""
fi

# ============================================
# Active Tasks Injection — Pending work
# ============================================
TASKS_FILE="$PROJECT_ROOT/psi/memory/tasks/active.json"
if [ -f "$TASKS_FILE" ]; then
    TASK_COUNT=$(grep -c '"status"' "$TASKS_FILE" 2>/dev/null || echo "0")
    if [ "$TASK_COUNT" -gt 0 ]; then
        echo ""
        echo "# Active Tasks ($TASK_COUNT registered)"
        echo '```json'
        cat "$TASKS_FILE"
        echo '```'
        echo ""
    fi
fi

# ============================================
# PULSE: Event Queue Injection (Phase 5)
# ============================================
EVENTS_FILE="$PROJECT_ROOT/psi/pulse/events.jsonl"
if [ -f "$EVENTS_FILE" ] && [ -s "$EVENTS_FILE" ]; then
    EVENT_COUNT=$(wc -l < "$EVENTS_FILE" 2>/dev/null || echo "0")
    if [ "$EVENT_COUNT" -gt 0 ]; then
        echo ""
        echo "# Recent Events (Pulse — last 20)"
        echo '```jsonl'
        tail -20 "$EVENTS_FILE"
        echo '```'
        echo ""
    fi
fi

# ============================================
# PULSE: Reminders Injection (Phase 5)
# ============================================
REMINDERS_FILE="$PROJECT_ROOT/psi/pulse/reminders.json"
if [ -f "$REMINDERS_FILE" ]; then
    PENDING_REMINDERS=$(grep -c '"pending"' "$REMINDERS_FILE" 2>/dev/null || echo "0")
    if [ "$PENDING_REMINDERS" -gt 0 ]; then
        echo ""
        echo "# Pending Reminders ($PENDING_REMINDERS)"
        echo '```json'
        cat "$REMINDERS_FILE"
        echo '```'
        echo ""
    fi
fi

# Log session start event
EVENT_WRITER="$PROJECT_ROOT/.claude/hooks/pulse-event-writer.sh"
if [ -f "$EVENT_WRITER" ]; then
    bash "$EVENT_WRITER" "session:start" "System" '{"hook":"SessionStart"}' 2>/dev/null &
fi

# ============================================
# Last Session Memory — Continuity
# ============================================
SESSIONS_DIR="$PROJECT_ROOT/psi/memory/sessions"
if [ -d "$SESSIONS_DIR" ]; then
    LATEST_SESSION=$(find "$SESSIONS_DIR" -name "*.md" -type f 2>/dev/null | sort | tail -1)
    if [ -n "$LATEST_SESSION" ]; then
        echo ""
        echo "# Last Session Memory (auto-injected)"
        echo ""
        # Only inject the summary section, not the entire file
        head -30 "$LATEST_SESSION"
        echo ""
        echo "*(Full session: $LATEST_SESSION)*"
        echo ""
    fi
fi

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
