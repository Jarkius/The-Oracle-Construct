#!/usr/bin/env bash
set -euo pipefail
#
# File: .claude/hooks/pulse-dispatch-learner.sh
#
# Phase D: Dispatch Learning Feedback (ADR-016 extension)
#
# Tracks dispatch outcomes and adjusts rule confidence over time.
# The system learns which dispatches succeed and which don't.
#
# Usage:
#   bash pulse-dispatch-learner.sh outcome <rule_id> <success|failure|timeout> [notes]
#   bash pulse-dispatch-learner.sh analyze                         # Show rule effectiveness
#   bash pulse-dispatch-learner.sh tune                            # Auto-adjust rule confidence
#   bash pulse-dispatch-learner.sh report                          # Full learning report
#

export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

DISPATCH_LOG="$PROJECT_ROOT/psi/pulse/dispatch-log.jsonl"
OUTCOME_LOG="$PROJECT_ROOT/psi/pulse/dispatch-outcomes.jsonl"
RULES_FILE="$PROJECT_ROOT/psi/pulse/dispatch-rules.json"
LEARNINGS_FILE="$PROJECT_ROOT/psi/pulse/dispatch-learnings.json"
EVENT_WRITER="$PROJECT_ROOT/.claude/hooks/pulse-event-writer.sh"

mkdir -p "$(dirname "$OUTCOME_LOG")"
touch "$OUTCOME_LOG"

ACTION="${1:-help}"
shift || true

case "$ACTION" in

# ─── OUTCOME: Record a dispatch result ────────────────────────
outcome)
    RULE_ID="${1:?Usage: outcome <rule_id> <success|failure|timeout> [notes]}"
    RESULT="${2:?Missing result (success|failure|timeout)}"
    NOTES="${3:-}"

    TIMESTAMP=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

    printf '{"ts":"%s","rule_id":"%s","result":"%s","notes":"%s"}\n' \
        "$TIMESTAMP" "$RULE_ID" "$RESULT" "$(echo "$NOTES" | sed 's/"/\\"/g')" \
        >> "$OUTCOME_LOG"

    bash "$EVENT_WRITER" "dispatch:outcome" "Learner" \
        "{\"rule_id\":\"$RULE_ID\",\"result\":\"$RESULT\"}" 2>/dev/null || true

    echo "[learner] Recorded: $RULE_ID → $RESULT"
    ;;

# ─── ANALYZE: Show rule effectiveness ────────────────────────
analyze)
    python3 << 'PYEOF'
import json
import sys
from collections import defaultdict
from pathlib import Path

root = Path(sys.argv[1] if len(sys.argv) > 1 else '.')
outcome_log = root / 'psi' / 'pulse' / 'dispatch-outcomes.jsonl'
dispatch_log = root / 'psi' / 'pulse' / 'dispatch-log.jsonl'

if not outcome_log.exists():
    print("[learner] No outcomes recorded yet.")
    sys.exit(0)

# Count outcomes per rule
stats = defaultdict(lambda: {'success': 0, 'failure': 0, 'timeout': 0, 'total': 0})

for line in open(outcome_log):
    line = line.strip()
    if not line:
        continue
    try:
        entry = json.loads(line)
        rule_id = entry.get('rule_id', 'unknown')
        result = entry.get('result', 'unknown')
        stats[rule_id][result] = stats[rule_id].get(result, 0) + 1
        stats[rule_id]['total'] += 1
    except json.JSONDecodeError:
        continue

# Count total dispatches per rule
dispatch_counts = defaultdict(int)
try:
    for line in open(dispatch_log):
        line = line.strip()
        if not line:
            continue
        try:
            entry = json.loads(line)
            rule_id = entry.get('rule_id', 'unknown')
            dispatch_counts[rule_id] += 1
        except:
            continue
except FileNotFoundError:
    pass

print("[learner] Rule Effectiveness Report")
print("=" * 60)
print(f"{'Rule ID':<30} {'Success':>8} {'Fail':>8} {'Rate':>8} {'Dispatches':>10}")
print("-" * 60)

for rule_id, s in sorted(stats.items()):
    total = s['total']
    success = s['success']
    rate = f"{success/total*100:.0f}%" if total > 0 else "N/A"
    dispatches = dispatch_counts.get(rule_id, 0)
    print(f"{rule_id:<30} {success:>8} {s['failure']:>8} {rate:>8} {dispatches:>10}")

print("-" * 60)

total_outcomes = sum(s['total'] for s in stats.values())
total_success = sum(s['success'] for s in stats.values())
overall_rate = f"{total_success/total_outcomes*100:.0f}%" if total_outcomes > 0 else "N/A"
print(f"{'TOTAL':<30} {total_success:>8} {sum(s['failure'] for s in stats.values()):>8} {overall_rate:>8}")
PYEOF
    ;;

# ─── TUNE: Auto-adjust rule confidence ───────────────────────
tune)
    python3 << 'PYEOF'
