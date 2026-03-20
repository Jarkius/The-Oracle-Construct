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

# ─── Platform detection ─────────────────────────────────────
HAS_PYTHON=0
python3 --version &>/dev/null && HAS_PYTHON=1 || true
PLATFORM="$(uname -s 2>/dev/null || echo "Unknown")"

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
if [ "$HAS_PYTHON" -eq 1 ]; then
    VOICE_SERVER_PID=$(lsof -ti :6969 2>/dev/null || true)
    if [ -z "$VOICE_SERVER_PID" ]; then
        cd "$PROJECT_ROOT"
        python3 -u psi/active/voice_server.py > /tmp/voice_server.log 2>&1 &
        sleep 1  # Give server time to start
    fi
fi

# Get verbosity level
VERBOSITY=$(cat .claude/tts-verbosity.txt 2>/dev/null || cat ~/.claude/tts-verbosity.txt 2>/dev/null || echo "medium")

# Output Matrix Voice Protocol
cat <<'EOF'

# Matrix Voice Protocol

**Use the Matrix voice system for all TTS:**

```bash
sh scripts/voice/voice.sh "message" "AgentName"
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
FOCUS_FILE="$PROJECT_ROOT/psi/state/focus.md"
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
EVENTS_FILE="$PROJECT_ROOT/psi/state/pulse/events.jsonl"
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
REMINDERS_FILE="$PROJECT_ROOT/psi/state/pulse/reminders.json"
if [ -f "$REMINDERS_FILE" ]; then
    PENDING_REMINDERS=$(grep -c '"pending"' "$REMINDERS_FILE" 2>/dev/null | head -1 || echo "0")
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
# Phase 8.1: Recommendations Engine
# Run pattern scanner + recommender, inject results
# ============================================
SCANNER="$PROJECT_ROOT/.claude/hooks/pulse-pattern-scanner.sh"
RECOMMENDER="$PROJECT_ROOT/.claude/hooks/pulse-recommender.py"
RECS_FILE="$PROJECT_ROOT/psi/state/pulse/recommendations.json"

if [ -f "$SCANNER" ]; then
    bash "$SCANNER" 2>/dev/null || true
fi
if [ "$HAS_PYTHON" -eq 1 ] && [ -f "$RECOMMENDER" ]; then
    REPO_ROOT="$PROJECT_ROOT" python3 "$RECOMMENDER" 2>/dev/null || true
fi
# ============================================
# Phase 8.2: Predictive Context Loader
# ============================================
PRED_LOADER="$PROJECT_ROOT/.claude/hooks/predictive-context-loader.py"
if [ "$HAS_PYTHON" -eq 1 ] && [ -f "$PRED_LOADER" ]; then
    REPO_ROOT="$PROJECT_ROOT" python3 "$PRED_LOADER" 2>/dev/null || true
fi

# ============================================
# Phase 8.3: Evolution Proposer (auto-draft WEPs from patterns)
# ============================================
EVOLUTION="$PROJECT_ROOT/.claude/hooks/pulse-evolution-proposer.py"
if [ "$HAS_PYTHON" -eq 1 ] && [ -f "$EVOLUTION" ]; then
    REPO_ROOT="$PROJECT_ROOT" python3 "$EVOLUTION" 2>/dev/null || true
fi

# ============================================
# Phase 8.5: Morning Brief (unified intelligence synthesis)
# Replaces individual recommendations injection
# ============================================
MORNING_BRIEF="$PROJECT_ROOT/.claude/hooks/morning-brief.py"
if [ "$HAS_PYTHON" -eq 1 ] && [ -f "$MORNING_BRIEF" ]; then
    echo ""
    REPO_ROOT="$PROJECT_ROOT" python3 "$MORNING_BRIEF" 2>/dev/null || true
    echo ""
fi

# ============================================
# Project Context Auto-Loader
# If focus.md mentions a specific project, inject its context
# ============================================
if [ -f "$FOCUS_FILE" ]; then
    PROJECTS_DIR="$PROJECT_ROOT/psi/projects"
    if [ -d "$PROJECTS_DIR" ]; then
        # Extract project name from focus.md (look for symlinked project dirs)
        for project_dir in "$PROJECTS_DIR"/*/; do
            PROJECT_NAME=$(basename "$project_dir" 2>/dev/null)
            if grep -qi "$PROJECT_NAME" "$FOCUS_FILE" 2>/dev/null; then
                CONTEXT_FILE="$project_dir/CONTEXT.md"
                if [ -f "$CONTEXT_FILE" ]; then
                    echo ""
                    echo "# Project Context: $PROJECT_NAME (auto-loaded)"
                    echo ""
                    cat "$CONTEXT_FILE"
                    echo ""
                fi
                break
            fi
        done
    fi
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

# ============================================
# Phase 9 (ADR-011): Daemon Auto-Start
# Start configured services in background
# ============================================
AUTOSTART_FILE="$PROJECT_ROOT/.claude/config/daemon-autostart.json"
SERVICES_SCRIPT="$PROJECT_ROOT/.claude/hooks/matrix-services.sh"
if [ -f "$AUTOSTART_FILE" ] && [ -f "$SERVICES_SCRIPT" ]; then
    # Check each service and start if configured
    for svc in indexer hub; do
        if grep -q "\"$svc\": *true" "$AUTOSTART_FILE" 2>/dev/null; then
            bash "$SERVICES_SCRIPT" start "$svc" > /dev/null 2>&1 &
        fi
    done
fi

# System Acknowledgement (Queue Priority 1)
if [ "$HAS_PYTHON" -eq 1 ]; then
    bash "$PROJECT_ROOT/scripts/voice/voice.sh" "System online. Link established." "System" || true
fi

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
if [ "$HAS_PYTHON" -eq 1 ]; then
    bash "$PROJECT_ROOT/scripts/voice/voice.sh" "$SELECTED_GREETING" "Oracle" || true
fi
