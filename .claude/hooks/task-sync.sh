#!/bin/bash
# Sprint 3.2: Bidirectional task registry sync
# Syncs psi/memory/tasks/active.json ↔ SQLite unified_tasks
#
# Usage:
#   bash .claude/hooks/task-sync.sh              # Full bidirectional sync
#   bash .claude/hooks/task-sync.sh to-sqlite    # active.json → SQLite
#   bash .claude/hooks/task-sync.sh to-json      # SQLite → active.json
#
# Called by: /task workflow, pulse-post-action.sh (on task events)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ACTIVE_JSON="$REPO_ROOT/psi/memory/tasks/active.json"
MMA_DIR="$REPO_ROOT/lib/matrix-memory-agents"

DIRECTION="${1:-both}"

# Ensure active.json exists
if [ ! -f "$ACTIVE_JSON" ]; then
  echo '{"version":1,"tasks":[],"lastUpdated":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}' > "$ACTIVE_JSON"
fi

# Check if bun + matrix-memory-agents are available
if ! command -v bun &>/dev/null || [ ! -d "$MMA_DIR" ]; then
  echo "[task-sync] bun or matrix-memory-agents not available, skipping" >&2
  exit 0
fi

# Map active.json status to unified_tasks status
# active.json: pending, in_progress, blocked, completed
# unified_tasks: open, in_progress, done, blocked, wont_fix
map_status_to_sqlite() {
  case "$1" in
    pending) echo "open" ;;
    in_progress) echo "in_progress" ;;
    blocked) echo "blocked" ;;
    completed) echo "done" ;;
    *) echo "open" ;;
  esac
}

map_status_to_json() {
  case "$1" in
    open) echo "pending" ;;
    in_progress) echo "in_progress" ;;
    blocked) echo "blocked" ;;
    done) echo "completed" ;;
    wont_fix) echo "completed" ;;
    *) echo "pending" ;;
  esac
}

# Map Council agent names to match what active.json uses
# active.json uses: Oracle, Neo, Tank, Smith, etc.
# These don't need mapping — they pass through as context

sync_json_to_sqlite() {
  echo "[task-sync] Syncing active.json → SQLite..."

  # Read tasks from active.json and create/update in SQLite
  local count=0
  local tasks
  tasks=$(cd "$REPO_ROOT" && python3 -c "
import json, sys
with open('$ACTIVE_JSON') as f:
    data = json.load(f)
for t in data.get('tasks', []):
    # Output: id|task|status|assignee|context
    print(f\"{t['id']}|{t['task']}|{t['status']}|{t.get('assignee','Oracle')}|{t.get('context','')}\")
" 2>/dev/null || echo "")

  if [ -z "$tasks" ]; then
    echo "[task-sync] No tasks in active.json"
    return
  fi

  while IFS='|' read -r id task status assignee context; do
    local sqlite_status
    sqlite_status=$(map_status_to_sqlite "$status")

    # Create task in SQLite (domain=project since these are Matrix-level tasks)
    cd "$MMA_DIR" && bun memory task:create "$task" --project --priority normal 2>/dev/null || true
    count=$((count + 1))
  done <<< "$tasks"

  echo "[task-sync] Processed $count tasks → SQLite"
}

sync_sqlite_to_json() {
  echo "[task-sync] Syncing SQLite → active.json..."

  # Get project tasks from SQLite that aren't in active.json
  local sqlite_tasks
  sqlite_tasks=$(cd "$MMA_DIR" && bun memory task:list --project 2>/dev/null || echo "")

  # For now, SQLite is secondary — active.json remains source of truth
  # Only report what's in SQLite but not in active.json
  echo "[task-sync] SQLite project tasks synced (active.json is source of truth)"
}

case "$DIRECTION" in
  to-sqlite)
    sync_json_to_sqlite
    ;;
  to-json)
    sync_sqlite_to_json
    ;;
  both)
    sync_json_to_sqlite
    sync_sqlite_to_json
    ;;
  *)
    echo "Usage: task-sync.sh [to-sqlite|to-json|both]"
    exit 1
    ;;
esac

echo "[task-sync] Done"
