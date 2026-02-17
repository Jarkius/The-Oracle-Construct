#!/usr/bin/env bash
set -euo pipefail
#
# File: .claude/hooks/matrix-services.sh
#
# Phase 9 (ADR-011): Unified Daemon Service Manager
# Single entry point for all Matrix daemon lifecycle operations.
#
# Usage:
#   matrix-services.sh start [service]    Start one or all services
#   matrix-services.sh stop [service]     Stop one or all services
#   matrix-services.sh status             Health check all services
#   matrix-services.sh restart [service]  Restart one or all services
#
# Services: indexer, hub
#
# Design principles:
#   - Zero idle cost: services only start when requested
#   - Graceful degradation: if one fails, others continue
#   - PID-based management with stale detection
#   - HTTP health checks where available
#

export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MMA_DIR="$PROJECT_ROOT/lib/matrix-memory-agents"
LOG_DIR="$PROJECT_ROOT/psi/pulse/daemon-logs"

mkdir -p "$LOG_DIR"

# ─── Service Definitions ──────────────────────────────────────

# Indexer Daemon
INDEXER_SCRIPT="$MMA_DIR/src/indexer/indexer-daemon.ts"
INDEXER_PID_DIR="${HOME}/.indexer-daemon"
INDEXER_DEFAULT_PORT=37890

# Matrix Hub
HUB_SCRIPT="$MMA_DIR/src/matrix-hub.ts"
HUB_PID_FILE="${HOME}/.matrix-hub/hub.pid"
HUB_DEFAULT_PORT=8081

# ─── Helpers ──────────────────────────────────────────────────

check_bun() {
    if ! command -v bun &> /dev/null; then
        echo "[matrix-services] ERROR: bun not found. Install bun first."
        return 1
    fi
}

check_mma() {
    if [ ! -d "$MMA_DIR" ]; then
        echo "[matrix-services] ERROR: matrix-memory-agents not found at $MMA_DIR"
        return 1
    fi
}

get_matrix_id() {
    local config_file="$PROJECT_ROOT/.matrix.json"
    if [ -f "$config_file" ]; then
        grep -o '"matrix_id":"[^"]*"' "$config_file" | head -1 | cut -d'"' -f4 || basename "$PROJECT_ROOT"
    else
        basename "$PROJECT_ROOT"
    fi
}

# Get indexer PID file (same hash logic as indexer-daemon.ts)
get_indexer_pid_file() {
    local matrix_id
    matrix_id=$(get_matrix_id)
    echo "${INDEXER_PID_DIR}/daemon-${matrix_id}.pid"
}

# Check if a process is alive by PID
is_process_alive() {
    local pid="$1"
    kill -0 "$pid" 2>/dev/null
}

# Check if a port is listening
is_port_open() {
    local port="$1"
    if command -v lsof &> /dev/null; then
        lsof -ti :"$port" &>/dev/null
    elif command -v ss &> /dev/null; then
        ss -tlnp | grep -q ":$port " 2>/dev/null
    elif command -v netstat &> /dev/null; then
        netstat -tlnp 2>/dev/null | grep -q ":$port "
    else
        # Fallback: try connecting
        (echo > /dev/tcp/localhost/"$port") 2>/dev/null
    fi
}

# Read PID from file, validate it's alive
read_pid() {
    local pid_file="$1"
    if [ -f "$pid_file" ]; then
        local pid
        pid=$(cat "$pid_file" 2>/dev/null | grep -o '[0-9]*' | head -1)
        if [ -n "$pid" ] && is_process_alive "$pid"; then
            echo "$pid"
            return 0
        else
            # Stale PID file — clean up
            rm -f "$pid_file" 2>/dev/null
        fi
    fi
    return 1
}

# Query HTTP health endpoint
http_health() {
    local port="$1"
    local path="${2:-/status}"
    curl -s --connect-timeout 2 --max-time 5 "http://localhost:${port}${path}" 2>/dev/null
}

# ─── Indexer Service ──────────────────────────────────────────

