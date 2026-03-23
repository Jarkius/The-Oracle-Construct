#!/usr/bin/env bash
set -euo pipefail
#
# File: .claude/hooks/pulse-task-sync.sh
#
# Task Registry Auto-Sync
# Updates active.json based on signals: git commits, PR merges, agent completion.
# Called from: TaskCompleted hook, session-end hook, /rrr workflow, or manually.
#
# Usage:
#   bash .claude/hooks/pulse-task-sync.sh complete <task-id>    # Mark task done
#   bash .claude/hooks/pulse-task-sync.sh archive               # Archive completed tasks
#   bash .claude/hooks/pulse-task-sync.sh reconcile             # Match tasks against git/events
#

export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TASKS_FILE="$PROJECT_ROOT/psi/memory/tasks/active.json"
ARCHIVE_DIR="$PROJECT_ROOT/psi/memory/tasks/archive"
EVENT_WRITER="$PROJECT_ROOT/.claude/hooks/pulse-event-writer.sh"

# Platform: find a working python
PY=""
for candidate in python3 python; do
    if $candidate -c "import json" &>/dev/null 2>&1; then
        PY="$candidate"
        break
    fi
done
# Windows fallback: explicit path (Windows Store alias can fail in subshells)
if [ -z "$PY" ]; then
    for p in \
        "$HOME/AppData/Local/Programs/Python/Python312/python.exe" \
        "$HOME/AppData/Local/Programs/Python/Python311/python.exe" \
        "$HOME/AppData/Local/Programs/Python/Python310/python.exe"; do
        if [ -x "$p" ]; then
            PY="$p"
            break
        fi
    done
fi

if [ ! -f "$TASKS_FILE" ]; then
    echo "[task-sync] No active.json found"
    exit 0
fi

ACTION="${1:-reconcile}"
shift || true

TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date +%Y-%m-%dT%H:%M:%SZ)

# ─── Action: Complete a specific task ──────────────────────────
if [ "$ACTION" = "complete" ]; then
    TASK_ID="${1:-}"
    if [ -z "$TASK_ID" ] || [ -z "$PY" ]; then
        echo "[task-sync] Usage: pulse-task-sync.sh complete <task-id>"
        exit 1
    fi

    $PY "$SCRIPT_DIR/pulse-task-sync-helper.py" complete "$TASKS_FILE" "$TASK_ID" "$TIMESTAMP"

    if [ -f "$EVENT_WRITER" ]; then
        bash "$EVENT_WRITER" "task:completed" "System" "{\"task_id\":\"$TASK_ID\",\"via\":\"pulse-task-sync\"}" 2>/dev/null &
    fi
    exit 0
fi

# ─── Action: Archive completed tasks ──────────────────────────
if [ "$ACTION" = "archive" ]; then
    COMPLETED_COUNT=$(grep -c '"completed"' "$TASKS_FILE" 2>/dev/null | tr -d '[:space:]' || echo "0")
    if [ "${COMPLETED_COUNT:-0}" -eq 0 ] 2>/dev/null; then
        echo "[task-sync] No completed tasks to archive"
        exit 0
    fi
    if [ -z "$PY" ]; then
        echo "[task-sync] No python available"; exit 1
    fi

    mkdir -p "$ARCHIVE_DIR"
    DATE_SLUG=$(date +%Y-%m-%d)
    ARCHIVE_FILE="$ARCHIVE_DIR/${DATE_SLUG}_archived.json"

    $PY "$SCRIPT_DIR/pulse-task-sync-helper.py" archive "$TASKS_FILE" "$ARCHIVE_FILE" "$TIMESTAMP"
    exit 0
fi

# ─── Action: Reconcile tasks against reality ──────────────────
if [ "$ACTION" = "reconcile" ]; then
    if [ -z "$PY" ]; then
        echo "[task-sync] No python available"; exit 1
    fi

    echo "[task-sync] Reconciling tasks against git history and events..."

    EVENTS_FILE="$PROJECT_ROOT/psi/state/pulse/events.jsonl"
    $PY "$SCRIPT_DIR/pulse-task-sync-helper.py" reconcile "$TASKS_FILE" "$EVENTS_FILE" "$TIMESTAMP" "$PROJECT_ROOT"
    exit 0
fi

echo "[task-sync] Unknown action: $ACTION"
echo "Usage: pulse-task-sync.sh [complete <id> | archive | reconcile]"
exit 1
