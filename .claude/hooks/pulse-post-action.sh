#!/usr/bin/env bash
set -euo pipefail
#
# File: .claude/hooks/pulse-post-action.sh
#
# Phase 5.1 + ADR-010: Async Post-Action Hook
# Logs significant tool actions to event queue + SQLite.
# Runs async — does NOT block the agent.
#
# Triggered by: PostToolUse (Bash)
# Reads CLAUDE_TOOL_NAME and tool output from stdin
#

export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MMA_DIR="$PROJECT_ROOT/lib/matrix-memory-agents"

EVENT_WRITER="$PROJECT_ROOT/.claude/hooks/pulse-event-writer.sh"

# Read tool use context from stdin (JSON)
INPUT=$(cat 2>/dev/null || echo '{}')

TOOL_NAME=$(echo "$INPUT" | grep -o '"tool_name":"[^"]*"' | head -1 | cut -d'"' -f4 || echo "unknown")
TOOL_INPUT=$(echo "$INPUT" | grep -o '"tool_input":{[^}]*}' | head -1 || echo "{}")

# Detect significant actions from Bash tool output
if [ "$TOOL_NAME" = "Bash" ] || [ "${CLAUDE_TOOL_NAME:-}" = "Bash" ]; then
    # Check for git operations
    if echo "$TOOL_INPUT" "$INPUT" | grep -q "git push" 2>/dev/null; then
        bash "$EVENT_WRITER" "git:push" "Neo" '{"tool":"Bash","action":"git push"}'
    elif echo "$TOOL_INPUT" "$INPUT" | grep -q "git commit" 2>/dev/null; then
        bash "$EVENT_WRITER" "git:commit" "Neo" '{"tool":"Bash","action":"git commit"}'
    fi

    # Check for test failures
    if echo "$INPUT" | grep -qi "fail\|error\|FAILED" 2>/dev/null; then
        EXIT_CODE=$(echo "$INPUT" | grep -o '"exit_code":[0-9]*' | head -1 | cut -d: -f2 || echo "0")
        if [ "${EXIT_CODE:-0}" != "0" ]; then
            bash "$EVENT_WRITER" "ci:fail" "System" "{\"tool\":\"Bash\",\"exit_code\":$EXIT_CODE}"

            # ─── ADR-010: Auto-learn from failures ──────────────
            # Capture test failure context into memory system
            if [ -d "$MMA_DIR" ] && command -v bun &> /dev/null; then
                cd "$MMA_DIR"
                echo "$INPUT" | bun memory save "CI failure detected (exit code $EXIT_CODE)" 2>/dev/null || true
            fi
        fi
    fi
fi

# Always allow — this is observational, never blocking
exit 0
