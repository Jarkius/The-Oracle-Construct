#!/usr/bin/env bash
set -euo pipefail
#
# File: .claude/hooks/pulse-context-loader.sh
#
# Phase A: Context Loader — Load relevant memory when spawning agents (ADR-016)
#
# When the dispatcher spawns an agent, this script loads relevant context:
# 1. Agent personality (from .claude/agents/)
# 2. Relevant learnings (from memory system)
# 3. Recent related events (from events.jsonl)
# 4. Active tasks assigned to this agent
# 5. Last related session memory
#
# Usage:
#   bash pulse-context-loader.sh <agent_name> <task_description> [team_id]
#
# Output: Markdown context block to stdout (for injection into agent prompt)
#

export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

AGENT_NAME="${1:-Oracle}"
TASK_DESC="${2:-General task}"
TEAM_ID="${3:-}"
AGENT_LOWER=$(echo "$AGENT_NAME" | tr '[:upper:]' '[:lower:]')

MATRIX_ROOT="$PROJECT_ROOT"

# ─── 1. Agent Personality ────────────────────────────────────
PERSONALITY=""
for pattern in "${AGENT_LOWER}.md" "agent-${AGENT_LOWER}.md" "${AGENT_LOWER}-keeper.md"; do
    if [ -f "$PROJECT_ROOT/.claude/agents/$pattern" ]; then
        PERSONALITY=$(cat "$PROJECT_ROOT/.claude/agents/$pattern" 2>/dev/null || echo "")
        break
    fi
done

# ─── 2. Relevant Memory (semantic search) ────────────────────
MEMORY_CONTEXT=""
if [ -d "$MATRIX_ROOT" ] && command -v bun &> /dev/null; then
    MEMORY_CONTEXT=$(cd "$MATRIX_ROOT" && bun memory recall "$TASK_DESC" 2>/dev/null | head -30 || echo "")
fi

# ─── 3. Recent Related Events ────────────────────────────────
RECENT_EVENTS=""
if [ -f "$PROJECT_ROOT/psi/state/pulse/events.jsonl" ]; then
    # Get events related to this agent or related event types
    RECENT_EVENTS=$(tail -50 "$PROJECT_ROOT/psi/state/pulse/events.jsonl" 2>/dev/null | \
        grep -i "$AGENT_NAME\|ci:fail\|task:\|error" 2>/dev/null | \
        tail -10 || echo "")
fi

# ─── 4. Active Tasks for This Agent ─────────────────────────
AGENT_TASKS=""
TASKS_FILE="$PROJECT_ROOT/psi/memory/tasks/active.json"
if [ -f "$TASKS_FILE" ]; then
    AGENT_TASKS=$(python3 -c "
import json
try:
    data = json.load(open('$TASKS_FILE'))
    tasks = [t for t in data.get('tasks', [])
             if t.get('assignee', '').lower() == '${AGENT_LOWER}'
             and t.get('status') != 'completed']
    for t in tasks:
        print(f\"- [{t['status']}] {t['task']} (id: {t['id']})\")
except: pass
" 2>/dev/null || echo "")
fi

# ─── 5. Last Related Session ─────────────────────────────────
LAST_SESSION=""
SESSIONS_DIR="$PROJECT_ROOT/psi/memory/sessions"
if [ -d "$SESSIONS_DIR" ]; then
    LATEST_SESSION=$(find "$SESSIONS_DIR" -name "*.md" -type f 2>/dev/null | sort | tail -1 || echo "")
    if [ -n "$LATEST_SESSION" ]; then
        LAST_SESSION=$(head -20 "$LATEST_SESSION" 2>/dev/null || echo "")
    fi
fi

# ─── 6. Current Focus ────────────────────────────────────────
FOCUS=""
FOCUS_FILE="$PROJECT_ROOT/psi/state/focus.md"
if [ -f "$FOCUS_FILE" ]; then
    FOCUS=$(head -15 "$FOCUS_FILE" 2>/dev/null || echo "")
fi

# ─── Output: Assembled Context ───────────────────────────────
cat << CONTEXT_EOF
## Dispatch Context for $AGENT_NAME

### Mission
$TASK_DESC

### Current Focus
${FOCUS:-No focus file found.}

### Your Personality
${PERSONALITY:-Default agent behavior. Operate within Matrix protocols.}

### Your Active Tasks
${AGENT_TASKS:-No tasks currently assigned to you.}

### Relevant Memory
${MEMORY_CONTEXT:-No relevant memory found. This may be a new area.}

### Recent System Events
\`\`\`
${RECENT_EVENTS:-No recent relevant events.}
\`\`\`

### Last Session Context
${LAST_SESSION:-No recent session context available.}

### Protocol
- Read relevant files before acting
- Log significant findings via event queue
- If blocked, report the blocker clearly
- Work silently, return concise results
CONTEXT_EOF

# ─── 7. Team Context (Phase B) ────────────────────────────────
if [ -n "$TEAM_ID" ]; then
    ORCHESTRATOR="$PROJECT_ROOT/.claude/hooks/pulse-team-orchestrator.sh"
    if [ -f "$ORCHESTRATOR" ] && [ -x "$ORCHESTRATOR" ]; then
        echo ""
        echo "---"
        echo ""
        bash "$ORCHESTRATOR" spawn-prompt "$TEAM_ID" "$AGENT_NAME" 2>/dev/null || \
            echo "*Team context loading failed — operate independently*"
    fi
fi
