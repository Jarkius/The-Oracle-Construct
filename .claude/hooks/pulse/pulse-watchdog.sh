#!/usr/bin/env bash
set -euo pipefail
#
# File: .claude/hooks/pulse-watchdog.sh
#
# Phase G: Watchdog — Service Monitor + Auto-Restart
#
# Lightweight daemon that monitors all Matrix services.
# Restarts crashed services, reports failures, tracks uptime.
#
# Usage:
#   bash pulse-watchdog.sh start          # Start watchdog (background)
#   bash pulse-watchdog.sh stop           # Stop watchdog
#   bash pulse-watchdog.sh status         # Check watchdog status
#   bash pulse-watchdog.sh check          # Run one check cycle
#   bash pulse-watchdog.sh report         # Show uptime report
#

export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

WATCHDOG_DIR="$HOME/.matrix-watchdog"
PID_FILE="$WATCHDOG_DIR/watchdog.pid"
LOG_FILE="$PROJECT_ROOT/psi/state/pulse/daemon-logs/watchdog.log"
STATUS_FILE="$PROJECT_ROOT/psi/state/pulse/watchdog-status.json"
EVENT_WRITER="$PROJECT_ROOT/.claude/hooks/pulse/pulse-event-writer.sh"
SERVICES_SCRIPT="$PROJECT_ROOT/.claude/hooks/core/matrix-services.sh"
SELF_HEAL="$PROJECT_ROOT/.claude/hooks/pulse/pulse-self-heal.sh"

CHECK_INTERVAL="${WATCHDOG_INTERVAL:-120}"  # seconds between checks
MAX_RESTARTS=3  # max restarts per service per hour

mkdir -p "$WATCHDOG_DIR" "$(dirname "$LOG_FILE")"

ACTION="${1:-help}"
shift || true

wlog() {
    echo "[watchdog $(date -u '+%Y-%m-%dT%H:%M:%SZ')] $*" >> "$LOG_FILE"
}

# ─── Service Health Checks ───────────────────────────────────

check_service() {
    local service="$1"
    local port="$2"
    local pid_file="$3"

    # Check PID
    if [ -f "$pid_file" ]; then
        local pid
        pid=$(cat "$pid_file" 2>/dev/null | tr -d '[:space:]')
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            # Process alive — check HTTP if port provided
            if [ "$port" -gt 0 ] 2>/dev/null; then
                if curl -sf "http://127.0.0.1:$port/status" --max-time 3 >/dev/null 2>&1; then
                    echo "running"
                    return 0
                else
                    echo "unresponsive"
                    return 1
                fi
            fi
            echo "running"
            return 0
        fi
    fi
    echo "stopped"
    return 1
}

restart_service() {
    local service="$1"
    wlog "Restarting $service..."

    if [ -f "$SERVICES_SCRIPT" ]; then
        bash "$SERVICES_SCRIPT" stop "$service" 2>/dev/null || true
        sleep 1
        bash "$SERVICES_SCRIPT" start "$service" 2>/dev/null
        local result=$?

        if [ $result -eq 0 ]; then
            wlog "$service restarted successfully"
            bash "$EVENT_WRITER" "watchdog:restart" "Watchdog" \
                "{\"service\":\"$service\",\"result\":\"success\"}" 2>/dev/null || true
            return 0
        else
            wlog "$service restart FAILED"
            bash "$EVENT_WRITER" "watchdog:restart_failed" "Watchdog" \
                "{\"service\":\"$service\",\"result\":\"failed\"}" 2>/dev/null || true
            return 1
        fi
    fi
    return 1
}

# ─── Check Cycle ─────────────────────────────────────────────

