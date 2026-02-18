#!/usr/bin/env bash
set -euo pipefail
#
# File: .claude/hooks/pulse-auto-evolve.sh
#
# Phase 12 (ADR-014) + Phase 13 Tier 1 (ADR-015): Sandbox Self-Evolution
#
# Scans proposals/ for WEPs and applies them:
# - Low-risk (.json/.md only): Direct apply (ADR-014 behavior)
# - Medium-risk or sandbox mode: Branch → test gates → merge/rollback
#
# Usage:
#   pulse-auto-evolve.sh                    # Auto-apply (sandbox for medium+)
#   pulse-auto-evolve.sh --dry-run          # Preview changes
#   pulse-auto-evolve.sh --sandbox          # Force sandbox for all WEPs
#   pulse-auto-evolve.sh --max-risk medium  # Allow medium-risk auto-apply
#   pulse-auto-evolve.sh --status           # Show evolution history
#
# Guard rails:
# - Sacred files NEVER auto-evolved (SOUL.md, CLAUDE.md, etc.)
# - Sandbox branch per WEP, auto-cleaned on pass/fail
# - Kill switch: heartbeat.json → "auto_evolve": false
# - Full audit in evolution-log.jsonl + events.jsonl
#

export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

PROPOSALS_DIR="$PROJECT_ROOT/psi/memory/evolution/proposals"
APPLIED_DIR="$PROJECT_ROOT/psi/memory/evolution/applied"
REJECTED_DIR="$PROJECT_ROOT/psi/memory/evolution/rejected"
HEARTBEAT_CONFIG="$PROJECT_ROOT/psi/pulse/heartbeat.json"
EVENT_WRITER="$SCRIPT_DIR/pulse-event-writer.sh"
EVOLUTION_LOG="$PROJECT_ROOT/psi/memory/evolution/evolution-log.jsonl"
MMA_DIR="$PROJECT_ROOT/lib/matrix-memory-agents"

# ─── Sacred Files (NEVER auto-evolved) ────────────────────────
SACRED_FILES=(
    "SOUL.md"
    "CLAUDE.md"
    "USER.md"
    "BOOT.md"
    "VOICE_CALIBRATION.md"
    "psi/The_Source/"
    ".claude/agents/"
)

# ─── Parse Arguments ──────────────────────────────────────────

DRY_RUN=false
FORCE_SANDBOX=false
MAX_RISK="low"
SHOW_STATUS=false

while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run)    DRY_RUN=true; shift ;;
        --sandbox)    FORCE_SANDBOX=true; shift ;;
        --max-risk)   MAX_RISK="${2:-low}"; shift 2 ;;
        --status)     SHOW_STATUS=true; shift ;;
        *)            echo "[auto-evolve] Unknown flag: $1"; exit 1 ;;
    esac
done

# ─── Utility Functions ────────────────────────────────────────

ts_now() {
    date -u '+%Y-%m-%dT%H:%M:%SZ'
}

log_evolution() {
    local wep="$1" tier="$2" action="$3" extra="${4:-}"
    mkdir -p "$(dirname "$EVOLUTION_LOG")"
    local entry="{\"ts\":\"$(ts_now)\",\"wep\":\"$wep\",\"tier\":$tier,\"action\":\"$action\""
    if [ -n "$extra" ]; then
        entry="$entry,$extra"
    fi
    entry="$entry}"
    echo "$entry" >> "$EVOLUTION_LOG"
}

log_event() {
    local type="$1" data="${2:-{}}"
    if [ -x "$EVENT_WRITER" ]; then
        bash "$EVENT_WRITER" "$type" "Heartbeat" "$data" 2>/dev/null || true
    fi
}

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

# ─── Sacred File Check ───────────────────────────────────────

is_sacred() {
    local filepath="$1"
    for sacred in "${SACRED_FILES[@]}"; do
        if [[ "$filepath" == *"$sacred"* ]]; then
            return 0
        fi
    done
    return 1
}

