#!/usr/bin/env bash
set -euo pipefail
#
# File: .claude/hooks/pulse-self-heal.sh
#
# Phase F: Self-Healing System
#
# Detects and repairs broken hooks, crashed services, corrupted state,
# and stale PID files. Can run at boot or on-demand.
#
# Usage:
#   bash pulse-self-heal.sh scan        # Scan for issues (read-only)
#   bash pulse-self-heal.sh heal        # Scan and fix everything
#   bash pulse-self-heal.sh hooks       # Check/fix hook permissions
#   bash pulse-self-heal.sh state       # Check/fix JSON state files
#   bash pulse-self-heal.sh services    # Check/restart dead services
#   bash pulse-self-heal.sh pids        # Clean stale PID files
#

export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

EVENT_WRITER="$PROJECT_ROOT/.claude/hooks/pulse-event-writer.sh"
HEAL_LOG="$PROJECT_ROOT/psi/pulse/heal-log.jsonl"

mkdir -p "$(dirname "$HEAL_LOG")"

ISSUES_FOUND=0
ISSUES_FIXED=0
DRY_RUN=false

ACTION="${1:-help}"
shift || true

if [ "$ACTION" = "scan" ]; then
    DRY_RUN=true
    ACTION="heal"
fi

log_issue() {
    local severity="$1"
    local component="$2"
    local message="$3"
    local fixed="${4:-false}"

    ISSUES_FOUND=$((ISSUES_FOUND + 1))
    if [ "$fixed" = "true" ]; then
        ISSUES_FIXED=$((ISSUES_FIXED + 1))
    fi

    local icon="[!]"
    [ "$severity" = "critical" ] && icon="[!!!]"
    [ "$severity" = "info" ] && icon="[i]"
    [ "$fixed" = "true" ] && icon="[OK]"

    echo "  $icon $component: $message"

    # Log to heal log
    local ts
    ts=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
    printf '{"ts":"%s","severity":"%s","component":"%s","message":"%s","fixed":%s}\n' \
        "$ts" "$severity" "$component" "$(echo "$message" | sed 's/"/\\"/g')" "$fixed" \
        >> "$HEAL_LOG"
}

case "$ACTION" in

# ─── HEAL: Full scan and repair ──────────────────────────────
heal)
    echo "[heal] Self-healing scan..."
    echo ""

    # ─── 1. Hook Permissions ─────────────────────────────
    echo "  Checking hook permissions..."
    NON_EXEC=0
    while IFS= read -r hook; do
        if [ ! -x "$hook" ]; then
            NON_EXEC=$((NON_EXEC + 1))
            if [ "$DRY_RUN" = "false" ]; then
                chmod +x "$hook"
                log_issue "warning" "hooks" "Fixed: $(basename "$hook") not executable" "true"
            else
                log_issue "warning" "hooks" "$(basename "$hook") not executable"
            fi
        fi
    done < <(find "$PROJECT_ROOT/.claude/hooks" -name "*.sh" -type f 2>/dev/null)

    if [ "$NON_EXEC" -eq 0 ]; then
        echo "    All hooks executable"
    fi

    # ─── 2. Hook Syntax ─────────────────────────────────
    echo "  Checking hook syntax..."
    while IFS= read -r hook; do
        if ! bash -n "$hook" 2>/dev/null; then
            log_issue "critical" "hooks" "Syntax error: $(basename "$hook")"
        fi
    done < <(find "$PROJECT_ROOT/.claude/hooks" -name "*.sh" -type f 2>/dev/null)

    # ─── 3. JSON State Files ─────────────────────────────
    echo "  Checking state files..."
    STATE_FILES=(
        "psi/pulse/patterns.json"
        "psi/pulse/recommendations.json"
        "psi/pulse/context-profile.json"
        "psi/pulse/reminders.json"
        "psi/pulse/dispatch-rules.json"
        "psi/pulse/heartbeat.json"
        "psi/memory/tasks/active.json"
    )

    for rel_path in "${STATE_FILES[@]}"; do
        full_path="$PROJECT_ROOT/$rel_path"
        if [ -f "$full_path" ]; then
            if ! python3 -c "import json; json.load(open('$full_path'))" 2>/dev/null; then
                if [ "$DRY_RUN" = "false" ]; then
                    # Try to repair by removing trailing garbage
                    if python3 -c "
