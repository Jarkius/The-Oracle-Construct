#!/usr/bin/env bash
set -euo pipefail
#
# File: .claude/hooks/pulse-post-action.sh
#
# Phase 5.1 + ADR-010 + WEP-004 + WEP-005: Async Post-Action Hook
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

EVENT_WRITER="$PROJECT_ROOT/.claude/hooks/pulse/pulse-event-writer.sh"

# Read tool use context from stdin (JSON)
INPUT=$(cat 2>/dev/null || echo '{}')

# ─── WEP-004: Extract session ID from hook input JSON ─────────
# Claude Code hooks receive JSON with session_id field on stdin.
# Export it so pulse-event-writer.sh can use it.
if [ -z "${CLAUDE_SESSION_ID:-}" ] || [ "${CLAUDE_SESSION_ID:-}" = "unknown" ]; then
    PARSED_SID=$(echo "$INPUT" | grep -o '"session_id":"[^"]*"' | head -1 | cut -d'"' -f4 || echo "")
    if [ -n "$PARSED_SID" ]; then
        export CLAUDE_SESSION_ID="$PARSED_SID"
    fi
fi

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

    # ─── WEP-005: Enhanced CI/test failure detection ──────────────
    # Detect test runner invocations and track pass/fail
    EXIT_CODE=$(echo "$INPUT" | grep -o '"exit_code":[0-9]*' | head -1 | cut -d: -f2 || echo "0")
    IS_TEST_RUNNER=false

    # Detect common test runner commands
    if echo "$TOOL_INPUT" "$INPUT" | grep -qiE "pytest|jest|vitest|npm test|bun test|phpunit|mocha|cargo test|go test" 2>/dev/null; then
        IS_TEST_RUNNER=true
    fi

    if [ "$IS_TEST_RUNNER" = true ]; then
        if [ "${EXIT_CODE:-0}" != "0" ]; then
            bash "$EVENT_WRITER" "ci:fail" "Smith" "{\"tool\":\"Bash\",\"exit_code\":$EXIT_CODE,\"runner\":\"detected\"}"

            # ADR-010: Auto-learn from failures
            if [ -d "$MMA_DIR" ] && command -v bun &> /dev/null; then
                cd "$MMA_DIR"
                echo "$INPUT" | bun memory save "CI failure detected (exit code $EXIT_CODE)" 2>/dev/null || true
            fi
        else
            # Emit ci:pass for successful test runs (enables pass/fail ratio tracking)
            bash "$EVENT_WRITER" "ci:pass" "Smith" '{"tool":"Bash","exit_code":0,"runner":"detected"}'
        fi
    elif [ "${EXIT_CODE:-0}" != "0" ]; then
        # Non-test command with non-zero exit — check for failure keywords
        if echo "$INPUT" | grep -qiE "fail|FAILED|error|panic|exception|segfault" 2>/dev/null; then
            bash "$EVENT_WRITER" "ci:fail" "System" "{\"tool\":\"Bash\",\"exit_code\":$EXIT_CODE}"

            if [ -d "$MMA_DIR" ] && command -v bun &> /dev/null; then
                cd "$MMA_DIR"
                echo "$INPUT" | bun memory save "Command failure detected (exit code $EXIT_CODE)" 2>/dev/null || true
            fi
        fi
    fi
fi

# Always allow — this is observational, never blocking
exit 0
