#!/usr/bin/env bash
set -euo pipefail
#
# File: .claude/hooks/pulse-event-dispatcher.sh
#
# Phase A: Event Dispatcher — The Nervous System (ADR-016)
#
# Reads recommendations, heartbeat alerts, and recent events.
# Matches against dispatch-rules.json.
# Outputs actionable dispatch commands (agent + task + context).
#
# This is the MISSING BRIDGE between detection and action.
#
# Usage:
#   bash pulse-event-dispatcher.sh                    # Full dispatch cycle
#   bash pulse-event-dispatcher.sh --dry-run          # Preview without dispatching
#   bash pulse-event-dispatcher.sh --check-only       # Only check, no output
#   bash pulse-event-dispatcher.sh --status            # Show dispatch log status
#
# Output: JSON dispatch instructions to stdout + dispatch-log.jsonl
#
# Flow:
#   recommendations.json ─┐
#   heartbeat alerts ──────┼─→ Rule Matcher → Dispatch Queue → Agent Spawn Instructions
#   recent events ─────────┘
#

export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Data files
RULES_FILE="$PROJECT_ROOT/psi/state/pulse/dispatch-rules.json"
RECOMMENDATIONS_FILE="$PROJECT_ROOT/psi/state/pulse/recommendations.json"
EVENTS_FILE="$PROJECT_ROOT/psi/state/pulse/events.jsonl"
DISPATCH_LOG="$PROJECT_ROOT/psi/state/pulse/dispatch-log.jsonl"
EVENT_WRITER="$PROJECT_ROOT/.claude/hooks/pulse/pulse-event-writer.sh"

# Flags
DRY_RUN=false
CHECK_ONLY=false
SHOW_STATUS=false

for arg in "$@"; do
    case "$arg" in
        --dry-run)    DRY_RUN=true ;;
        --check-only) CHECK_ONLY=true ;;
        --status)     SHOW_STATUS=true ;;
    esac
done

# Ensure dispatch log exists
mkdir -p "$(dirname "$DISPATCH_LOG")"
touch "$DISPATCH_LOG"