check_wep_sacred_files() {
    local wep_file="$1"
    local in_affected=false
    while IFS= read -r line; do
        if [[ "$line" =~ ^affected_files: ]]; then
            in_affected=true
            continue
        fi
        if [ "$in_affected" = true ]; then
            if [[ "$line" =~ ^[[:space:]]+-[[:space:]]+(.*) ]]; then
                local fpath="${BASH_REMATCH[1]}"
                if is_sacred "$fpath"; then
                    echo "[auto-evolve] BLOCKED: $fpath is a sacred file"
                    return 1
                fi
            elif [[ ! "$line" =~ ^[[:space:]] ]]; then
                break
            fi
        fi
    done < "$wep_file"
    return 0
}

# ─── WEP Metadata Extraction ─────────────────────────────────

get_field() {
    local wep_file="$1" field="$2"
    grep -i "^\*\*$field\*\*:" "$wep_file" 2>/dev/null | head -1 | sed 's/.*:\s*//' | tr '[:upper:]' '[:lower:]' | xargs
}

get_risk_level() {
    local risk
    risk=$(get_field "$1" "Risk")
    echo "${risk:-unknown}"
}

get_wep_number() {
    basename "$1" | grep -o 'WEP-[0-9]*' | head -1
}

# ─── Status Display ──────────────────────────────────────────

show_status() {
    echo "╔══════════════════════════════════════╗"
    echo "║     Evolution Status (Phase 13)      ║"
    echo "╚══════════════════════════════════════╝"
    echo ""

    local applied_count=0
    if [ -d "$APPLIED_DIR" ]; then
        applied_count=$(find "$APPLIED_DIR" -name 'WEP-*.md' 2>/dev/null | wc -l | xargs)
    fi

    local rejected_count=0
    if [ -d "$REJECTED_DIR" ]; then
        rejected_count=$(find "$REJECTED_DIR" -name 'WEP-*.md' 2>/dev/null | wc -l | xargs)
    fi

    local pending_count=0
    if [ -d "$PROPOSALS_DIR" ]; then
        pending_count=$(find "$PROPOSALS_DIR" -name 'WEP-*.md' 2>/dev/null | wc -l | xargs)
    fi

    echo "  Applied:  $applied_count"
    echo "  Rejected: $rejected_count"
    echo "  Pending:  $pending_count"
    echo ""

    if [ -f "$EVOLUTION_LOG" ]; then
        local total_entries
        total_entries=$(wc -l < "$EVOLUTION_LOG" | xargs)
        local test_passes
        test_passes=$(grep -c '"result":"pass"' "$EVOLUTION_LOG" 2>/dev/null || true)
        test_passes=${test_passes:-0}
        local test_fails
        test_fails=$(grep -c '"result":"fail"' "$EVOLUTION_LOG" 2>/dev/null || true)
        test_fails=${test_fails:-0}
        echo "  Log entries: $total_entries"
        echo "  Test passes: $test_passes"
        echo "  Test fails:  $test_fails"
        echo ""
        echo "  Last 5 events:"
        tail -5 "$EVOLUTION_LOG" 2>/dev/null | while IFS= read -r line; do
            echo "    $line"
        done
    else
        echo "  No evolution log yet."
    fi

    exit 0
}

if [ "$SHOW_STATUS" = true ]; then
    show_status
fi

# ─── Test Gates (Tier 1) ─────────────────────────────────────

run_test_gate() {
    local gate_name="$1" command="$2" wep_num="$3"
    echo "[auto-evolve]   Gate: $gate_name..."

    if [ "$DRY_RUN" = true ]; then
        echo "[auto-evolve]   DRY-RUN: Would run: $command"
        log_evolution "$wep_num" 1 "test" "\"gate\":\"$gate_name\",\"result\":\"skip\",\"reason\":\"dry-run\""
        return 0
    fi

    local result
    if eval "$command" >/dev/null 2>&1; then
        result="pass"
        echo "[auto-evolve]   ✓ $gate_name passed"
    else
        result="fail"
        echo "[auto-evolve]   ✗ $gate_name FAILED"
    fi

    log_evolution "$wep_num" 1 "test" "\"gate\":\"$gate_name\",\"result\":\"$result\""

    if [ "$result" = "fail" ]; then
        return 1
    fi
    return 0
}

