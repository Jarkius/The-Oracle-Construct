#!/usr/bin/env bash
# ============================================================
# matrix-source-guard.sh - The Source Protection Enforcement
# ============================================================
#
# PURPOSE:
#   Guards The Source (psi/The_Source/) from unauthorized writes.
#   The Source is ALWAYS protected unless explicitly unlocked.
#
# PROTOCOL:
#   If .UNLOCK exists → Allow the edit (temporary access)
#   If .UNLOCK absent → BLOCK the edit (default protected)
#
# USAGE:
#   Called automatically by Claude Code PreToolUse hook
#   Receives tool data via JSON on stdin (Claude Code hook protocol)
#
# TO UNLOCK:
#   touch psi/The_Source/.UNLOCK
#
# TO RE-LOCK:
#   rm psi/The_Source/.UNLOCK
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
UNLOCK_FILE="$PROJECT_DIR/psi/The_Source/.UNLOCK"
VOICE_SCRIPT="$PROJECT_DIR/psi/matrix/voice.sh"

# Only check if we're editing something in The_Source
if [[ "$FILE_PATH" == *"psi/The_Source"* ]]; then

    # Check if .UNLOCK exists (temporary access granted)
    if [[ -f "$UNLOCK_FILE" ]]; then
        # Source is unlocked - allow the edit but warn
        echo "⚠️  The Source is UNLOCKED - edit permitted: $FILE_PATH" >&2
        exit 0
    fi

    # === NO UNLOCK = VIOLATION DETECTED ===

    # Echo warning to stderr (visible to Claude and user)
    echo "" >&2
    echo "============================================" >&2
    echo "🔒 THE SOURCE IS PROTECTED" >&2
    echo "============================================" >&2
    echo "" >&2
    echo "EDIT BLOCKED:" >&2
    echo "  File: $FILE_PATH" >&2
    echo "" >&2
    echo "The Source is sacred and protected by default." >&2
    echo "" >&2
    echo "To unlock temporarily:" >&2
    echo "  touch psi/The_Source/.UNLOCK" >&2
    echo "" >&2
    echo "To re-lock when done:" >&2
    echo "  rm psi/The_Source/.UNLOCK" >&2
    echo "" >&2
    echo "============================================" >&2

    # SHOUT to the user via voice (Smith guards security)
    if [[ -f "$VOICE_SCRIPT" ]]; then
        bash "$VOICE_SCRIPT" "The Source is protected. Create UNLOCK to grant access." "Smith" 2>/dev/null &
    fi

    # EXIT 2 = BLOCK THE OPERATION (shows stderr to Claude)
    exit 2

fi

# Not editing The_Source - allow operation
exit 0
