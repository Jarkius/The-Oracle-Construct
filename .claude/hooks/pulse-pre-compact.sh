#!/usr/bin/env bash
set -euo pipefail
#
# File: .claude/hooks/pulse-pre-compact.sh
#
# Phase 5.1: Pre-Compaction Preservation Hook
# Saves critical context before Claude Code compacts the conversation.
# Ensures decisions and in-progress work survive context reduction.
#

export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

EVENT_WRITER="$PROJECT_ROOT/.claude/hooks/pulse-event-writer.sh"
MEMORY_SAVE="$PROJECT_ROOT/.claude/hooks/session-memory-save.sh"

# Log compaction event
bash "$EVENT_WRITER" "context:compacted" "System" '{"reason":"pre_compact_hook"}'

# Save session memory before compaction wipes context
if [ -f "$MEMORY_SAVE" ]; then
    bash "$MEMORY_SAVE" "pre-compact" 2>/dev/null || true
fi

# Output preservation reminder to the agent
cat <<'EOF'

# Pre-Compaction Preservation (Phase 5)

Context is being compacted. Critical state has been auto-saved to session memory.
After compaction, check `psi/memory/sessions/` for the pre-compact snapshot if you lose context.

EOF

exit 0
