#!/bin/bash
# Matrix Artifact - Agent drops deliverable
# Usage: matrix-artifact.sh <AgentID> <filename> <content>
#        OR: echo "content" | matrix-artifact.sh <AgentID> <filename>
#
# Creates artifact file for Operator to collect

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

AGENT_ID="${1:-unknown}"
FILENAME="${2:-artifact.md}"

ARTIFACTS_DIR="$PROJECT_ROOT/psi/inbox/artifacts"

# Full path for artifact
ARTIFACT_PATH="$ARTIFACTS_DIR/${AGENT_ID}-${FILENAME}"

# Content from argument or stdin
if [[ -n "${3:-}" ]]; then
    echo "$3" > "$ARTIFACT_PATH"
else
    # Read from stdin
    cat > "$ARTIFACT_PATH"
fi

echo "📦 Artifact dropped: $ARTIFACT_PATH"
