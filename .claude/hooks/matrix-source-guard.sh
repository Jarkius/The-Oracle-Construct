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
#   Receives file path via CLAUDE_FILE_PATH environment variable
#
# ============================================================

set -euo pipefail

# Get the file being edited from Claude's environment
FILE_PATH="${CLAUDE_FILE_PATH:-}"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
LOCK_FILE="$PROJECT_DIR/psi/The_Source/.LOCK"
VOICE_SCRIPT="$PROJECT_DIR/psi/matrix/voice.sh"

# Only check if we're editing something in The_Source
if [[ "$FILE_PATH" == *"psi/The_Source"* ]]; then

    # Check if .LOCK exists
    if [[ -f "$LOCK_FILE" ]]; then

        # === VIOLATION DETECTED ===

        # Echo warning to console (visible in Claude output)
        echo ""
        echo "============================================"
        echo "🔒 THE SOURCE IS LOCKED"
        echo "============================================"
        echo ""
        echo "VIOLATION ATTEMPT BLOCKED:"
        echo "  File: $FILE_PATH"
        echo "  Lock: $LOCK_FILE"
        echo ""
        echo "The Source is sacred. The .LOCK file protects it."
        echo ""
        echo "To unlock, the Operator must:"
        echo "  rm psi/The_Source/.LOCK"
        echo ""
        echo "Then re-lock when done:"
        echo "  touch psi/The_Source/.LOCK"
        echo ""
        echo "============================================"

        # SHOUT to the user via voice (Smith guards security)
        if [[ -f "$VOICE_SCRIPT" ]]; then
            bash "$VOICE_SCRIPT" "ALERT! Someone is trying to modify The Source while it is locked! I have blocked this violation." "Smith" 2>/dev/null || true
        fi

        # EXIT 1 = BLOCK THE OPERATION
        exit 1

    else
        # Source is unlocked - allow the edit but warn
        echo "⚠️  The Source is UNLOCKED - edit permitted: $FILE_PATH"
    fi
fi

# Not editing The_Source, or Source is unlocked - allow operation
exit 0
