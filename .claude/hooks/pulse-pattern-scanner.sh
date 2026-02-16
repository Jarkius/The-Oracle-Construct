#!/bin/bash
# Sprint 4.1: PULSE Pattern Scanner (shell wrapper)
#
# Scans psi/pulse/events.jsonl for recurring patterns and writes
# detected patterns to psi/pulse/patterns.json
#
# Usage:
#   bash .claude/hooks/pulse-pattern-scanner.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
export REPO_ROOT

python3 "$REPO_ROOT/.claude/hooks/pulse-pattern-scanner.py"
