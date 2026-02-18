#!/usr/bin/env bash
set -euo pipefail
#
# File: .claude/hooks/pulse-session-continuity.sh
#
# Phase N: Cross-Session Continuity — Structured Handoff Generation
#
# Generates structured handoff documents when sessions end, ensuring the
# next session can pick up exactly where the last one left off.
#
# Usage:
#   bash pulse-session-continuity.sh generate   — Full continuity document
#   bash pulse-session-continuity.sh quick       — One-paragraph handoff
#   bash pulse-session-continuity.sh diff        — Changes since last snapshot
#   bash pulse-session-continuity.sh chain       — Last 5 continuity handoffs
#   bash pulse-session-continuity.sh inject      — Output continuity for boot injection
#

export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

EVENT_WRITER="$PROJECT_ROOT/.claude/hooks/pulse-event-writer.sh"
HANDOFF_DIR="$PROJECT_ROOT/psi/swarm/handoffs"
CONTINUITY_FILE="$PROJECT_ROOT/psi/pulse/continuity.md"

FOCUS_FILE="$PROJECT_ROOT/psi/inbox/focus.md"
ACTIVE_TASKS="$PROJECT_ROOT/psi/memory/tasks/active.json"
EVENTS_FILE="$PROJECT_ROOT/psi/pulse/events.jsonl"

# Ensure directories exist
mkdir -p "$HANDOFF_DIR"
mkdir -p "$(dirname "$CONTINUITY_FILE")"

# ─── Helpers ─────────────────────────────────────────────────────

get_timestamp() {
    date -u '+%Y-%m-%dT%H:%M:%SZ'
}

get_date_stamp() {
    date -u '+%Y-%m-%d'
}

get_focus_task() {
    if [ -f "$FOCUS_FILE" ]; then
        grep -m1 '^\*\*Task\*\*:' "$FOCUS_FILE" 2>/dev/null | sed 's/\*\*Task\*\*: *//' || echo "No focus task found"
    else
        echo "No focus file found"
    fi
}

get_recent_commits() {
    local since="${1:-}"
    local args=("--oneline" "-n" "10")
    if [ -n "$since" ]; then
        args+=("--since=$since")
    fi
    cd "$PROJECT_ROOT"
    git log "${args[@]}" 2>/dev/null || echo "No commits found"
}

get_current_branch() {
    cd "$PROJECT_ROOT"
    git branch --show-current 2>/dev/null || echo "unknown"
}

is_working_tree_clean() {
    cd "$PROJECT_ROOT"
    if git diff --quiet 2>/dev/null && git diff --cached --quiet 2>/dev/null; then
        echo "yes"
    else
        echo "no"
    fi
}

get_uncommitted_count() {
    cd "$PROJECT_ROOT"
    local count
    count=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    echo "$count"
}

get_active_tasks() {
    if [ -f "$ACTIVE_TASKS" ]; then
        # Extract non-completed tasks: id, task, status
        local task_id=""
        local task_desc=""
        local task_status=""
        local output=""

        while IFS= read -r line; do
            case "$line" in
                *'"id":'*)
                    task_id=$(echo "$line" | sed 's/.*"id": *"//;s/".*//')
                    ;;
                *'"task":'*)
                    task_desc=$(echo "$line" | sed 's/.*"task": *"//;s/".*//')
                    ;;
                *'"status":'*)
                    task_status=$(echo "$line" | sed 's/.*"status": *"//;s/".*//')
                    if [ "$task_status" != "completed" ] && [ -n "$task_id" ]; then
                        output="${output}- **${task_id}** [${task_status}]: ${task_desc}"$'\n'
                    fi
                    task_id=""
                    task_desc=""
                    task_status=""
                    ;;
            esac
        done < "$ACTIVE_TASKS"

        if [ -n "$output" ]; then
            echo "$output"
        else
            echo "No active tasks"
        fi
    else
        echo "No task registry found"
    fi
}

get_unresolved_failures() {
    if [ ! -f "$EVENTS_FILE" ]; then
        echo "No events log found"
        return
    fi

    local failures=""
    local has_failures=0

    # Get recent ci:fail events (last 50 lines for performance)
    local fail_events
    fail_events=$(tail -50 "$EVENTS_FILE" 2>/dev/null | grep '"ci:fail"' || true)

    if [ -n "$fail_events" ]; then
        local has_pass
        has_pass=$(tail -50 "$EVENTS_FILE" 2>/dev/null | grep '"ci:pass"' | tail -1 || true)

        local last_fail_ts
        last_fail_ts=$(echo "$fail_events" | tail -1 | sed 's/.*"ts":"\([^"]*\)".*/\1/' || true)
        local last_pass_ts=""

        if [ -n "$has_pass" ]; then
            last_pass_ts=$(echo "$has_pass" | sed 's/.*"ts":"\([^"]*\)".*/\1/' || true)
        fi

        # If last failure is after last pass (or no pass exists), it's unresolved
        if [ -z "$last_pass_ts" ] || [[ "$last_fail_ts" > "$last_pass_ts" ]]; then
            failures="- CI failure detected at ${last_fail_ts} — not yet resolved"
            has_failures=1
        fi
    fi

    # Check for dispatch failures in recent events
    local dispatch_fails
    dispatch_fails=$(tail -50 "$EVENTS_FILE" 2>/dev/null | grep '"dispatch:fail\|"error"' || true)

    if [ -n "$dispatch_fails" ]; then
        local count
        count=$(echo "$dispatch_fails" | wc -l | tr -d ' ')
        failures="${failures:+${failures}
}- ${count} dispatch/error event(s) in recent log"
        has_failures=1
    fi

    if [ "$has_failures" -eq 0 ]; then
        echo "None detected"
    else
        echo "$failures"
    fi
}

