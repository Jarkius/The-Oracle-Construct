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
MATRIX_ROOT="$PROJECT_ROOT"

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

# ─── Deduplication guard ──────────────────────────────────────
# Prevent duplicate session:end events when Stop hook fires multiple times
DEDUP_DIR="$PROJECT_ROOT/.claude/.session-end-dedup"
mkdir -p "$DEDUP_DIR"
SID="${CLAUDE_SESSION_ID:-unknown}"
DEDUP_FILE="$DEDUP_DIR/$SID"
NOW_EPOCH=$(date +%s)
if [ -f "$DEDUP_FILE" ]; then
    LAST_EPOCH=$(cat "$DEDUP_FILE" 2>/dev/null || echo "0")
    DIFF=$((NOW_EPOCH - LAST_EPOCH))
    if [ "$DIFF" -lt 10 ]; then
        exit 0
    fi
fi
echo "$NOW_EPOCH" > "$DEDUP_FILE"
# Clean old dedup files (>1 hour old)
find "$DEDUP_DIR" -type f -mmin +60 -delete 2>/dev/null || true

# Log session end event
bash "$EVENT_WRITER" "session:end" "System" '{"reason":"stop_hook"}'

# ─── Build a meaningful session summary ──────────────────────
# Gather context from focus, tasks, and recent events
SUMMARY_PARTS=""

FOCUS=$(head -20 "$PROJECT_ROOT/psi/state/focus.md" 2>/dev/null | grep -A1 "Task:" | tail -1 || echo "")
[ -n "$FOCUS" ] && SUMMARY_PARTS="**Focus**: $FOCUS"

TASK_PENDING=$(grep -c '"status": "pending"' "$PROJECT_ROOT/psi/memory/tasks/active.json" 2>/dev/null || echo "0")
TASK_PROGRESS=$(grep -c '"status": "in_progress"' "$PROJECT_ROOT/psi/memory/tasks/active.json" 2>/dev/null || echo "0")
if [ "$TASK_PENDING" != "0" ] || [ "$TASK_PROGRESS" != "0" ]; then
    SUMMARY_PARTS="$SUMMARY_PARTS
**Tasks**: ${TASK_PROGRESS} in-progress, ${TASK_PENDING} pending"
fi

RECENT_COMMITS=$(git -C "$PROJECT_ROOT" log --oneline --since="1 hour ago" 2>/dev/null | head -5 || echo "")
[ -n "$RECENT_COMMITS" ] && SUMMARY_PARTS="$SUMMARY_PARTS
**Recent commits**:
$RECENT_COMMITS"

if [ -n "$SUMMARY_PARTS" ]; then
    FINAL_SUMMARY="$SUMMARY_PARTS"
else
    FINAL_SUMMARY="Session ended without explicit summary. Check retrospectives for details."
fi

# --- Auto-archive completed tasks before session save ---
TASK_SYNC="$PROJECT_ROOT/.claude/hooks/pulse-task-sync.sh"
if [ -f "$TASK_SYNC" ]; then
    bash "$TASK_SYNC" archive 2>/dev/null || true
fi

# Auto-save session memory to psi/ markdown (Phase 1)
SESSION_FILE=""
if [ -f "$MEMORY_SAVE" ]; then
    SESSION_FILE=$(bash "$MEMORY_SAVE" "auto-pulse" "$FINAL_SUMMARY" 2>/dev/null || echo "")
fi

# ─── ADR-010: Dual-layer persistence ────────────────────────────
# Save to SQLite (ChromaDB optional) if bun memory is available
MEMORY_LOG="$PROJECT_ROOT/psi/state/pulse/memory-errors.log"
if [ -d "$MATRIX_ROOT" ] && command -v bun &> /dev/null; then
    cd "$MATRIX_ROOT"

    # Save session to SQLite — log errors instead of hiding them
    if ! bun memory save "Auto-saved session via pulse hook" 2>>"$MEMORY_LOG"; then
        echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] bun memory save failed" >> "$MEMORY_LOG"
    fi

    # If we captured a markdown session file, also ingest it
    if [ -n "$SESSION_FILE" ] && [ -f "$SESSION_FILE" ]; then
        if ! bun memory learn "$SESSION_FILE" 2>>"$MEMORY_LOG"; then
            echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] bun memory learn failed for $SESSION_FILE" >> "$MEMORY_LOG"
        fi
    fi
fi

exit 0