run_check() {
    local now
    now=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

    # Load restart counters
    declare -A restart_counts
    if [ -f "$STATUS_FILE" ]; then
        while IFS='=' read -r key val; do
            restart_counts["$key"]="$val"
        done < <(python3 -c "
import json
data = json.load(open('$STATUS_FILE'))
for s, info in data.get('services', {}).items():
    print(f'{s}={info.get(\"restarts_this_hour\", 0)}')
" 2>/dev/null || true)
    fi

    # Define services to monitor
    declare -A services
    services[heartbeat]="37892:$HOME/.matrix-heartbeat/heartbeat.pid"
    services[gateway]="8082:$HOME/.matrix-gateway/gateway.pid"
    services[indexer]="37890:$HOME/.indexer-daemon/indexer.pid"
    services[hub]="8081:$HOME/.matrix-hub/hub.pid"

    local status_json='{"checked_at":"'"$now"'","services":{'
    local first=true
    local any_issues=false

    for service in "${!services[@]}"; do
        IFS=':' read -r port pid_file <<< "${services[$service]}"

        local state
        state=$(check_service "$service" "$port" "$pid_file")

        local restarts=${restart_counts[$service]:-0}
        local restarted=false

        if [ "$state" != "running" ]; then
            any_issues=true

            # Only restart if under max restarts
            if [ "$restarts" -lt "$MAX_RESTARTS" ]; then
                # Only restart services that were previously configured/started
                if [ -f "$pid_file" ] || [ "$state" = "unresponsive" ]; then
                    if restart_service "$service"; then
                        state="restarted"
                        restarted=true
                        restarts=$((restarts + 1))
                    else
                        state="failed"
                    fi
                fi
            else
                wlog "$service: max restarts ($MAX_RESTARTS) reached this hour — skipping"
                state="max_restarts"
            fi
        fi

        if [ "$first" = "true" ]; then
            first=false
        else
            status_json+=','
        fi
        status_json+="\"$service\":{\"status\":\"$state\",\"port\":$port,\"restarts_this_hour\":$restarts,\"last_restarted\":$restarted}"
    done

    status_json+='}}'

    # Save status
    echo "$status_json" | python3 -c "
import json, sys
data = json.load(sys.stdin)
with open('$STATUS_FILE', 'w') as f:
    json.dump(data, f, indent=2)
" 2>/dev/null || echo "$status_json" > "$STATUS_FILE"

    # Run self-heal if issues found
    if [ "$any_issues" = "true" ] && [ -f "$SELF_HEAL" ]; then
        wlog "Running self-heal scan..."
        bash "$SELF_HEAL" heal >> "$LOG_FILE" 2>&1 || true
    fi

    echo "[watchdog] Check complete at $now"
}

case "$ACTION" in

# ─── START: Run watchdog as background daemon ────────────────
start)
    if [ -f "$PID_FILE" ]; then
        EXISTING_PID=$(cat "$PID_FILE" 2>/dev/null | tr -d '[:space:]')
        if [ -n "$EXISTING_PID" ] && kill -0 "$EXISTING_PID" 2>/dev/null; then
            echo "[watchdog] Already running (PID $EXISTING_PID)"
            exit 0
        fi
    fi

    echo "[watchdog] Starting (check every ${CHECK_INTERVAL}s)..."

    # Fork to background
    (
        echo $$ > "$PID_FILE"
        wlog "Watchdog started (PID $$, interval ${CHECK_INTERVAL}s)"
        bash "$EVENT_WRITER" "watchdog:start" "Watchdog" \
            "{\"pid\":$$,\"interval\":$CHECK_INTERVAL}" 2>/dev/null || true

        trap 'wlog "Watchdog stopping"; rm -f "$PID_FILE"; exit 0' SIGTERM SIGINT

        while true; do
            run_check >> "$LOG_FILE" 2>&1 || true
            sleep "$CHECK_INTERVAL"
        done
    ) &

    disown
    sleep 1

    if [ -f "$PID_FILE" ]; then
        echo "[watchdog] Started (PID $(cat "$PID_FILE"))"
    else
        echo "[watchdog] Failed to start"
        exit 1
    fi
    ;;

# ─── STOP: Stop the watchdog ────────────────────────────────
stop)
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE" 2>/dev/null | tr -d '[:space:]')
        if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
            kill "$PID" 2>/dev/null || true
            rm -f "$PID_FILE"
            wlog "Watchdog stopped"
            bash "$EVENT_WRITER" "watchdog:stop" "Watchdog" '{}' 2>/dev/null || true
            echo "[watchdog] Stopped"
        else
            rm -f "$PID_FILE"
            echo "[watchdog] Not running (cleaned stale PID)"
        fi
    else
        echo "[watchdog] Not running"
    fi
    ;;

# ─── STATUS: Show watchdog status ───────────────────────────
status)
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE" 2>/dev/null | tr -d '[:space:]')
        if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
            echo "[watchdog] Running (PID $PID)"
        else
            echo "[watchdog] Not running (stale PID)"
        fi
    else
        echo "[watchdog] Not running"
    fi

    if [ -f "$STATUS_FILE" ]; then
        echo ""
        python3 -c "
import json
data = json.load(open('$STATUS_FILE'))
print(f'Last check: {data.get(\"checked_at\", \"never\")}')
for name, info in data.get('services', {}).items():
    status = info.get('status', 'unknown')
    restarts = info.get('restarts_this_hour', 0)
    icon = 'OK' if status == 'running' else 'XX'
    print(f'  [{icon}] {name}: {status} (restarts: {restarts})')
" 2>/dev/null
    fi
    ;;

# ─── CHECK: Run one check cycle ─────────────────────────────
check)
    run_check
    ;;

# ─── REPORT: Uptime report ──────────────────────────────────
report)
    echo "=== Watchdog Report ==="
    echo ""

    bash "$0" status 2>/dev/null || true

    echo ""
    echo "=== Recent Events ==="
    if [ -f "$LOG_FILE" ]; then
        tail -20 "$LOG_FILE" 2>/dev/null | grep -E "restart|FAILED|started|stopped" || echo "  No recent events"
    fi
    ;;

# ─── HELP ────────────────────────────────────────────────────
*)
    echo "Watchdog Daemon — Phase G"
    echo ""
    echo "Usage:"
    echo "  start       Start watchdog (background daemon)"
    echo "  stop        Stop watchdog"
    echo "  status      Show watchdog + service status"
    echo "  check       Run one check cycle"
    echo "  report      Full uptime report"
    echo ""
    echo "Env: WATCHDOG_INTERVAL=120 (seconds between checks)"
    ;;

esac