get_next_steps() {
    if [ -f "$FOCUS_FILE" ]; then
        # Look for unchecked items after "Next Priority" or similar headers
        local in_next=0
        local found=""

        while IFS= read -r line; do
            if echo "$line" | grep -qi "next\|priority\|todo\|upcoming"; then
                in_next=1
                continue
            fi
            if [ "$in_next" -eq 1 ]; then
                # Look for unchecked markdown checkboxes
                if echo "$line" | grep -q '^\- \[ \]'; then
                    found="$line"
                    break
                fi
                # Also accept plain list items
                if echo "$line" | grep -q '^\- ' && [ -z "$found" ]; then
                    found="$line"
                    break
                fi
                # Stop at next header
                if echo "$line" | grep -q '^#'; then
                    break
                fi
            fi
        done < "$FOCUS_FILE"

        if [ -n "$found" ]; then
            echo "$found"
        else
            echo "Review focus.md for next priorities"
        fi
    else
        echo "No focus file — set priorities with /oracle"
    fi
}

get_running_services() {
    local services=""
    local found=0
    for pidfile in "$HOME"/.matrix-*.pid; do
        if [ -f "$pidfile" ] 2>/dev/null; then
            found=1
            local name
            name=$(basename "$pidfile" | sed 's/^\.matrix-//;s/\.pid$//')
            local pid
            pid=$(cat "$pidfile" 2>/dev/null || echo "")
            if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
                services="${services:+${services}, }${name} (running)"
            else
                services="${services:+${services}, }${name} (stale PID)"
            fi
        fi
    done

    if [ "$found" -eq 0 ] || [ -z "$services" ]; then
        echo "None detected"
    else
        echo "$services"
    fi
}

get_last_continuity_timestamp() {
    if [ -f "$CONTINUITY_FILE" ]; then
        # Extract timestamp from first heading
        head -1 "$CONTINUITY_FILE" | sed 's/# Session Continuity — //' || echo ""
    else
        echo ""
    fi
}

# ─── Commands ────────────────────────────────────────────────────

cmd_generate() {
    local timestamp
    timestamp=$(get_timestamp)
    local date_stamp
    date_stamp=$(get_date_stamp)

    local focus_task
    focus_task=$(get_focus_task)

    local last_ts
    last_ts=$(get_last_continuity_timestamp)

    local recent_commits
    if [ -n "$last_ts" ]; then
        recent_commits=$(get_recent_commits "$last_ts")
    else
        recent_commits=$(get_recent_commits)
    fi

    local active_tasks
    active_tasks=$(get_active_tasks)

    local unfinished
    unfinished=$(get_unresolved_failures)

    local next_steps
    next_steps=$(get_next_steps)

    local branch
    branch=$(get_current_branch)

    local clean
    clean=$(is_working_tree_clean)

    local services
    services=$(get_running_services)

    # Build the continuity document
    cat > "$CONTINUITY_FILE" << EOF
# Session Continuity — ${timestamp}

## What Was Happening
${focus_task}

## What Changed This Session
${recent_commits}

## Active Work
${active_tasks}
## Unfinished Business
${unfinished}

## Next Steps
${next_steps}

## Environment State
- Branch: ${branch}
- Clean: ${clean}
- Services: ${services}

---
*Auto-generated by Phase N: Session Continuity*
EOF

    # Save a dated copy to handoffs
    local handoff_file="${HANDOFF_DIR}/${date_stamp}_continuity.md"
    cp "$CONTINUITY_FILE" "$handoff_file"

    # Log event
    if [ -f "$EVENT_WRITER" ]; then
        bash "$EVENT_WRITER" "continuity:generated" "System" "{\"file\":\"${handoff_file}\"}" 2>/dev/null || true
    fi

    echo "Continuity document generated:"
    echo "  Primary: ${CONTINUITY_FILE}"
    echo "  Handoff: ${handoff_file}"
}

