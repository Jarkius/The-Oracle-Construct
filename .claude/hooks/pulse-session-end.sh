#!/usr/bin/env bash
set -euo pipefail
#
# File: .claude/hooks/pulse-session-end.sh
#
# Phase 5.1 + ADR-010 + WEP-004: Session End Hook
# Auto-saves session memory to both psi/ markdown AND SQLite/ChromaDB.
# Triggers distillation to extract patterns from recent sessions.
# Runs async on Stop hook — does NOT block exit.
#

export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MMA_DIR="$PROJECT_ROOT/lib/matrix-memory-agents"

EVENT_WRITER="$PROJECT_ROOT/.claude/hooks/pulse-event-writer.sh"
MEMORY_SAVE="$PROJECT_ROOT/.claude/hooks/session-memory-save.sh"

# ─── WEP-004: Extract session ID from Stop hook stdin JSON ────
# Stop hook receives JSON with session_id on stdin. Parse and export
# so event writer and memory save can use it.
HOOK_INPUT=$(cat 2>/dev/null || echo '{}')
if [ -z "${CLAUDE_SESSION_ID:-}" ] || [ "${CLAUDE_SESSION_ID:-}" = "unknown" ]; then
    PARSED_SID=$(echo "$HOOK_INPUT" | grep -o '"session_id":"[^"]*"' | head -1 | cut -d'"' -f4 || echo "")
    if [ -n "$PARSED_SID" ]; then
        export CLAUDE_SESSION_ID="$PARSED_SID"
    fi
fi

# Log session end event
bash "$EVENT_WRITER" "session:end" "System" '{"reason":"stop_hook"}'

# Auto-save session memory to psi/ markdown (Phase 1)
SESSION_FILE=""
if [ -f "$MEMORY_SAVE" ]; then
    SESSION_FILE=$(bash "$MEMORY_SAVE" "auto-pulse" 2>/dev/null || echo "")
fi

# ─── ADR-010: Dual-layer persistence ────────────────────────────
# Save to SQLite + ChromaDB if matrix-memory-agents is available
if [ -d "$MMA_DIR" ] && command -v bun &> /dev/null; then
    cd "$MMA_DIR"

    # Save session to SQLite
    bun memory save "Auto-saved session via pulse hook" 2>/dev/null || true

    # If we captured a markdown session file, also ingest it
    if [ -n "$SESSION_FILE" ] && [ -f "$SESSION_FILE" ]; then
        bun memory learn "$SESSION_FILE" 2>/dev/null || true
    fi

    # Trigger distillation — extract patterns from recent sessions
    bun memory distill 2>/dev/null || true
fi

exit 0
