#!/usr/bin/env bash
# ============================================================
# matrix-lock-check.sh - Cross-Worktree File Lock Enforcement
# ============================================================
#
# PURPOSE:
#   Prevents agents from editing files locked by other agents.
#   Part of the ADR-019 coordination layer.
#
# PROTOCOL:
#   Reads the target file path from PreToolUse JSON input.
#   Computes SHA256 hash → checks ~/.matrix/coordination/locks/
#   If locked by another agent → BLOCK (exit 2)
#   If unlocked or owned by this agent → ALLOW (exit 0)
#   If no CLAUDE_AGENT_ID set (solo mode) → ALLOW (backward compat)
#
# EXIT CODES:
#   0 = Allow the operation
#   2 = Block the operation (file locked by another agent)
#
# ============================================================

# Read JSON input from stdin
INPUT=$(cat)

# Extract file path from JSON
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

# No file path = not a file edit, allow
if [[ -z "$FILE_PATH" ]]; then
    exit 0
fi

# No agent ID = solo mode (human session), skip lock checks
AGENT_ID="${CLAUDE_AGENT_ID:-}"
if [[ -z "$AGENT_ID" ]]; then
    exit 0
fi

# Coordination lock directory
LOCK_DIR="$HOME/.matrix/coordination/locks"

# If lock directory doesn't exist, no active coordination session
if [[ ! -d "$LOCK_DIR" ]]; then
    exit 0
fi

# Normalize the file path to be relative to project root
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
RELATIVE_PATH="${FILE_PATH#$PROJECT_DIR/}"

# Compute SHA256 hash of the relative path
if command -v sha256sum &>/dev/null; then
    FILE_HASH=$(echo -n "$RELATIVE_PATH" | sha256sum | cut -d' ' -f1)
elif command -v shasum &>/dev/null; then
    FILE_HASH=$(echo -n "$RELATIVE_PATH" | shasum -a 256 | cut -d' ' -f1)
else
    # Can't compute hash — allow (fail open for compatibility)
    exit 0
fi

LOCK_FILE="$LOCK_DIR/${FILE_HASH}.lock"

# No lock file = file is not locked, allow
if [[ ! -f "$LOCK_FILE" ]]; then
    # Also check parent directories (directory locks)
    # Walk up the path checking for directory locks
    CHECK_PATH="$RELATIVE_PATH"
    while [[ "$CHECK_PATH" == *"/"* ]]; do
        CHECK_PATH="${CHECK_PATH%/*}/"
        if command -v sha256sum &>/dev/null; then
            DIR_HASH=$(echo -n "$CHECK_PATH" | sha256sum | cut -d' ' -f1)
        else
            DIR_HASH=$(echo -n "$CHECK_PATH" | shasum -a 256 | cut -d' ' -f1)
        fi
        DIR_LOCK="$LOCK_DIR/${DIR_HASH}.lock"
        if [[ -f "$DIR_LOCK" ]]; then
            LOCK_FILE="$DIR_LOCK"
            break
        fi
    done

    # Still no lock found
    if [[ ! -f "$LOCK_FILE" ]]; then
        exit 0
    fi
fi

# Lock file exists — check ownership
LOCK_OWNER=$(jq -r '.owner // empty' "$LOCK_FILE" 2>/dev/null)
LOCK_EXPIRES=$(jq -r '.expiresAt // empty' "$LOCK_FILE" 2>/dev/null)
LOCK_PATH=$(jq -r '.path // empty' "$LOCK_FILE" 2>/dev/null)

# Same owner — re-entrant lock, allow
if [[ "$LOCK_OWNER" == "$AGENT_ID" ]]; then
    exit 0
fi

# Check expiry (compare ISO timestamps)
if [[ -n "$LOCK_EXPIRES" ]]; then
    NOW=$(date -u '+%Y-%m-%dT%H:%M:%S')
    if [[ "$NOW" > "$LOCK_EXPIRES" ]]; then
        # Lock expired — remove it and allow
        rm -f "$LOCK_FILE"
        exit 0
    fi
fi

# === LOCKED BY ANOTHER AGENT ===
echo "" >&2
echo "============================================" >&2
echo "FILE LOCKED — Edit Blocked" >&2
echo "============================================" >&2
echo "" >&2
echo "  File:  $RELATIVE_PATH" >&2
echo "  Owner: $LOCK_OWNER" >&2
echo "  Lock:  $LOCK_PATH" >&2
echo "" >&2
echo "This file is currently owned by another agent." >&2
echo "Wait for them to complete or request a handoff." >&2
echo "============================================" >&2

exit 2