validate_syntax() {
    local failed=false
    while IFS= read -r jsonfile; do
        if ! python3 -c "import json; json.load(open('$jsonfile'))" 2>/dev/null; then
            echo "[auto-evolve]     Invalid JSON: $jsonfile"
            failed=true
        fi
    done < <(find "$PROJECT_ROOT" -name '*.json' -not -path '*/node_modules/*' -not -path '*/.git/*' -maxdepth 4 2>/dev/null)
    if [ "$failed" = true ]; then return 1; fi
    return 0
}

run_all_test_gates() {
    local wep_file="$1" wep_num="$2"
    local failed=false

    # Gate 1: Syntax — validate JSON structure
    run_test_gate "syntax" "validate_syntax" "$wep_num" || failed=true
    if [ "$failed" = true ]; then return 1; fi

    # Gate 2: Hook health — pattern scanner
    if [ -x "$SCRIPT_DIR/pulse-pattern-scanner.sh" ]; then
        run_test_gate "hooks" "bash '$SCRIPT_DIR/pulse-pattern-scanner.sh' >/dev/null 2>&1" "$wep_num" || failed=true
    else
        echo "[auto-evolve]   Gate: hooks (skip — scanner not found)"
        log_evolution "$wep_num" 1 "test" "\"gate\":\"hooks\",\"result\":\"skip\""
    fi
    if [ "$failed" = true ]; then return 1; fi

    # Gate 3: Memory health
    if [ -d "$MMA_DIR" ] && command -v bun >/dev/null 2>&1; then
        run_test_gate "memory" "cd '$MMA_DIR' && bun memory status >/dev/null 2>&1" "$wep_num" || failed=true
    else
        echo "[auto-evolve]   Gate: memory (skip — bun/MMA not available)"
        log_evolution "$wep_num" 1 "test" "\"gate\":\"memory\",\"result\":\"skip\""
    fi
    if [ "$failed" = true ]; then return 1; fi

    # Gate 4: Service health
    if [ -x "$SCRIPT_DIR/matrix-services.sh" ]; then
        run_test_gate "services" "bash '$SCRIPT_DIR/matrix-services.sh' status >/dev/null 2>&1" "$wep_num" || failed=true
    else
        echo "[auto-evolve]   Gate: services (skip — services script not found)"
        log_evolution "$wep_num" 1 "test" "\"gate\":\"services\",\"result\":\"skip\""
    fi
    if [ "$failed" = true ]; then return 1; fi

    # Gate 5: Custom test command from WEP frontmatter
    local custom_test
    custom_test=$(grep -i '^\*\*test_command\*\*:' "$wep_file" 2>/dev/null | head -1 | sed 's/.*:\s*//' | xargs)
    if [ -n "$custom_test" ] && [ "$custom_test" != "none" ]; then
        run_test_gate "custom" "$custom_test" "$wep_num" || failed=true
    else
        log_evolution "$wep_num" 1 "test" "\"gate\":\"custom\",\"result\":\"skip\""
    fi
    if [ "$failed" = true ]; then return 1; fi

    return 0
}

# ─── Risk Can Proceed Check ──────────────────────────────────

risk_can_proceed() {
    local risk="$1"
    case "$MAX_RISK" in
        low)    [ "$risk" = "low" ] ;;
        medium) [ "$risk" = "low" ] || [ "$risk" = "medium" ] ;;
        high)   true ;;
        *)      [ "$risk" = "low" ] ;;
    esac
}

# ─── Direct Apply (ADR-014 path — low-risk, no sandbox) ──────

apply_direct() {
    local wep_file="$1" wep_num="$2" wep_name="$3"

    echo "[auto-evolve] Direct apply: $wep_num"

    if [ "$DRY_RUN" = true ]; then
        echo "[auto-evolve] DRY-RUN: Would move $wep_name to applied/"
        log_evolution "$wep_num" 1 "direct-apply" "\"dry_run\":true"
        return 0
    fi

    mkdir -p "$APPLIED_DIR"

    sed -i 's/\*\*Status\*\*: proposed/**Status**: applied/' "$wep_file"

    local applied_date
    applied_date=$(date -u '+%Y-%m-%d')
    {
        echo ""
        echo "## Applied"
        echo ""
        echo "**Applied-by**: pulse-auto-evolve.sh (Phase 12 — direct)"
        echo "**Applied-date**: $applied_date"
    } >> "$wep_file"

    mv "$wep_file" "$APPLIED_DIR/"

    cd "$PROJECT_ROOT"
    git add "$APPLIED_DIR/$wep_name.md" 2>/dev/null || true
    git add "$PROPOSALS_DIR/" 2>/dev/null || true
    git commit -m "chore(evolution): auto-apply $wep_num [direct]" --no-verify 2>/dev/null || true

    log_evolution "$wep_num" 1 "applied" "\"method\":\"direct\""
    log_event "evolution:auto-applied" "{\"wep\":\"$wep_num\",\"method\":\"direct\"}"

    echo "[auto-evolve] ✓ Applied $wep_num (direct)"
}