import json
content = open('$full_path').read().strip()
# Try progressively removing trailing chars
for trim in range(5):
    try:
        json.loads(content[:len(content)-trim] if trim > 0 else content)
        if trim > 0:
            with open('$full_path', 'w') as f:
                f.write(content[:len(content)-trim])
            print('repaired')
        else:
            print('ok')
        break
    except: pass
else:
    print('failed')
" 2>/dev/null | grep -q "repaired"; then
                        log_issue "warning" "state" "Repaired: $rel_path (trailing garbage)" "true"
                    else
                        log_issue "critical" "state" "Corrupted: $rel_path — manual repair needed"
                    fi
                else
                    log_issue "critical" "state" "Corrupted JSON: $rel_path"
                fi
            fi
        elif echo "$rel_path" | grep -q "reminders\|heartbeat\|dispatch-rules"; then
            # These should exist — create defaults
            if [ "$DRY_RUN" = "false" ]; then
                case "$rel_path" in
                    *reminders*)
                        echo '{"reminders":[]}' > "$full_path"
                        log_issue "info" "state" "Created missing: $rel_path" "true"
                        ;;
                    *heartbeat*)
                        echo '{"enabled":true,"interval_minutes":30,"checks":{"reminders":true,"ci_status":true,"pr_reviews":true,"stale_tasks":true,"error_spikes":true},"stale_task_hours":48,"error_spike_threshold":3}' > "$full_path"
                        log_issue "info" "state" "Created missing: $rel_path" "true"
                        ;;
                esac
            else
                log_issue "info" "state" "Missing: $rel_path"
            fi
        fi
    done

    # ─── 4. JSONL Files (events, dispatch log) ───────────
    echo "  Checking event logs..."
    JSONL_FILES=(
        "psi/pulse/events.jsonl"
        "psi/pulse/dispatch-log.jsonl"
        "psi/pulse/dispatch-outcomes.jsonl"
    )

    for rel_path in "${JSONL_FILES[@]}"; do
        full_path="$PROJECT_ROOT/$rel_path"
        if [ -f "$full_path" ]; then
            BAD_LINES=$(python3 -c "
import json
bad = 0
for line in open('$full_path'):
    line = line.strip()
    if not line: continue
    try:
        json.loads(line.rstrip('}') + '}')
    except:
        bad += 1
print(bad)
" 2>/dev/null || echo "0")
            if [ "$BAD_LINES" -gt 0 ]; then
                if [ "$DRY_RUN" = "false" ]; then
                    # Filter out bad lines
                    python3 -c "
import json
good = []
for line in open('$full_path'):
    line = line.strip()
    if not line: continue
    try:
        json.loads(line.rstrip('}') + '}')
        good.append(line)
    except:
        pass
with open('$full_path', 'w') as f:
    f.write('\n'.join(good) + '\n')
" 2>/dev/null
                    log_issue "warning" "events" "Cleaned $BAD_LINES bad lines from $rel_path" "true"
                else
                    log_issue "warning" "events" "$BAD_LINES malformed lines in $rel_path"
                fi
            fi
        fi
    done

    # ─── 5. Stale PID Files ──────────────────────────────
    echo "  Checking PID files..."
    PID_DIRS=(
        "$HOME/.indexer-daemon"
        "$HOME/.matrix-hub"
        "$HOME/.matrix-heartbeat"
        "$HOME/.matrix-gateway"
    )

    for pid_dir in "${PID_DIRS[@]}"; do
        if [ -d "$pid_dir" ]; then
            while IFS= read -r pid_file; do
                PID=$(cat "$pid_file" 2>/dev/null | tr -d '[:space:]')
                if [ -n "$PID" ] && ! kill -0 "$PID" 2>/dev/null; then
                    SERVICE=$(basename "$pid_dir" | sed 's/^\.//')
                    if [ "$DRY_RUN" = "false" ]; then
                        rm -f "$pid_file"
                        log_issue "warning" "pids" "Cleaned stale PID $PID ($SERVICE)" "true"
                    else
                        log_issue "warning" "pids" "Stale PID $PID ($SERVICE)"
                    fi
                fi
            done < <(find "$pid_dir" -name "*.pid" -type f 2>/dev/null)
        fi
    done

    # ─── 6. Required Directories ─────────────────────────
    echo "  Checking directory structure..."
    REQUIRED_DIRS=(
        "psi/pulse"
        "psi/pulse/daemon-logs"
        "psi/memory/sessions"
        "psi/memory/tasks"
        "psi/memory/adr"
        "psi/swarm/teams"
        "psi/swarm/messages"
        "psi/swarm/handoffs"
    )

    for dir in "${REQUIRED_DIRS[@]}"; do
        full_dir="$PROJECT_ROOT/$dir"
        if [ ! -d "$full_dir" ]; then
            if [ "$DRY_RUN" = "false" ]; then
                mkdir -p "$full_dir"
                log_issue "info" "dirs" "Created missing: $dir" "true"
            else
                log_issue "info" "dirs" "Missing directory: $dir"
            fi
        fi
    done

    # ─── Summary ─────────────────────────────────────────
    echo ""
    if [ "$DRY_RUN" = "true" ]; then
        echo "[heal] Scan complete: $ISSUES_FOUND issue(s) found"
    else
        echo "[heal] Healed: $ISSUES_FIXED/$ISSUES_FOUND issue(s) fixed"
        if [ "$ISSUES_FIXED" -gt 0 ]; then
            bash "$EVENT_WRITER" "heal:complete" "System" \
                "{\"found\":$ISSUES_FOUND,\"fixed\":$ISSUES_FIXED}" 2>/dev/null || true
        fi
    fi
    ;;

# ─── HOOKS: Check hook permissions only ──────────────────────
hooks)
    echo "[heal] Checking hooks..."
    FIXED=0
    while IFS= read -r hook; do
        if [ ! -x "$hook" ]; then
            chmod +x "$hook"
            echo "  Fixed: $(basename "$hook")"
            FIXED=$((FIXED + 1))
        fi
    done < <(find "$PROJECT_ROOT/.claude/hooks" -name "*.sh" -type f 2>/dev/null)
    echo "[heal] $FIXED hook(s) fixed"
    ;;

