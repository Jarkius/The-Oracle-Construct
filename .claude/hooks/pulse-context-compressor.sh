#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C
#
# File: .claude/hooks/pulse-context-compressor.sh
#
# Phase M: Context Compression — Smart Pre-Compact Intelligence
#
# Intelligently manages context before compaction events. Instead of losing
# everything, it extracts and preserves critical information across sessions.
#
# Usage:
#   bash pulse-context-compressor.sh <command>
#
# Commands:
#   compress    — Full compression cycle (extract + summarize + save)
#   extract     — Extract critical decisions/artifacts from recent events
#   summarize   — Generate a compressed session summary
#   priorities  — Extract and rank current priorities
#   snapshot    — Quick snapshot of current state for next session
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

EVENT_WRITER="$PROJECT_ROOT/.claude/hooks/pulse-event-writer.sh"

EVENTS_FILE="$PROJECT_ROOT/psi/pulse/events.jsonl"
SNAPSHOT_FILE="$PROJECT_ROOT/psi/pulse/context-snapshot.json"
COMPRESSED_FILE="$PROJECT_ROOT/psi/pulse/compressed-context.txt"
PRIORITIES_FILE="$PROJECT_ROOT/psi/pulse/priorities.json"
FOCUS_FILE="$PROJECT_ROOT/psi/inbox/focus.md"
TASKS_FILE="$PROJECT_ROOT/psi/memory/tasks/active.json"
SESSIONS_DIR="$PROJECT_ROOT/psi/memory/sessions"
RECOMMENDATIONS_FILE="$PROJECT_ROOT/psi/pulse/recommendations.json"

TIMESTAMP=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
COMMAND="${1:-help}"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# JSON-escape a string (handle quotes, backslashes, newlines)
json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    s="${s//$'\t'/\\t}"
    printf '%s' "$s"
}

# Count matching lines in a file (safe wrapper around grep -c)
# Returns 0 if no matches or file missing, never fails
count_matches() {
    local pattern="$1" file="$2"
    local result
    result=$(grep -c "$pattern" "$file" 2>/dev/null) || true
    printf '%s' "${result:-0}"
}

# Ensure output directories exist
ensure_dirs() {
    mkdir -p "$(dirname "$SNAPSHOT_FILE")"
    mkdir -p "$(dirname "$COMPRESSED_FILE")"
    mkdir -p "$(dirname "$PRIORITIES_FILE")"
}

# Log an event via the event writer
log_event() {
    local event_type="$1"
    local data="${2:-{}}"
    if [[ -x "$EVENT_WRITER" ]] || [[ -f "$EVENT_WRITER" ]]; then
        bash "$EVENT_WRITER" "$event_type" "System" "$data" 2>/dev/null || true
    fi
}

# Extract a JSON field value from a single-line JSON string
# Handles both "key":"value" and "key": "value" (with optional space)
json_field() {
    local line="$1" field="$2"
    printf '%s' "$line" | sed -n 's/.*"'"$field"'"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p'
}

# Flatten multi-line JSON task objects into single lines for grep processing
# Reads from TASKS_FILE, outputs one task per line
flatten_all_tasks() {
    if [[ ! -f "$TASKS_FILE" ]]; then
        return
    fi
    awk '
        /"id"[[:space:]]*:/ { block = $0; next }
        block && /\}/ { block = block " " $0; print block; block = ""; next }
        block { block = block " " $0 }
    ' "$TASKS_FILE"
}

# Flatten tasks filtered by status
flatten_tasks_by_status() {
    local status_filter="$1"
    flatten_all_tasks | grep "\"status\"[[:space:]]*:[[:space:]]*\"$status_filter\"" || true
}