cmd_quick() {
    local focus_task
    focus_task=$(get_focus_task)

    local branch
    branch=$(get_current_branch)

    local uncommitted
    uncommitted=$(get_uncommitted_count)

    local last_commit
    cd "$PROJECT_ROOT"
    last_commit=$(git log --oneline -1 2>/dev/null | cut -c1-60 || echo "no commits")

    # Build a single paragraph under 280 chars
    local summary="Focus: ${focus_task}. Branch: ${branch}. ${uncommitted} uncommitted change(s). Last commit: ${last_commit}."

    # Truncate to 280 chars if needed
    if [ ${#summary} -gt 280 ]; then
        summary="${summary:0:277}..."
    fi

    echo "$summary"
}

cmd_diff() {
    local last_ts
    last_ts=$(get_last_continuity_timestamp)

    if [ -z "$last_ts" ] || [ ! -f "$CONTINUITY_FILE" ]; then
        echo "No prior continuity snapshot found. Run 'generate' first."
        return 1
    fi

    echo "=== Changes since last continuity snapshot (${last_ts}) ==="
    echo ""

    # New commits
    echo "--- New Commits ---"
    cd "$PROJECT_ROOT"
    local new_commits
    new_commits=$(git log --oneline --since="$last_ts" 2>/dev/null || true)
    if [ -n "$new_commits" ]; then
        echo "$new_commits"
    else
        echo "No new commits"
    fi
    echo ""

    # Task status changes
    echo "--- Active Tasks (current) ---"
    get_active_tasks
    echo ""

    # New events since last snapshot
    echo "--- New Events ---"
    if [ -f "$EVENTS_FILE" ]; then
        local new_events
        new_events=$(while IFS= read -r line; do
            local ev_ts
            ev_ts=$(echo "$line" | sed 's/.*"ts":"\([^"]*\)".*/\1/' 2>/dev/null || true)
            if [ -n "$ev_ts" ] && [[ "$ev_ts" > "$last_ts" ]]; then
                local ev_type
                ev_type=$(echo "$line" | sed 's/.*"type":"\([^"]*\)".*/\1/' 2>/dev/null || true)
                local ev_agent
                ev_agent=$(echo "$line" | sed 's/.*"agent":"\([^"]*\)".*/\1/' 2>/dev/null || true)
                echo "  [${ev_ts}] ${ev_type} (${ev_agent})"
            fi
        done < <(tail -50 "$EVENTS_FILE" 2>/dev/null))

        if [ -n "$new_events" ]; then
            echo "$new_events"
        else
            echo "No new events since last snapshot"
        fi
    else
        echo "No events log found"
    fi
}

cmd_chain() {
    echo "=== Continuity Chain (last 5 handoffs) ==="
    echo ""

    # Find continuity handoffs sorted by date (newest first)
    local handoffs
    handoffs=$(ls -1r "$HANDOFF_DIR"/*_continuity.md 2>/dev/null | head -5 || true)

    if [ -z "$handoffs" ]; then
        echo "No continuity handoffs found in ${HANDOFF_DIR}"
        return 0
    fi

    local count=0
    while IFS= read -r file; do
        count=$((count + 1))
        local filename
        filename=$(basename "$file")
        local date_part
        date_part=$(echo "$filename" | sed 's/_continuity\.md$//')

        # Get first line of "What Was Happening" section
        local what=""
        local in_section=0
        while IFS= read -r line; do
            if echo "$line" | grep -q '^## What Was Happening'; then
                in_section=1
                continue
            fi
            if [ "$in_section" -eq 1 ] && [ -n "$line" ] && ! echo "$line" | grep -q '^##'; then
                what="$line"
                break
            fi
        done < "$file"

        echo "${count}. [${date_part}] ${what:-<empty>}"
    done <<< "$handoffs"
}

cmd_inject() {
    if [ -f "$CONTINUITY_FILE" ]; then
        cat "$CONTINUITY_FILE"
    else
        echo "# Session Continuity"
        echo ""
        echo "No prior continuity data. This appears to be a fresh start."
        echo "Run \`bash .claude/hooks/pulse-session-continuity.sh generate\` to create a snapshot."
    fi
}

# ─── Command Router ──────────────────────────────────────────────

COMMAND="${1:-help}"

case "$COMMAND" in
    generate)
        cmd_generate
        ;;
    quick)
        cmd_quick
        ;;
    diff)
        cmd_diff
        ;;
    chain)
        cmd_chain
        ;;
    inject)
        cmd_inject
        ;;
    help|--help|-h)
        echo "Phase N: Cross-Session Continuity — Structured Handoff Generation"
        echo ""
        echo "Usage: bash $(basename "$0") <command>"
        echo ""
        echo "Commands:"
        echo "  generate  — Generate a full continuity document for next session"
        echo "  quick     — Quick one-paragraph handoff (under 280 chars)"
        echo "  diff      — Show what changed since last continuity snapshot"
        echo "  chain     — Show continuity chain (last 5 handoffs)"
        echo "  inject    — Output continuity context for session injection"
        echo "  help      — Show this help message"
        ;;
    *)
        echo "Unknown command: ${COMMAND}"
        echo "Run 'bash $(basename "$0") help' for usage."
        exit 1
        ;;
esac
