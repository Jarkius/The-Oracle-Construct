#!/usr/bin/env bash
set -euo pipefail
#
# File: .claude/hooks/pulse-proactive-boot.sh
#
# Phase A: Proactive Boot Dispatcher (ADR-016)
#
# Called during session boot (after morning brief).
# Runs the event dispatcher, then outputs structured dispatch
# instructions that the agent can consume and act on.
#
# This is the KEY innovation: instead of displaying recommendations
# as text, this script converts them into spawn-ready agent instructions.
#
# Usage:
#   bash pulse-proactive-boot.sh              # Full proactive cycle
#   bash pulse-proactive-boot.sh --preview    # Preview only (no dispatch log)
#
# Output: Structured dispatch instructions for the session agent
#

export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
export PROJECT_ROOT

DISPATCHER="$PROJECT_ROOT/.claude/hooks/pulse/pulse-event-dispatcher.sh"
CONTEXT_LOADER="$PROJECT_ROOT/.claude/hooks/pulse/pulse-context-loader.sh"
DISPATCH_LOG="$PROJECT_ROOT/psi/state/pulse/dispatch-log.jsonl"
EVENT_WRITER="$PROJECT_ROOT/.claude/hooks/pulse/pulse-event-writer.sh"

PREVIEW_ONLY=false
[ "${1:-}" = "--preview" ] && PREVIEW_ONLY=true

# ─── Preflight ────────────────────────────────────────────────
if [ ! -f "$DISPATCHER" ]; then
    echo "[proactive] Event dispatcher not found — skipping"
    exit 0
fi

if [ ! -x "$DISPATCHER" ]; then
    chmod +x "$DISPATCHER" 2>/dev/null || true
fi

# ─── Run Dispatcher ───────────────────────────────────────────
if [ "$PREVIEW_ONLY" = true ]; then
    DISPATCH_OUTPUT=$(bash "$DISPATCHER" --dry-run 2>/dev/null || echo "")
else
    DISPATCH_OUTPUT=$(bash "$DISPATCHER" 2>/dev/null || echo "")
fi

# Check if there are any DISPATCH lines (auto-dispatch actions)
AUTO_DISPATCHES=$(echo "$DISPATCH_OUTPUT" | grep "^DISPATCH|" || echo "")

if [ -z "$AUTO_DISPATCHES" ]; then
    # Check for pending approvals
    PENDING=$(grep -c '"status":"pending_approval"' "$DISPATCH_LOG" 2>/dev/null || true)
    PENDING="${PENDING:-0}"
    PENDING=$(echo "$PENDING" | tr -d '[:space:]')
    if [ "$PENDING" -gt 0 ]; then
        echo ""
        echo "### Proactive Dispatch Queue"
        echo ""
        echo "$PENDING dispatch(es) awaiting your approval:"
        echo ""
        tail -10 "$DISPATCH_LOG" 2>/dev/null | grep '"pending_approval"' | while IFS= read -r line; do
            RULE=$(echo "$line" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('rule_id','?'))" 2>/dev/null || echo "?")
            AGENT=$(echo "$line" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('agent','?'))" 2>/dev/null || echo "?")
            TASK=$(echo "$line" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('task','?')[:100])" 2>/dev/null || echo "?")
            echo "- **$RULE** → Spawn **$AGENT**: $TASK"
        done
        echo ""
        echo "*Say 'approve dispatches' to execute, or 'skip dispatches' to defer.*"
    fi
    exit 0
fi

# ─── Process Auto-Dispatches ─────────────────────────────────
echo ""
echo "### Proactive Dispatch — Auto-Actions"
echo ""

DISPATCH_COUNT=0
while IFS='|' read -r _ AGENT TASK RULE_ID; do
    DISPATCH_COUNT=$((DISPATCH_COUNT + 1))

    echo "**Dispatch #$DISPATCH_COUNT**: Spawning **$AGENT** via rule \`$RULE_ID\`"
    echo ""
    echo "> $TASK"
    echo ""

    # Load context for this agent
    if [ -f "$CONTEXT_LOADER" ] && [ -x "$CONTEXT_LOADER" ]; then
        echo "<details><summary>Agent Context (click to expand)</summary>"
        echo ""
        bash "$CONTEXT_LOADER" "$AGENT" "$TASK" 2>/dev/null || echo "*Context loading failed — agent will operate without preloaded context*"
        echo ""
        echo "</details>"
        echo ""
    fi

    # Output spawn instruction marker
    echo "<!-- SPAWN_AGENT: $AGENT | TASK: $TASK | RULE: $RULE_ID -->"
    echo ""

done <<< "$AUTO_DISPATCHES"

echo "---"
echo "**$DISPATCH_COUNT agent(s) queued for dispatch.** The Oracle Construct will spawn them as Task agents."
echo ""

# Log proactive boot event
bash "$EVENT_WRITER" "dispatch:proactive_boot" "Dispatcher" "{\"auto_dispatches\":$DISPATCH_COUNT}" 2>/dev/null || true