# ─── Status Mode ─────────────────────────────────────────────
if [ "$SHOW_STATUS" = true ]; then
    TOTAL=$(wc -l < "$DISPATCH_LOG" 2>/dev/null || echo "0")
    DISPATCHED=$(grep -c '"status":"dispatched"' "$DISPATCH_LOG" 2>/dev/null || echo "0")
    SKIPPED=$(grep -c '"status":"cooldown"' "$DISPATCH_LOG" 2>/dev/null || echo "0")
    PENDING=$(grep -c '"status":"pending_approval"' "$DISPATCH_LOG" 2>/dev/null || echo "0")

    echo "[dispatcher] Dispatch Log Status:"
    echo "  Total entries: $TOTAL"
    echo "  Dispatched:    $DISPATCHED"
    echo "  On cooldown:   $SKIPPED"
    echo "  Pending approval: $PENDING"

    # Show last 5 dispatches
    if [ "$TOTAL" -gt 0 ]; then
        echo ""
        echo "  Recent dispatches:"
        tail -5 "$DISPATCH_LOG" | while IFS= read -r line; do
            RULE=$(echo "$line" | grep -o '"rule_id":"[^"]*"' | cut -d'"' -f4)
            AGENT=$(echo "$line" | grep -o '"agent":"[^"]*"' | cut -d'"' -f4)
            STATUS=$(echo "$line" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
            TS=$(echo "$line" | grep -o '"ts":"[^"]*"' | cut -d'"' -f4)
            echo "    [$TS] $RULE → $AGENT ($STATUS)"
        done
    fi
    exit 0
fi

# ─── Preflight Checks ────────────────────────────────────────
if [ ! -f "$RULES_FILE" ]; then
    echo "[dispatcher] No dispatch rules found at $RULES_FILE — skipping"
    exit 0
fi

# Check if dispatcher is enabled
ENABLED=$(python3 -c "
import json, sys
try:
    rules = json.load(open('$RULES_FILE'))
    print('true' if rules.get('enabled', True) else 'false')
except: print('false')
" 2>/dev/null || echo "false")

if [ "$ENABLED" != "true" ]; then
    echo "[dispatcher] Disabled in config — skipping"
    exit 0
fi

# ─── Core Dispatch Logic (Python for JSON handling) ──────────
DISPATCHES=$(python3 << 'PYEOF'
import json
import sys
import os
from datetime import datetime, timezone, timedelta
from pathlib import Path

PROJECT_ROOT = os.environ.get('PROJECT_ROOT', '')
if not PROJECT_ROOT:
    sys.exit(0)

root = Path(PROJECT_ROOT)

def load_json(path, default):
    try:
        with open(path) as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return default

def load_jsonl(path, limit=50):
    """Load last N lines from JSONL file."""
    events = []
    try:
        lines = open(path).readlines()
        for line in lines[-limit:]:
            line = line.strip()
            if not line:
                continue
            # Fix double-brace issue
            while line.endswith('}}') and not line.endswith('"}}'):
                line = line[:-1]
            try:
                events.append(json.loads(line))
            except json.JSONDecodeError:
                continue
    except FileNotFoundError:
        pass
    return events

def check_cooldown(rule_id, cooldown_minutes, dispatch_log_path):
    """Check if a rule is on cooldown (was dispatched recently)."""
    cutoff = datetime.now(timezone.utc) - timedelta(minutes=cooldown_minutes)
    try:
        for line in open(dispatch_log_path).readlines():
            line = line.strip()
            if not line:
                continue
            try:
                entry = json.loads(line)
                if entry.get('rule_id') == rule_id and entry.get('status') in ('dispatched', 'pending_approval'):
                    entry_ts = datetime.fromisoformat(entry['ts'].replace('Z', '+00:00'))
                    if entry_ts > cutoff:
                        return True
            except (json.JSONDecodeError, KeyError, ValueError):
                continue
    except FileNotFoundError:
        pass
    return False

def urgency_value(urgency):
    return {'critical': 0, 'high': 1, 'medium': 2, 'low': 3, 'none': 4}.get(urgency, 4)

def severity_value(severity):
    return {'critical': 0, 'warning': 1, 'info': 2}.get(severity, 2)

def template_replace(template, context):
    """Recursive ${var.key.subkey} template replacement."""
    result = template
    def flatten(prefix, obj):
        pairs = {}
        if isinstance(obj, dict):
            for k, v in obj.items():
                full_key = f'{prefix}.{k}'
                if isinstance(v, dict):
                    pairs.update(flatten(full_key, v))
                else:
                    pairs[full_key] = str(v)
        return pairs

    all_pairs = {}
    for prefix, data in context.items():
        if isinstance(data, dict):
            all_pairs.update(flatten(prefix, data))

    for key, val in all_pairs.items():
        result = result.replace(f'${{{key}}}', val)
    return result

# Load data
rules_data = load_json(root / 'psi' / 'pulse' / 'dispatch-rules.json', {})
recommendations = load_json(root / 'psi' / 'pulse' / 'recommendations.json', {})
dispatch_log_path = str(root / 'psi' / 'pulse' / 'dispatch-log.jsonl')

# Load recent heartbeat alerts from events
events = load_jsonl(str(root / 'psi' / 'pulse' / 'events.jsonl'), 100)
recent_alerts = [e for e in events if e.get('type') == 'heartbeat:alert'
                 and datetime.fromisoformat(e.get('ts', '2000-01-01T00:00:00Z').replace('Z', '+00:00'))
                 > datetime.now(timezone.utc) - timedelta(hours=2)]

# Load recent ci:fail events (last 2 hours)
recent_failures = [e for e in events if e.get('type') == 'ci:fail'
                   and datetime.fromisoformat(e.get('ts', '2000-01-01T00:00:00Z').replace('Z', '+00:00'))
                   > datetime.now(timezone.utc) - timedelta(hours=2)]

rules = rules_data.get('rules', [])
max_concurrent = rules_data.get('max_concurrent_dispatches', 3)
approval_threshold = rules_data.get('require_approval_above_priority', 2)

dispatches = []
now = datetime.now(timezone.utc)

for rule in rules:
    rule_id = rule.get('id', 'unknown')
    trigger = rule.get('trigger', {})
    action = rule.get('action', {})
    cooldown = rule.get('cooldown_minutes', 60)

    # Check cooldown
    if check_cooldown(rule_id, cooldown, dispatch_log_path):
        continue

    matched = False
    context = {}

    # --- Match: recommendation type ---
    if trigger.get('type') == 'recommendation':
        rec_type = trigger.get('rec_type')
        min_urgency = trigger.get('min_urgency', 'low')

        for rec in recommendations.get('recommendations', []):
            if rec.get('type') == rec_type:
                if urgency_value(rec.get('urgency', 'low')) <= urgency_value(min_urgency):
                    matched = True
                    context = {'rec': rec}
                    break

    # --- Match: heartbeat alert ---
    elif trigger.get('type') == 'heartbeat_alert':
        check_name = trigger.get('check')
        min_severity = trigger.get('min_severity', 'warning')

        for alert in recent_alerts:
            alert_data = alert.get('data', {})
            if isinstance(alert_data, str):
                try:
                    alert_data = json.loads(alert_data)
                except:
                    alert_data = {}

            if alert_data.get('check') == check_name:
                alert_severity = alert_data.get('severity', 'info')
                if severity_value(alert_severity) <= severity_value(min_severity):
                    matched = True
                    context = {'alert': alert_data, 'event': alert}
                    break

    # --- Match: direct event ---
    elif trigger.get('type') == 'event':
        event_type = trigger.get('event_type')
        for event in recent_failures if 'fail' in (event_type or '') else events[-20:]:
            if event.get('type') == event_type:
                event_data = event.get('data', {})
                if isinstance(event_data, str):
                    try:
                        event_data = json.loads(event_data)
                    except:
                        event_data = {}
                matched = True
                context = {'event': {**event, 'data': event_data}}
                break

    if not matched:
        continue

    # Build dispatch instruction
    task_template = action.get('task', 'Investigate issue')
    task_text = template_replace(task_template, context)
    priority = action.get('priority', 3)
    auto_dispatch = action.get('auto_dispatch', False)

    # Determine status
    if priority > approval_threshold and not auto_dispatch:
        status = 'pending_approval'
    elif auto_dispatch:
        status = 'dispatched'
    else:
        status = 'pending_approval'

    dispatch = {
        'rule_id': rule_id,
        'agent': action.get('agent', 'Oracle'),
        'task': task_text,
        'priority': priority,
        'status': status,
        'auto_dispatch': auto_dispatch,
        'ts': now.isoformat(),
        'trigger_type': trigger.get('type'),
        'context_summary': str(context)[:200]
    }

    dispatches.append(dispatch)

    if len(dispatches) >= max_concurrent:
        break

# Sort by priority (lower = higher priority)
dispatches.sort(key=lambda d: d['priority'])

# Output as JSON
print(json.dumps({
    'dispatches': dispatches,
    'checked_at': now.isoformat(),
    'rules_evaluated': len(rules),
    'matches_found': len(dispatches)
}, indent=2))
PYEOF
)

# ─── Process Dispatches ──────────────────────────────────────

MATCH_COUNT=$(echo "$DISPATCHES" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('matches_found', 0))" 2>/dev/null || echo "0")

if [ "$MATCH_COUNT" = "0" ]; then
    if [ "$DRY_RUN" = true ]; then
        echo "[dispatcher] Dry run: No actionable dispatches found"
    fi
    exit 0
fi

if [ "$CHECK_ONLY" = true ]; then
    echo "[dispatcher] $MATCH_COUNT dispatch(es) would be triggered"
    echo "$DISPATCHES" | python3 -c "
import json, sys
d = json.load(sys.stdin)
for dispatch in d.get('dispatches', []):
    print(f\"  [{dispatch['status']}] {dispatch['rule_id']} → {dispatch['agent']}: {dispatch['task'][:80]}...\")
"
    exit 0
fi

if [ "$DRY_RUN" = true ]; then
    echo "[dispatcher] Dry run — $MATCH_COUNT dispatch(es) matched:"
    echo "$DISPATCHES" | python3 -c "
import json, sys
d = json.load(sys.stdin)
for dispatch in d.get('dispatches', []):
    auto = '🟢 AUTO' if dispatch.get('auto_dispatch') else '🟡 APPROVAL'
    print(f\"  [{auto}] {dispatch['rule_id']} → {dispatch['agent']}: {dispatch['task'][:80]}...\")
"
    exit 0
fi

# ─── Write to dispatch log + output for consumption ─────────

echo "$DISPATCHES" | python3 -c "
import json, sys
d = json.load(sys.stdin)
log_path = '$DISPATCH_LOG'

# Append each dispatch to log
with open(log_path, 'a') as f:
    for dispatch in d.get('dispatches', []):
        f.write(json.dumps(dispatch) + '\n')

# Output summary
auto = [x for x in d['dispatches'] if x.get('auto_dispatch')]
manual = [x for x in d['dispatches'] if not x.get('auto_dispatch')]

print(f\"[dispatcher] {len(d['dispatches'])} dispatch(es): {len(auto)} auto, {len(manual)} pending approval\")

# Output dispatch instructions for caller to consume
for dispatch in d['dispatches']:
    if dispatch.get('auto_dispatch'):
        print(f\"DISPATCH|{dispatch['agent']}|{dispatch['task']}|{dispatch['rule_id']}\")
" 2>/dev/null

# ─── Log event ───────────────────────────────────────────────
bash "$EVENT_WRITER" "dispatch:cycle" "Dispatcher" "{\"matches\":$MATCH_COUNT}" 2>/dev/null || true
