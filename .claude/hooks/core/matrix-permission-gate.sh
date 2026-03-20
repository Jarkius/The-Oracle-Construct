#!/usr/bin/env bash
# ============================================================
# matrix-permission-gate.sh - Agent Permission Enforcement
# ============================================================
#
# PURPOSE:
#   Enforces agent frontmatter permissions at runtime.
#   Architect (plan mode) cannot Write/Edit/Bash.
#   Trinity (plan mode) cannot Write/Edit/Bash/Agent.
#   Tank cannot Write/Edit/Agent.
#   Humans are NEVER blocked.
#
# PROTOCOL:
#   Reads PreToolUse JSON from stdin.
#   Passes to bun scripts/security/check-permission.ts
#   If blocked → exit 2
#   If allowed → exit 0
#
# EXIT CODES:
#   0 = Allow the operation
#   2 = Block the operation (permission denied)
#
# ============================================================

# Read JSON input from stdin
INPUT=$(cat)

# No agent ID = human session — NEVER block humans
AGENT_ID="${CLAUDE_AGENT_ID:-}"
if [[ -z "$AGENT_ID" ]]; then
    exit 0
fi

# No agent type = can't resolve permissions, allow (fail open)
AGENT_TYPE="${CLAUDE_AGENT_TYPE:-}"
if [[ -z "$AGENT_TYPE" && -z "$AGENT_ID" ]]; then
    exit 0
fi

# Extract tool name from JSON
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
if [[ -z "$TOOL_NAME" ]]; then
    exit 0
fi

# Check if bun is available
if ! command -v bun &>/dev/null; then
    # Can't run permission check without bun — fail open
    exit 0
fi

# Resolve project directory
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# Call the TypeScript enforcement engine
echo "$INPUT" | CLAUDE_PROJECT_DIR="$PROJECT_DIR" \
    bun run "$PROJECT_DIR/scripts/security/check-permission.ts" 2>&1

EXIT_CODE=$?

# Relay exit code (0 = allow, 2 = block)
exit $EXIT_CODE