indexer_start() {
    local pid_file
    pid_file=$(get_indexer_pid_file)

    if pid=$(read_pid "$pid_file" 2>/dev/null); then
        echo "[indexer] Already running (PID $pid)"
        return 0
    fi

    check_bun || return 1
    check_mma || return 1

    echo "[indexer] Starting..."
    mkdir -p "$INDEXER_PID_DIR"

    cd "$MMA_DIR"
    nohup bun run src/indexer/indexer-daemon.ts start --initial \
        > "$LOG_DIR/indexer.log" 2>&1 &

    local bg_pid=$!
    sleep 2

    if is_process_alive "$bg_pid"; then
        echo "[indexer] Started (PID $bg_pid)"
    else
        echo "[indexer] FAILED to start. Check $LOG_DIR/indexer.log"
        return 1
    fi
}

indexer_stop() {
    local pid_file
    pid_file=$(get_indexer_pid_file)

    if ! pid=$(read_pid "$pid_file" 2>/dev/null); then
        echo "[indexer] Not running"
        return 0
    fi

    echo "[indexer] Stopping (PID $pid)..."

    # Try graceful HTTP stop first
    if is_port_open "$INDEXER_DEFAULT_PORT"; then
        curl -s -X POST "http://localhost:${INDEXER_DEFAULT_PORT}/stop" 2>/dev/null || true
        sleep 1
    fi

    # If still alive, SIGTERM
    if is_process_alive "$pid"; then
        kill -TERM "$pid" 2>/dev/null || true
        sleep 1
    fi

    # If STILL alive, SIGKILL
    if is_process_alive "$pid"; then
        kill -9 "$pid" 2>/dev/null || true
    fi

    rm -f "$pid_file" 2>/dev/null
    echo "[indexer] Stopped"
}

indexer_status() {
    local pid_file
    pid_file=$(get_indexer_pid_file)

    if ! pid=$(read_pid "$pid_file" 2>/dev/null); then
        echo "[indexer] Status: stopped"
        return 1
    fi

    local health
    health=$(http_health "$INDEXER_DEFAULT_PORT" "/status" 2>/dev/null || echo "")

    if [ -n "$health" ]; then
        local files
        files=$(echo "$health" | grep -o '"indexedFiles":[0-9]*' | cut -d: -f2 || echo "?")
        local watcher
        watcher=$(echo "$health" | grep -o '"watcherActive":true' && echo "active" || echo "inactive")
        echo "[indexer] Status: running (PID $pid, port ~$INDEXER_DEFAULT_PORT, $files files indexed, watcher $watcher)"
    else
        echo "[indexer] Status: running (PID $pid) — API not responding (may be initializing)"
    fi
}

# ─── Hub Service ──────────────────────────────────────────────

hub_start() {
    mkdir -p "$(dirname "$HUB_PID_FILE")"

    if pid=$(read_pid "$HUB_PID_FILE" 2>/dev/null); then
        echo "[hub] Already running (PID $pid)"
        return 0
    fi

    # Also check if something is already on the port
    if is_port_open "$HUB_DEFAULT_PORT"; then
        echo "[hub] Port $HUB_DEFAULT_PORT already in use — hub may be running outside our management"
        return 0
    fi

    check_bun || return 1
    check_mma || return 1

    echo "[hub] Starting..."

    cd "$MMA_DIR"
    nohup bun run src/matrix-hub.ts \
        > "$LOG_DIR/hub.log" 2>&1 &

    local bg_pid=$!

    # Write PID file ourselves since hub doesn't use per-matrix PID files
    echo "$bg_pid" > "$HUB_PID_FILE"

    sleep 2

    if is_process_alive "$bg_pid"; then
        echo "[hub] Started (PID $bg_pid, port $HUB_DEFAULT_PORT)"
    else
        rm -f "$HUB_PID_FILE"
        echo "[hub] FAILED to start. Check $LOG_DIR/hub.log"
        return 1
    fi
}

