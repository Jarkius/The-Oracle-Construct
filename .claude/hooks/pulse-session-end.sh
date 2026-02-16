#!/usr/bin/env bash
set -euo pipefail
#
# File: .claude/hooks/pulse-session-end.sh
#
# Phase 5.1: Session End Hook
# Auto-saves session memory and logs session:end event.
# Runs async on Stop hook — does NOT block exit.
#

export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

EVENT_WRITER="$PROJECT_ROOT/.claude/hooks/pulse-event-writer.sh"
MEMORY_SAVE="$PROJECT_ROOT/.claude/hooks/session-memory-save.sh"

# Log session end event
bash "$EVENT_WRITER" "session:end" "System" '{"reason":"stop_hook"}'

# Auto-save session memory (minimal — no slug means "session")
if [ -f "$MEMORY_SAVE" ]; then
    bash "$MEMORY_SAVE" "auto-pulse" 2>/dev/null || true
fi

exit 0
