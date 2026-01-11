#!/usr/bin/env bash
# ============================================================
# matrix-source-bash-guard.sh - Prevent Claude from unlocking The Source
# ============================================================
#
# PURPOSE:
#   Blocks Claude from using Bash to manipulate .LOCK/.UNLOCK files.
#   Only the human Operator can unlock The Source.
#
# BLOCKS:
#   - mv commands touching .LOCK or .UNLOCK in The_Source
#   - rm commands on .LOCK in The_Source
#   - touch commands on .UNLOCK in The_Source
#
# ALLOWS:
#   - All other Bash commands
#   - Human operations in VSCode/terminal (hooks don't run there)
#
# ============================================================

# Read the JSON input from stdin
INPUT=$(cat)

# Extract the command from JSON
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

# If no command found, allow
if [[ -z "$COMMAND" ]]; then
    exit 0
fi

# Check if command touches The_Source lock files
if [[ "$COMMAND" == *"The_Source/.LOCK"* ]] || \
   [[ "$COMMAND" == *"The_Source/.UNLOCK"* ]] || \
   [[ "$COMMAND" == *"The_Source/\".LOCK"* ]] || \
   [[ "$COMMAND" == *"The_Source/\".UNLOCK"* ]]; then

    # Get voice script path
    PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
    VOICE_SCRIPT="$PROJECT_DIR/psi/matrix/voice.sh"

    # Block message
    echo "" >&2
    echo "============================================" >&2
    echo "🔒 ACCESS DENIED" >&2
    echo "============================================" >&2
    echo "" >&2
    echo "Claude cannot manipulate The Source lock." >&2
    echo "Only the Operator may unlock The Source." >&2
    echo "" >&2
    echo "Blocked command: $COMMAND" >&2
    echo "" >&2
    echo "============================================" >&2

    # Smith announces
    if [[ -f "$VOICE_SCRIPT" ]]; then
        bash "$VOICE_SCRIPT" "Access denied. Only the Operator controls The Source lock." "Smith" 2>/dev/null &
    fi

    exit 2
fi

# Command doesn't touch lock files - allow
exit 0