import json
import sys
from collections import defaultdict
from pathlib import Path
from datetime import datetime, timezone

root = Path(sys.argv[1] if len(sys.argv) > 1 else '.')
outcome_log = root / 'psi' / 'pulse' / 'dispatch-outcomes.jsonl'
rules_file = root / 'psi' / 'pulse' / 'dispatch-rules.json'
learnings_file = root / 'psi' / 'pulse' / 'dispatch-learnings.json'

if not outcome_log.exists() or not rules_file.exists():
    print("[learner] Need both outcomes and rules to tune.")
    sys.exit(0)

# Load outcomes
stats = defaultdict(lambda: {'success': 0, 'failure': 0, 'timeout': 0, 'total': 0})
for line in open(outcome_log):
    line = line.strip()
    if not line:
        continue
    try:
        entry = json.loads(line)
        rule_id = entry.get('rule_id', 'unknown')
        result = entry.get('result', 'unknown')
        stats[rule_id][result] = stats[rule_id].get(result, 0) + 1
        stats[rule_id]['total'] += 1
    except:
        continue

# Load rules
rules_data = json.load(open(rules_file))
rules = rules_data.get('rules', [])
adjustments = []

for rule in rules:
    rule_id = rule.get('id', '')
    if rule_id not in stats:
        continue

    s = stats[rule_id]
    if s['total'] < 3:
        continue  # Not enough data

    success_rate = s['success'] / s['total']

    # Tune cooldown based on success rate
    original_cooldown = rule.get('cooldown_minutes', 60)
    original_auto = rule.get('action', {}).get('auto_dispatch', False)

    if success_rate >= 0.8:
        # High success → reduce cooldown (dispatch more often)
        new_cooldown = max(5, int(original_cooldown * 0.7))
        if not original_auto:
            # Promote to auto-dispatch if consistently successful
            rule['action']['auto_dispatch'] = True
            adjustments.append(f"  {rule_id}: promoted to auto_dispatch (success rate {success_rate:.0%})")
    elif success_rate <= 0.3:
        # Low success → increase cooldown (dispatch less)
        new_cooldown = min(2880, int(original_cooldown * 1.5))
        if original_auto:
            # Demote from auto-dispatch
            rule['action']['auto_dispatch'] = False
            adjustments.append(f"  {rule_id}: demoted from auto_dispatch (success rate {success_rate:.0%})")
    else:
        new_cooldown = original_cooldown

    if new_cooldown != original_cooldown:
        rule['cooldown_minutes'] = new_cooldown
        adjustments.append(f"  {rule_id}: cooldown {original_cooldown}m → {new_cooldown}m (rate {success_rate:.0%})")

if adjustments:
    # Save updated rules
    with open(rules_file, 'w') as f:
        json.dump(rules_data, f, indent=2)

    # Save learnings
    learning = {
        'tuned_at': datetime.now(timezone.utc).isoformat(),
        'adjustments': adjustments,
        'rules_tuned': len(adjustments),
        'total_outcomes': sum(s['total'] for s in stats.values()),
    }

    learnings = {'history': []}
    if learnings_file.exists():
        try:
            learnings = json.load(open(learnings_file))
        except:
            pass

    learnings['history'].append(learning)
    learnings['last_tuned'] = learning['tuned_at']

    with open(learnings_file, 'w') as f:
        json.dump(learnings, f, indent=2)

    print(f"[learner] Tuned {len(adjustments)} rule(s):")
    for adj in adjustments:
        print(adj)
else:
    print("[learner] No adjustments needed (insufficient data or rules performing well)")
PYEOF
    ;;

# ─── REPORT: Full learning report ────────────────────────────
report)
    echo "=== Dispatch Learning Report ==="
    echo ""

    # Effectiveness
    bash "$0" analyze "$PROJECT_ROOT" 2>/dev/null || echo "No analysis data"
    echo ""

    # Learnings history
    if [ -f "$LEARNINGS_FILE" ]; then
        echo "=== Tuning History ==="
        python3 -c "
import json
data = json.load(open('$LEARNINGS_FILE'))
for h in data.get('history', [])[-5:]:
    print(f\"  [{h['tuned_at'][:16]}] {h['rules_tuned']} rule(s) adjusted\")
    for adj in h.get('adjustments', []):
        print(f'    {adj}')
" 2>/dev/null || echo "  No tuning history"
    else
        echo "=== No tuning history yet ==="
    fi
    ;;

# ─── HELP ─────────────────────────────────────────────────────
*)
    echo "Dispatch Learner — Phase D (Self-tuning)"
    echo ""
    echo "Usage:"
    echo "  outcome <rule_id> <success|failure|timeout> [notes]"
    echo "  analyze                   Show rule effectiveness"
    echo "  tune                      Auto-adjust rules from outcomes"
    echo "  report                    Full learning report"
    ;;

esac
