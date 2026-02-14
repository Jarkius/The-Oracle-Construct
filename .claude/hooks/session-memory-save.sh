#!/usr/bin/env bash
set -euo pipefail
#
# File: .claude/hooks/session-memory-save.sh
#
# Auto-Session Memory Hook (Phase 1 - Autonomy Evolution)
# Called at session end or manually via /snapshot
#
# Saves a session summary to psi/memory/sessions/YYYY-MM-DD-HH.MM-slug.md
# This ensures knowledge is never lost between sessions.
#
# Learning From: OpenClaw src/hooks/bundled/session-memory/handler.ts
#

export LC_ALL=C

# Get project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Session storage
SESSIONS_DIR="$PROJECT_ROOT/psi/memory/sessions"
mkdir -p "$SESSIONS_DIR"

# Date components
DATE=$(date '+%Y-%m-%d')
TIME=$(date '+%H.%M')
YEAR_MONTH=$(date '+%Y-%m')

# Create year-month subdirectory (matches retrospectives pattern)
mkdir -p "$SESSIONS_DIR/$YEAR_MONTH"

# Generate session filename
# If a slug argument is provided, use it; otherwise use "session"
SLUG="${1:-session}"
# Sanitize slug: lowercase, spaces to dashes, strip non-alphanumeric
SLUG=$(echo "$SLUG" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-')
SLUG="${SLUG:0:50}" # Truncate to 50 chars

SESSION_FILE="$SESSIONS_DIR/$YEAR_MONTH/${DATE}_${TIME}_${SLUG}.md"

# If a summary is provided via stdin or as second arg, use it
SUMMARY="${2:-}"

if [ -z "$SUMMARY" ] && [ ! -t 0 ]; then
    # Read from stdin if available
    SUMMARY=$(cat)
fi

if [ -z "$SUMMARY" ]; then
    # Default minimal session marker
    SUMMARY="Session ended without explicit summary. Check retrospectives for details."
fi

# Write session file
cat > "$SESSION_FILE" << HEREDOC
# Session Memory: $DATE $TIME

> *Auto-captured by session-memory-save hook*

**Date**: $DATE $TIME
**Session ID**: ${CLAUDE_SESSION_ID:-unknown}

## Summary

$SUMMARY

## Context Snapshot

- **Focus at end**: $(head -20 "$PROJECT_ROOT/psi/inbox/focus.md" 2>/dev/null | grep -A1 "Task:" | tail -1 || echo "Unknown")
- **Active tasks**: $(cat "$PROJECT_ROOT/psi/memory/tasks/active.json" 2>/dev/null | grep -c '"status": "pending"' || echo "0") pending

---

*Auto-saved by Phase 1: Memory & Persistence*
HEREDOC

echo "$SESSION_FILE"
