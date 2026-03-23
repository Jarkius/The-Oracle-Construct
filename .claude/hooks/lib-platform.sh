#!/bin/bash
# lib-platform.sh — Cross-platform shell utilities for Matrix hooks
# Source this file: source "$(dirname "$0")/lib-platform.sh"

get_platform() {
  case "$(uname -s)" in
    Darwin) echo "macos" ;;
    MINGW*|MSYS*|CYGWIN*) echo "windows" ;;
    Linux)
      grep -qi microsoft /proc/version 2>/dev/null && echo "wsl" || echo "linux" ;;
    *) echo "unknown" ;;
  esac
}

MATRIX_PLATFORM="$(get_platform)"
MATRIX_TMPDIR="${TMPDIR:-${TEMP:-/tmp}}"

is_process_alive() {
  local pid=$1
  if [[ "$MATRIX_PLATFORM" == "windows" ]]; then
    tasklist.exe /FI "PID eq $pid" 2>/dev/null | grep -q "$pid"
  else
    kill -0 "$pid" 2>/dev/null
  fi
}

is_port_open() {
  local port=$1
  if command -v curl &>/dev/null; then
    curl -sf "http://127.0.0.1:$port" -o /dev/null --connect-timeout 2 2>/dev/null
    return $?
  elif [[ "$MATRIX_PLATFORM" == "windows" ]]; then
    powershell.exe -Command "(Test-NetConnection -ComputerName localhost -Port $port -WarningAction SilentlyContinue).TcpTestSucceeded" 2>/dev/null | grep -qi true
    return $?
  else
    bash -c "echo >/dev/tcp/127.0.0.1/$port" 2>/dev/null
    return $?
  fi
}

get_python_cmd() {
  command -v python3 2>/dev/null || command -v python 2>/dev/null || echo "python3"
}