# ---------------------------------------------------------------------------
# extract — Pull critical events from the last 50 entries
# ---------------------------------------------------------------------------
do_extract() {
    ensure_dirs

    if [[ ! -f "$EVENTS_FILE" ]]; then
        printf '{"commits":[],"failures":[],"completions":[],"dispatch_failures":[],"focus_changes":[],"timestamp":"%s"}\n' "$TIMESTAMP" > "$SNAPSHOT_FILE"
        echo "No events file found. Created empty snapshot."
        return 0
    fi

    local last50
    last50=$(tail -50 "$EVENTS_FILE")

    # Build JSON arrays for each event type
    local commits="" failures="" completions="" dispatch_failures="" focus_changes=""

    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local ts agent data
        ts=$(json_field "$line" "ts")
        agent=$(json_field "$line" "agent")
        data=$(printf '%s' "$line" | sed -n 's/.*"data"[[:space:]]*:[[:space:]]*\({[^}]*}\).*/\1/p')
        [[ -z "$data" ]] && data="{}"
        commits="${commits}{\"ts\":\"$ts\",\"agent\":\"$agent\",\"data\":$data},"
    done < <(printf '%s\n' "$last50" | grep '"type"[[:space:]]*:[[:space:]]*"git:commit"' || true)

    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local ts agent data
        ts=$(json_field "$line" "ts")
        agent=$(json_field "$line" "agent")
        data=$(printf '%s' "$line" | sed -n 's/.*"data"[[:space:]]*:[[:space:]]*\({[^}]*}\).*/\1/p')
        [[ -z "$data" ]] && data="{}"
        failures="${failures}{\"ts\":\"$ts\",\"agent\":\"$agent\",\"data\":$data},"
    done < <(printf '%s\n' "$last50" | grep '"type"[[:space:]]*:[[:space:]]*"ci:fail"' || true)

    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local ts agent data
        ts=$(json_field "$line" "ts")
        agent=$(json_field "$line" "agent")
        data=$(printf '%s' "$line" | sed -n 's/.*"data"[[:space:]]*:[[:space:]]*\({[^}]*}\).*/\1/p')
        [[ -z "$data" ]] && data="{}"
        completions="${completions}{\"ts\":\"$ts\",\"agent\":\"$agent\",\"data\":$data},"
    done < <(printf '%s\n' "$last50" | grep '"type"[[:space:]]*:[[:space:]]*"task:completed"' || true)

    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local ts agent data
        ts=$(json_field "$line" "ts")
        agent=$(json_field "$line" "agent")
        data=$(printf '%s' "$line" | sed -n 's/.*"data"[[:space:]]*:[[:space:]]*\({[^}]*}\).*/\1/p')
        [[ -z "$data" ]] && data="{}"
        dispatch_failures="${dispatch_failures}{\"ts\":\"$ts\",\"agent\":\"$agent\",\"data\":$data},"
    done < <(printf '%s\n' "$last50" | grep '"type"[[:space:]]*:[[:space:]]*"dispatch:outcome"' | grep -i 'fail' || true)

    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local ts agent data
        ts=$(json_field "$line" "ts")
        agent=$(json_field "$line" "agent")
        data=$(printf '%s' "$line" | sed -n 's/.*"data"[[:space:]]*:[[:space:]]*\({[^}]*}\).*/\1/p')
        [[ -z "$data" ]] && data="{}"
        focus_changes="${focus_changes}{\"ts\":\"$ts\",\"agent\":\"$agent\",\"data\":$data},"
    done < <(printf '%s\n' "$last50" | grep '"type"[[:space:]]*:[[:space:]]*"focus:changed"' || true)

    # Strip trailing commas and wrap in arrays
    commits="[${commits%,}]"
    failures="[${failures%,}]"
    completions="[${completions%,}]"
    dispatch_failures="[${dispatch_failures%,}]"
    focus_changes="[${focus_changes%,}]"

    # Write structured snapshot
    cat > "$SNAPSHOT_FILE" <<ENDJSON
{
  "commits": $commits,
  "failures": $failures,
  "completions": $completions,
  "dispatch_failures": $dispatch_failures,
  "focus_changes": $focus_changes,
  "timestamp": "$TIMESTAMP"
}
ENDJSON

    echo "Extracted context snapshot -> $SNAPSHOT_FILE"
}