# ─── Sandbox Apply (ADR-015 path — branch + test + merge) ────

apply_sandbox() {
    local wep_file="$1" wep_num="$2" wep_name="$3"
    local sandbox_branch="evolution/$wep_num"
    local original_branch

    original_branch=$(git -C "$PROJECT_ROOT" rev-parse --abbrev-ref HEAD)

    echo "[auto-evolve] Sandbox apply: $wep_num (branch: $sandbox_branch)"

    if [ "$DRY_RUN" = true ]; then
        echo "[auto-evolve] DRY-RUN: Would create branch $sandbox_branch"
        echo "[auto-evolve] DRY-RUN: Would run 5 test gates"
        echo "[auto-evolve] DRY-RUN: Would merge on pass / delete on fail"
        log_evolution "$wep_num" 1 "sandbox" "\"dry_run\":true,\"branch\":\"$sandbox_branch\""
        return 0
    fi

    cd "$PROJECT_ROOT"

    # Create sandbox branch
    git checkout -b "$sandbox_branch" 2>/dev/null || {
        echo "[auto-evolve] ✗ Failed to create branch $sandbox_branch"
        log_evolution "$wep_num" 1 "sandbox" "\"result\":\"fail\",\"reason\":\"branch creation failed\""
        return 1
    }

    log_evolution "$wep_num" 1 "sandbox" "\"branch\":\"$sandbox_branch\""

    # Update status to sandbox
    sed -i 's/\*\*Status\*\*: proposed/**Status**: sandbox/' "$wep_file"
    git add "$wep_file" 2>/dev/null || true
    git commit -m "chore(evolution): sandbox $wep_num" --no-verify 2>/dev/null || true

    # Run test gates
    echo "[auto-evolve] Running test gates..."
    local gates_passed=true
    if ! run_all_test_gates "$wep_file" "$wep_num"; then
        gates_passed=false
    fi

    if [ "$gates_passed" = true ]; then
        # ── PASS: merge back ──
        echo "[auto-evolve] All gates passed. Merging → $original_branch"

        sed -i 's/\*\*Status\*\*: sandbox/**Status**: applied/' "$wep_file"
        local applied_date
        applied_date=$(date -u '+%Y-%m-%d')
        {
            echo ""
            echo "## Applied"
            echo ""
            echo "**Applied-by**: pulse-auto-evolve.sh (Phase 13 — sandbox)"
            echo "**Applied-date**: $applied_date"
            echo "**Test-results**: all gates passed"
        } >> "$wep_file"

        mkdir -p "$APPLIED_DIR"
        mv "$wep_file" "$APPLIED_DIR/"
        git add -A 2>/dev/null || true
        git commit -m "chore(evolution): sandbox-apply $wep_num [all gates pass]" --no-verify 2>/dev/null || true

        git checkout "$original_branch" 2>/dev/null
        git merge "$sandbox_branch" --no-edit 2>/dev/null || {
            echo "[auto-evolve] ✗ Merge conflict — rejecting $wep_num"
            git merge --abort 2>/dev/null || true
            git branch -D "$sandbox_branch" 2>/dev/null || true
            log_evolution "$wep_num" 1 "rejected" "\"reason\":\"merge conflict\""
            log_event "evolution:rejected" "{\"wep\":\"$wep_num\",\"reason\":\"merge conflict\"}"
            return 1
        }

        git branch -d "$sandbox_branch" 2>/dev/null || true

        log_evolution "$wep_num" 1 "applied" "\"method\":\"sandbox\",\"branch\":\"$sandbox_branch\""
        log_event "evolution:applied" "{\"wep\":\"$wep_num\",\"method\":\"sandbox\"}"

        echo "[auto-evolve] ✓ Applied $wep_num (sandbox — all gates passed)"
    else
        # ── FAIL: rollback ──
        echo "[auto-evolve] ✗ Test gates failed. Rolling back $sandbox_branch"

        mkdir -p "$REJECTED_DIR"
        sed -i 's/\*\*Status\*\*: sandbox/**Status**: rejected/' "$wep_file"
        {
            echo ""
            echo "## Rejected"
            echo ""
            echo "**Rejected-by**: pulse-auto-evolve.sh (Phase 13 — sandbox)"
            echo "**Rejected-date**: $(date -u '+%Y-%m-%d')"
            echo "**Reason**: Test gate(s) failed"
        } >> "$wep_file"

        git add -A 2>/dev/null || true
        git commit -m "chore(evolution): reject $wep_num [gate failure]" --no-verify 2>/dev/null || true

        # Return to original branch
        git checkout "$original_branch" 2>/dev/null

        # Move WEP to rejected on original branch
        if [ -f "$PROPOSALS_DIR/$wep_name.md" ]; then
            mv "$PROPOSALS_DIR/$wep_name.md" "$REJECTED_DIR/" 2>/dev/null || true
            git add "$REJECTED_DIR/" "$PROPOSALS_DIR/" 2>/dev/null || true
            git commit -m "chore(evolution): reject $wep_num [gate failure]" --no-verify 2>/dev/null || true
        fi

        git branch -D "$sandbox_branch" 2>/dev/null || true

        log_evolution "$wep_num" 1 "rejected" "\"reason\":\"test gates failed\""
        log_event "evolution:rejected" "{\"wep\":\"$wep_num\",\"reason\":\"test gates failed\"}"

        echo "[auto-evolve] ✗ Rejected $wep_num (gate failure — branch deleted)"
        return 1
    fi
}

