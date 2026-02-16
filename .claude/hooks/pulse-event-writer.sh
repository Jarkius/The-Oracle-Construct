#!/usr/bin/env bash
set -euo pipefail
#
# File: .claude/hooks/pulse-event-writer.sh
#
# Phase 5.2: Event Queue Writer
# Appends events to psi/pulse/events.jsonl (append-only JSONL)
#
# Usage: bash pulse-event-writer.sh <event_type> <agent> [data_json]
#
# Examples:
#   bash pulse-event-writer.sh "git:push" "Neo" '{"branch":"main","commits":2}'
#   bash pulse-event-writer.sh "task:completed" "Oracle" '{"task_id":"task-001"}'
#   bash pulse-event-writer.sh "session:end" "System"
#

export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

EVENTS_FILE="$PROJECT_ROOT/psi/pulse/events.jsonl"
mkdir -p "$(dirname "$EVENTS_FILE")"

EVENT_TYPE="${1:-unknown}"
AGENT="${2:-System}"
DATA="${3:-{}}"

TIMESTAMP=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
SESSION_ID="${CLAUDE_SESSION_ID:-unknown}"

# Write event as single JSON line
printf '{"ts":"%s","type":"%s","agent":"%s","session":"%s","data":%s}\n' \
    "$TIMESTAMP" "$EVENT_TYPE" "$AGENT" "$SESSION_ID" "$DATA" \
    >> "$EVENTS_FILE"

# Rotate if file exceeds 1000 lines (keep last 500)
LINE_COUNT=$(wc -l < "$EVENTS_FILE" 2>/dev/null || echo "0")
if [ "$LINE_COUNT" -gt 1000 ]; then
    tail -500 "$EVENTS_FILE" > "$EVENTS_FILE.tmp"
    mv "$EVENTS_FILE.tmp" "$EVENTS_FILE"
fi