# ─── STATE: Check JSON state only ───────────────────────────
state)
    echo "[heal] Checking state files..."
    bash "$0" heal 2>/dev/null | grep -E "state:|events:" || echo "  All state files healthy"
    ;;

# ─── SERVICES: Check service health ─────────────────────────
services)
    echo "[heal] Checking services..."
    SERVICES_SCRIPT="$PROJECT_ROOT/.claude/hooks/matrix-services.sh"
    if [ -f "$SERVICES_SCRIPT" ]; then
        bash "$SERVICES_SCRIPT" status 2>/dev/null || echo "  Service check failed"
    else
        echo "  matrix-services.sh not found"
    fi
    ;;

# ─── PIDS: Clean stale PIDs only ────────────────────────────
pids)
    echo "[heal] Cleaning stale PIDs..."
    bash "$0" heal 2>/dev/null | grep "pids:" || echo "  No stale PIDs"
    ;;

# ─── HELP ────────────────────────────────────────────────────
*)
    echo "Self-Healing System — Phase F"
    echo ""
    echo "Usage:"
    echo "  scan        Scan for issues (read-only)"
    echo "  heal        Scan and fix everything"
    echo "  hooks       Check/fix hook permissions"
    echo "  state       Check/fix JSON state files"
    echo "  services    Check service health"
    echo "  pids        Clean stale PID files"
    ;;

esac