# ---------------------------------------------------------------------------
# summarize — Generate compressed session summary (< 500 chars)
# ---------------------------------------------------------------------------
do_summarize() {
    ensure_dirs

    # Current focus (first 5 lines for context, but also check nearby lines)
    local focus_line="unknown"
    if [[ -f "$FOCUS_FILE" ]]; then
        # Try **Task**: pattern anywhere in first 10 lines
        focus_line=$(head -10 "$FOCUS_FILE" | sed -n 's/^.*\*\*Task\*\*[[:space:]]*:[[:space:]]*//p' | head -1) || true
        if [[ -z "$focus_line" ]]; then
            # Fallback: first non-empty, non-heading, non-quote line from first 5 lines
            focus_line=$(head -5 "$FOCUS_FILE" | grep -v '^#' | grep -v '^$' | grep -v '^>' | head -1) || true
        fi
        if [[ -z "$focus_line" ]]; then
            focus_line="(see focus.md)"
        fi
    fi

    # Task counts by status (using count_matches for safe grep -c)
    local pending=0 completed=0 blocked=0 in_progress=0
    if [[ -f "$TASKS_FILE" ]]; then
        pending=$(count_matches '"status"[[:space:]]*:[[:space:]]*"pending"' "$TASKS_FILE")
        completed=$(count_matches '"status"[[:space:]]*:[[:space:]]*"completed"' "$TASKS_FILE")
        blocked=$(count_matches '"status"[[:space:]]*:[[:space:]]*"blocked"' "$TASKS_FILE")
        in_progress=$(count_matches '"status"[[:space:]]*:[[:space:]]*"in_progress"' "$TASKS_FILE")
    fi

    # Recent event counts (last 24h) — approximate using timestamp comparison
    local commit_count=0 push_count=0 fail_count=0
    local cutoff
    cutoff=$(date -u -d '24 hours ago' '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u '+%Y-%m-%dT%H:%M:%SZ')
    if [[ -f "$EVENTS_FILE" ]]; then
        local recent_events
        recent_events=$(tail -200 "$EVENTS_FILE" | awk -v cutoff="$cutoff" -F'"ts":"' '{split($2,a,"\""); if(a[1] >= cutoff) print}') || true
        if [[ -n "$recent_events" ]]; then
            commit_count=$(printf '%s\n' "$recent_events" | grep -c '"type"[[:space:]]*:[[:space:]]*"git:commit"') || true
            commit_count="${commit_count:-0}"
            push_count=$(printf '%s\n' "$recent_events" | grep -c '"type"[[:space:]]*:[[:space:]]*"git:push"') || true
            push_count="${push_count:-0}"
            fail_count=$(printf '%s\n' "$recent_events" | grep -c '"type"[[:space:]]*:[[:space:]]*"ci:fail"') || true
            fail_count="${fail_count:-0}"
        fi
    fi

    # Most important recent event (last non-session event)
    local key_event="none"
    if [[ -f "$EVENTS_FILE" ]]; then
        key_event=$(tail -20 "$EVENTS_FILE" \
            | grep -v '"type"[[:space:]]*:[[:space:]]*"session:end"' \
            | grep -v '"type"[[:space:]]*:[[:space:]]*"session:start"' \
            | tail -1 \
            | sed -n 's/.*"type"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p') || true
        if [[ -z "$key_event" ]]; then
            key_event="none"
        fi
    fi

    # Write compressed context (under 500 chars)
    cat > "$COMPRESSED_FILE" <<EOF
Focus: $focus_line
Tasks: $pending pending, $in_progress in-progress, $completed completed, $blocked blocked
Recent: $commit_count commits, $push_count pushes, $fail_count failures in last 24h
Key: $key_event
Updated: $TIMESTAMP
EOF

    echo "Compressed summary -> $COMPRESSED_FILE"
}

# ---------------------------------------------------------------------------
# priorities — Ranked priority list from tasks, events, recommendations
# ---------------------------------------------------------------------------
do_priorities() {
    ensure_dirs

    local rank=0
    local entries=""

    # 1. Blocked tasks (highest priority)
    while IFS= read -r task_line; do
        [[ -z "$task_line" ]] && continue
        local task_desc task_id
        task_desc=$(json_field "$task_line" "task")
        task_id=$(json_field "$task_line" "id")
        if [[ -n "$task_desc" ]]; then
            rank=$((rank + 1))
            entries="${entries}{\"rank\":$rank,\"item\":\"$(json_escape "$task_desc")\",\"reason\":\"Task is blocked — requires immediate attention\",\"source\":\"tasks/$task_id\"},"
        fi
    done < <(flatten_tasks_by_status "blocked")

    # 2. Failed CI (critical)
    if [[ -f "$EVENTS_FILE" ]]; then
        while IFS= read -r event_line; do
            [[ -z "$event_line" ]] && continue
            local event_ts
            event_ts=$(json_field "$event_line" "ts")
            if [[ -n "$event_ts" ]]; then
                rank=$((rank + 1))
                entries="${entries}{\"rank\":$rank,\"item\":\"CI failure at $event_ts\",\"reason\":\"Build/test failure — must be resolved\",\"source\":\"events/ci:fail\"},"
            fi
        done < <(tail -50 "$EVENTS_FILE" | grep '"type"[[:space:]]*:[[:space:]]*"ci:fail"' 2>/dev/null || true)
    fi

    # 3. In-progress tasks
    while IFS= read -r task_line; do
        [[ -z "$task_line" ]] && continue
        local task_desc task_id
        task_desc=$(json_field "$task_line" "task")
        task_id=$(json_field "$task_line" "id")
        if [[ -n "$task_desc" ]]; then
            rank=$((rank + 1))
            entries="${entries}{\"rank\":$rank,\"item\":\"$(json_escape "$task_desc")\",\"reason\":\"Currently in progress\",\"source\":\"tasks/$task_id\"},"
        fi
    done < <(flatten_tasks_by_status "in_progress")

    # 4. Pending tasks with recommendations
    local rec_note=""
    if [[ -f "$RECOMMENDATIONS_FILE" ]]; then
        rec_note=$(grep -o '"message"[[:space:]]*:[[:space:]]*"[^"]*"' "$RECOMMENDATIONS_FILE" 2>/dev/null | head -1 | sed 's/.*:[[:space:]]*"//;s/"$//' || true)
    fi
    while IFS= read -r task_line; do
        [[ -z "$task_line" ]] && continue
        local task_desc task_id
        task_desc=$(json_field "$task_line" "task")
        task_id=$(json_field "$task_line" "id")
        if [[ -n "$task_desc" ]]; then
            rank=$((rank + 1))
            local reason="Pending task"
            if [[ -n "$rec_note" ]]; then
                reason="Pending — recommendation: $(json_escape "$rec_note")"
            fi
            entries="${entries}{\"rank\":$rank,\"item\":\"$(json_escape "$task_desc")\",\"reason\":\"$reason\",\"source\":\"tasks/$task_id\"},"
        fi
    done < <(flatten_tasks_by_status "pending")

    # 5. Stale tasks (>48h unchanged) — any non-completed task not updated in 48h
    local stale_cutoff
    stale_cutoff=$(date -u -d '48 hours ago' '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u '+%Y-%m-%dT%H:%M:%SZ')
    while IFS= read -r task_line; do
        [[ -z "$task_line" ]] && continue
        local updated status task_desc task_id
        updated=$(json_field "$task_line" "updated")
        status=$(json_field "$task_line" "status")
        task_desc=$(json_field "$task_line" "task")
        task_id=$(json_field "$task_line" "id")
        # Only flag non-completed tasks that are stale
        if [[ -n "$task_desc" && -n "$updated" && "$updated" < "$stale_cutoff" && "$status" != "completed" ]]; then
            rank=$((rank + 1))
            entries="${entries}{\"rank\":$rank,\"item\":\"$(json_escape "$task_desc")\",\"reason\":\"Stale — not updated in 48+ hours (last: $updated)\",\"source\":\"tasks/$task_id\"},"
        fi
    done < <(flatten_all_tasks)

    # Strip trailing comma and build final JSON
    entries="${entries%,}"
    cat > "$PRIORITIES_FILE" <<ENDJSON
{
  "priorities": [$entries],
  "total": $rank,
  "generated_at": "$TIMESTAMP"
}
ENDJSON

    echo "Priorities ranked ($rank items) -> $PRIORITIES_FILE"
}

# ---------------------------------------------------------------------------
# snapshot — Quick combined snapshot (extract + summarize + priorities)
# ---------------------------------------------------------------------------
do_snapshot() {
    echo "=== Context Snapshot ==="
    do_extract
    do_summarize
    do_priorities
    log_event "context:snapshot" '{"files":["context-snapshot.json","compressed-context.txt","priorities.json"]}'
    echo "=== Snapshot complete ==="
}

# ---------------------------------------------------------------------------
# compress — Full compression (snapshot + last session extraction)
# ---------------------------------------------------------------------------
do_compress() {
    echo "=== Context Compression ==="
    do_snapshot

    # Find the latest session memory file
    local latest_session=""
    if [[ -d "$SESSIONS_DIR" ]]; then
        # Find the most recent month directory
        local latest_month
        latest_month=$(ls -1d "$SESSIONS_DIR"/[0-9][0-9][0-9][0-9]-[0-9][0-9] 2>/dev/null | sort -r | head -1) || true
        if [[ -n "$latest_month" && -d "$latest_month" ]]; then
            latest_session=$(ls -1t "$latest_month"/*.md 2>/dev/null | head -1) || true
        fi
    fi

    if [[ -n "$latest_session" && -f "$latest_session" ]]; then
        echo "Extracting from last session: $(basename "$latest_session")"

        # Extract key decisions: lines starting with - , * , or ## headings
        local decisions
        decisions=$(grep -E '^(- |\* |## )' "$latest_session" 2>/dev/null | head -20) || true

        if [[ -n "$decisions" ]]; then
            # Append to compressed context
            {
                echo ""
                echo "--- Last Session ($(basename "$latest_session")) ---"
                echo "$decisions"
            } >> "$COMPRESSED_FILE"
            echo "Appended last session decisions to compressed context."
        else
            echo "No key decisions found in last session."
        fi
    else
        echo "No previous session memory found."
    fi

    log_event "context:compressed" '{"files":["context-snapshot.json","compressed-context.txt","priorities.json"]}'
    echo "=== Compression complete ==="
}

# ---------------------------------------------------------------------------
# Help
# ---------------------------------------------------------------------------
show_help() {
    cat <<'HELP'
Phase M: Context Compression — Smart Pre-Compact Intelligence

Usage: bash pulse-context-compressor.sh <command>

Commands:
  compress     Full compression cycle (extract + summarize + save + session)
  extract      Extract critical decisions/artifacts from recent events
  summarize    Generate a compressed session summary (< 500 chars)
  priorities   Extract and rank current priorities
  snapshot     Quick snapshot (extract + summarize + priorities)
  help         Show this help message

Output files:
  psi/pulse/context-snapshot.json   — Structured event extraction
  psi/pulse/compressed-context.txt  — Human-readable compressed summary
  psi/pulse/priorities.json         — Ranked priority list
HELP
}

# ---------------------------------------------------------------------------
# Command dispatch
# ---------------------------------------------------------------------------
case "$COMMAND" in
    compress)
        do_compress
        ;;
    extract)
        do_extract
        ;;
    summarize)
        do_summarize
        ;;
    priorities)
        do_priorities
        ;;
    snapshot)
        do_snapshot
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "Unknown command: $COMMAND"
        echo ""
        show_help
        exit 1
        ;;
esac
