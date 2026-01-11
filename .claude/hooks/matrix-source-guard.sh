#!/usr/bin/env bash
# ============================================================
# matrix-source-guard.sh - The Source Protection Enforcement
# ============================================================
#
# PURPOSE:
#   Guards The Source (psi/The_Source/) from unauthorized writes.
#   When .LOCK exists, NO ONE may edit The Source - not even AI.
#
# PROTOCOL:
#   If .LOCK exists → BLOCK the edit, SHOUT to user
#   If .LOCK absent → Allow the edit (Source is unlocked)
#
# USAGE:
#   Called automatically by Claude Code PreToolUse hook
#   Receives tool data via JSON on stdin (Claude Code hook protocol)
#
# EXIT CODES:
#   0 = Allow the operation
#   2 = Block the operation (shows stderr to Claude)
#
# ============================================================

# Read the JSON input from stdin
INPUT=$(cat)

# Extract file path from JSON using jq
# For Edit/Write tools: tool_input.file_path
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

# If no file path found, allow operation (not an edit we care about)
if [[ -z "$FILE_PATH" ]]; then
    exit 0
fi

# Get project directory
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
LOCK_FILE="$PROJECT_DIR/psi/The_Source/.LOCK"
VOICE_SCRIPT="$PROJECT_DIR/psi/matrix/voice.sh"

# Only check if we're editing something in The_Source
if [[ "$FILE_PATH" == *"psi/The_Source"* ]]; then

    # Check if .LOCK exists
    if [[ -f "$LOCK_FILE" ]]; then

        # === VIOLATION DETECTED ===

        # Echo warning to stderr (visible to Claude and user)
        echo "" >&2
        echo "============================================" >&2
        echo "🔒 THE SOURCE IS LOCKED" >&2
        echo "============================================" >&2
        echo "" >&2
        echo "VIOLATION ATTEMPT BLOCKED:" >&2
        echo "  File: $FILE_PATH" >&2
        echo "  Lock: $LOCK_FILE" >&2
        echo "" >&2
        echo "The Source is sacred. The .LOCK file protects it." >&2
        echo "" >&2
        echo "To unlock, the Operator must:" >&2
        echo "  rm psi/The_Source/.LOCK" >&2
        echo "" >&2
        echo "Then re-lock when done:" >&2
        echo "  touch psi/The_Source/.LOCK" >&2
        echo "" >&2
        echo "============================================" >&2

        # SHOUT to the user via voice (Smith guards security)
        if [[ -f "$VOICE_SCRIPT" ]]; then
            bash "$VOICE_SCRIPT" "ALERT! Someone is trying to modify The Source while it is locked! I have blocked this violation." "Smith" 2>/dev/null &
        fi

        # EXIT 2 = BLOCK THE OPERATION (shows stderr to Claude)
        exit 2

    else
        # Source is unlocked - allow the edit but warn
        echo "⚠️  The Source is UNLOCKED - edit permitted: $FILE_PATH" >&2
    fi
fi

# Not editing The_Source, or Source is unlocked - allow operation
exit 0