# ─── Main ─────────────────────────────────────────────────────

main() {
    check_kill_switch

    if [ ! -d "$PROPOSALS_DIR" ]; then
        echo "[auto-evolve] No proposals directory — nothing to do"
        exit 0
    fi

    local applied=0
    local rejected=0
    local skipped=0
    local blocked=0
    local total=0

    for wep_file in "$PROPOSALS_DIR"/WEP-*.md; do
        [ -f "$wep_file" ] || continue
        total=$((total + 1))

        local risk
        risk=$(get_risk_level "$wep_file")
        local wep_num
        wep_num=$(get_wep_number "$wep_file")
        local wep_name
        wep_name=$(basename "$wep_file" .md)

        echo ""
        echo "[auto-evolve] Processing $wep_num (risk: $risk)"

        # Sacred file check
        if ! check_wep_sacred_files "$wep_file"; then
            echo "[auto-evolve] BLOCKED: $wep_num touches sacred files — skipping"
            blocked=$((blocked + 1))
            log_evolution "$wep_num" 1 "blocked" "\"reason\":\"sacred files\""
            continue
        fi

        # Risk gate
        if ! risk_can_proceed "$risk"; then
            echo "[auto-evolve] Skipping $wep_num (risk: $risk — max allowed: $MAX_RISK)"
            skipped=$((skipped + 1))
            continue
        fi

        # Choose apply method
        if [ "$FORCE_SANDBOX" = true ] || [ "$risk" != "low" ]; then
            if apply_sandbox "$wep_file" "$wep_num" "$wep_name"; then
                applied=$((applied + 1))
            else
                rejected=$((rejected + 1))
            fi
        else
            apply_direct "$wep_file" "$wep_num" "$wep_name"
            applied=$((applied + 1))
        fi
    done

    echo ""
    echo "[auto-evolve] Done: $applied applied, $rejected rejected, $skipped skipped, $blocked blocked, $total total"

    # Log summary
    if [ "$total" -gt 0 ] && [ "$DRY_RUN" = false ]; then
        log_evolution "summary" 1 "cycle" "\"applied\":$applied,\"rejected\":$rejected,\"skipped\":$skipped,\"blocked\":$blocked,\"total\":$total"
        log_event "evolution:cycle" "{\"applied\":$applied,\"rejected\":$rejected,\"skipped\":$skipped,\"total\":$total}"
    fi
}

main
