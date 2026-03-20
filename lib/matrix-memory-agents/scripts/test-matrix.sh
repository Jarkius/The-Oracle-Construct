#!/bin/bash
# Matrix Test Runner — Run all or targeted test suites
#
# Usage:
#   ./scripts/test-matrix.sh              # All tests
#   ./scripts/test-matrix.sh quick        # Quick (unit only, no integration)
#   ./scripts/test-matrix.sh nerve        # Nerve module tests
#   ./scripts/test-matrix.sh health       # Health patrol
#   ./scripts/test-matrix.sh integration  # Integration tests only
#   ./scripts/test-matrix.sh <file>       # Specific test file

set -o pipefail
cd "$(dirname "$0")/.."

MODE="${1:-all}"
FAILED=0

run_test() {
  local label="$1"
  local pattern="$2"
  echo "=== $label ==="
  if bun test "$pattern" 2>&1; then
    echo "  ✅ $label passed"
  else
    echo "  ❌ $label FAILED"
    FAILED=$((FAILED + 1))
  fi
  echo ""
}

case "$MODE" in
  quick)
    run_test "Nerve Unit" "src/nerve/"
    run_test "DB Functions" "scripts/tests/db-functions.test.ts"
    run_test "Task Routing" "scripts/tests/task-routing.test.ts"
    run_test "Security" "scripts/tests/security.test.ts"
    ;;
  nerve)
    run_test "Nerve Unit" "src/nerve/"
    ;;
  health)
    echo "=== Health Patrol ==="
    bun scripts/matrix-health-patrol.ts --quick
    ;;
  integration)
    run_test "Matrix Integration" "src/tests/matrix-integration.test.ts"
    run_test "E2E Flow" "src/tests/e2e-flow.test.ts"
    run_test "PTY Integration" "src/intelligence/pty/tests/integration.test.ts"
    ;;
  all)
    run_test "Nerve" "src/nerve/"
    run_test "Matrix Integration" "src/tests/matrix-integration.test.ts"
    run_test "DB Functions" "scripts/tests/db-functions.test.ts"
    run_test "Task Routing" "scripts/tests/task-routing.test.ts"
    run_test "Oracle Spawning" "scripts/tests/oracle-spawning.test.ts"
    run_test "Security" "scripts/tests/security.test.ts"
    run_test "Agent Query" "scripts/tests/agent-query.test.ts"
    echo "=== Health Patrol ==="
    bun scripts/matrix-health-patrol.ts --quick
    ;;
  *)
    # Treat as file path
    run_test "$MODE" "$MODE"
    ;;
esac

echo "================================"
if [ $FAILED -eq 0 ]; then
  echo "All tests passed"
else
  echo "$FAILED test suite(s) FAILED"
  exit 1
fi
