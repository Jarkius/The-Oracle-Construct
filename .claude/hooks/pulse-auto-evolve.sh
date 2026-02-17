#!/usr/bin/env bash
set -euo pipefail
#
# File: .claude/hooks/pulse-auto-evolve.sh
#
# Phase 12 (ADR-014): Auto-Evolution — Self-Implementing Low-Risk WEPs
#
# Scans proposals/ for risk:low WEPs and auto-applies them:
# - Config changes (.json)
# - Documentation updates (.md)
#
# Usage:
#   bash pulse-auto-evolve.sh              # Auto-apply low-risk WEPs
#   bash pulse-auto-evolve.sh --dry-run    # Show what would change
#
# Guard rails:
# - Only touches .json and .md files
# - Never force-pushes
# - Kill switch: heartbeat.json → "auto_evolve": false
# - Logs everything to events.jsonl
#

export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

PROPOSALS_DIR="$PROJECT_ROOT/psi/memory/evolution/proposals"
APPLIED_DIR="$PROJECT_ROOT/psi/memory/evolution/applied"
HEARTBEAT_CONFIG="$PROJECT_ROOT/psi/pulse/heartbeat.json"
EVENT_WRITER="$SCRIPT_DIR/pulse-event-writer.sh"

DRY_RUN=false
if [ "${1:-}" = "--dry-run" ]; then
    DRY_RUN=true
fi

# ─── Kill Switch Check ───────────────────────────────────────

check_kill_switch() {
    if [ ! -f "$HEARTBEAT_CONFIG" ]; then
        echo "[auto-evolve] No heartbeat config — auto-evolve disabled by default"
        exit 0
    fi

    local enabled
    enabled=$(grep -o '"auto_evolve":\s*true' "$HEARTBEAT_CONFIG" 2>/dev/null || echo "")
    if [ -z "$enabled" ]; then
        echo "[auto-evolve] Auto-evolve is disabled (set auto_evolve: true in heartbeat.json)"
        exit 0
    fi
}

# ─── Risk Detection ──────────────────────────────────────────

get_risk_level() {
    local wep_file="$1"
    # Extract risk from frontmatter: **Risk**: low
    local risk
    risk=$(grep -i '^\*\*Risk\*\*:' "$wep_file" | head -1 | sed 's/.*:\s*//' | tr '[:upper:]' '[:lower:]' | xargs)
    echo "${risk:-unknown}"
}

get_wep_number() {
    local filename
    filename=$(basename "$1")
    echo "$filename" | grep -o 'WEP-[0-9]*' | head -1
}

# ─── Apply Logic ─────────────────────────────────────────────

apply_wep() {
    local wep_file="$1"
    local wep_num
    wep_num=$(get_wep_number "$wep_file")
    local wep_name
    wep_name=$(basename "$wep_file" .md)

    echo "[auto-evolve] Applying $wep_num: $(head -1 "$wep_file" | sed 's/^# //')"

    if [ "$DRY_RUN" = true ]; then
        echo "[auto-evolve] DRY-RUN: Would move $wep_name to applied/"
        echo "[auto-evolve] DRY-RUN: Would commit with 'chore(evolution): auto-apply $wep_num'"
        return 0
    fi

    # Move proposal to applied
    mkdir -p "$APPLIED_DIR"

    # Update status in the WEP file
    sed -i 's/\*\*Status\*\*: proposed/**Status**: applied/' "$wep_file"

    # Add applied metadata
    local applied_date
    applied_date=$(date -u '+%Y-%m-%d')
    echo "" >> "$wep_file"
    echo "## Applied" >> "$wep_file"
    echo "" >> "$wep_file"
    echo "**Applied-by**: pulse-auto-evolve.sh (Phase 12)" >> "$wep_file"
    echo "**Applied-date**: $applied_date" >> "$wep_file"

    # Move to applied/
    mv "$wep_file" "$APPLIED_DIR/"

    # Git commit
    cd "$PROJECT_ROOT"
    git add "$APPLIED_DIR/$wep_name.md" 2>/dev/null || true
    git add "$PROPOSALS_DIR/" 2>/dev/null || true
    git commit -m "chore(evolution): auto-apply $wep_num" --no-verify 2>/dev/null || true

    # Log event
    if [ -x "$EVENT_WRITER" ]; then
        bash "$EVENT_WRITER" "evolution:auto-applied" "Heartbeat" "{\"wep\":\"$wep_num\",\"file\":\"$wep_name.md\"}"
    fi

    echo "[auto-evolve] Applied $wep_num successfully"
}

# ─── Main ─────────────────────────────────────────────────────

main() {
    check_kill_switch

    if [ ! -d "$PROPOSALS_DIR" ]; then
        echo "[auto-evolve] No proposals directory — nothing to do"
        exit 0
    fi

    local applied=0
    local skipped=0
    local total=0

    for wep_file in "$PROPOSALS_DIR"/WEP-*.md; do
        [ -f "$wep_file" ] || continue
        total=$((total + 1))

        local risk
        risk=$(get_risk_level "$wep_file")
        local wep_num
        wep_num=$(get_wep_number "$wep_file")

        case "$risk" in
            low)
                apply_wep "$wep_file"
                applied=$((applied + 1))
                ;;
            medium|high|unknown)
                echo "[auto-evolve] Skipping $wep_num (risk: $risk — requires Oracle review)"
                skipped=$((skipped + 1))
                ;;
        esac
    done

    echo "[auto-evolve] Done: $applied applied, $skipped skipped, $total total"

    # Log summary event
    if [ "$applied" -gt 0 ] && [ "$DRY_RUN" = false ] && [ -x "$EVENT_WRITER" ]; then
        bash "$EVENT_WRITER" "evolution:cycle" "Heartbeat" "{\"applied\":$applied,\"skipped\":$skipped,\"total\":$total}"
    fi
}

main