hub_stop() {
    if ! pid=$(read_pid "$HUB_PID_FILE" 2>/dev/null); then
        # Check port as fallback
        if is_port_open "$HUB_DEFAULT_PORT"; then
            echo "[hub] Found process on port $HUB_DEFAULT_PORT but no PID file — kill manually"
            return 1
        fi
        echo "[hub] Not running"
        return 0
    fi

    echo "[hub] Stopping (PID $pid)..."
    kill -TERM "$pid" 2>/dev/null || true
    sleep 1

    if is_process_alive "$pid"; then
        kill -9 "$pid" 2>/dev/null || true
    fi

    rm -f "$HUB_PID_FILE" 2>/dev/null
    echo "[hub] Stopped"
}

hub_status() {
    if ! pid=$(read_pid "$HUB_PID_FILE" 2>/dev/null); then
        if is_port_open "$HUB_DEFAULT_PORT"; then
            echo "[hub] Status: running (unmanaged — port $HUB_DEFAULT_PORT in use)"
        else
            echo "[hub] Status: stopped"
        fi
        return 1
    fi

    local health
    health=$(http_health "$HUB_DEFAULT_PORT" "/status" 2>/dev/null || echo "")

    if [ -n "$health" ]; then
        local clients
        clients=$(echo "$health" | grep -o '"connectedClients":[0-9]*' | cut -d: -f2 || echo "?")
        echo "[hub] Status: running (PID $pid, port $HUB_DEFAULT_PORT, $clients connected)"
    else
        echo "[hub] Status: running (PID $pid, port $HUB_DEFAULT_PORT)"
    fi
}

# ─── Dispatch ─────────────────────────────────────────────────

dispatch_service() {
    local action="$1"
    local service="$2"

    case "$service" in
        indexer) "indexer_${action}" ;;
        hub)     "hub_${action}" ;;
        *)
            echo "[matrix-services] Unknown service: $service"
            echo "Available services: indexer, hub"
            return 1
            ;;
    esac
}

dispatch_all() {
    local action="$1"
    local failed=0

    for svc in indexer hub; do
        dispatch_service "$action" "$svc" || failed=$((failed + 1))
    done

    if [ "$failed" -gt 0 ]; then
        return 1
    fi
}

# ─── CLI Entry Point ─────────────────────────────────────────

ACTION="${1:-help}"
SERVICE="${2:-all}"

case "$ACTION" in
    start)
        echo "=== Matrix Services — Starting ==="
        if [ "$SERVICE" = "all" ]; then
            dispatch_all "start"
        else
            dispatch_service "start" "$SERVICE"
        fi
        echo "=== Done ==="
        ;;

    stop)
        echo "=== Matrix Services — Stopping ==="
        if [ "$SERVICE" = "all" ]; then
            dispatch_all "stop"
        else
            dispatch_service "stop" "$SERVICE"
        fi
        echo "=== Done ==="
        ;;

    status)
        echo "=== Matrix Services — Status ==="
        dispatch_all "status" || true
        echo "=== Done ==="
        ;;

    restart)
        echo "=== Matrix Services — Restarting ==="
        if [ "$SERVICE" = "all" ]; then
            dispatch_all "stop"
            sleep 1
            dispatch_all "start"
        else
            dispatch_service "stop" "$SERVICE"
            sleep 1
            dispatch_service "start" "$SERVICE"
        fi
        echo "=== Done ==="
        ;;

    help|*)
        cat <<'USAGE'
Matrix Services — Unified Daemon Manager (Phase 9 / ADR-011)

Usage:
  matrix-services.sh start [service]    Start one or all services
  matrix-services.sh stop [service]     Stop one or all services
  matrix-services.sh status             Health check all services
  matrix-services.sh restart [service]  Restart one or all services

Services:
  indexer    Code indexer daemon (auto-indexes on file changes)
  hub        Matrix Hub (cross-project WebSocket messaging)
  all        All services (default)

Examples:
  matrix-services.sh start              Start all services
  matrix-services.sh start indexer      Start indexer only
  matrix-services.sh status             Check all service health
  matrix-services.sh stop hub           Stop hub only

Logs: psi/pulse/daemon-logs/
USAGE
        ;;
esac
