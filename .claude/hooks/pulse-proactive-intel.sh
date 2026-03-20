#!/usr/bin/env bash
set -euo pipefail
#
# File: .claude/hooks/pulse-proactive-intel.sh
#
# Phase E: Proactive Intelligence (extends Phase A dispatcher)
#
# Goes beyond reactive event→dispatch. Analyzes trends, detects anomalies,
# predicts what the operator needs before they ask.
#
# Usage:
#   bash pulse-proactive-intel.sh analyze       # Full proactive analysis
#   bash pulse-proactive-intel.sh anomalies     # Detect anomalies only
#   bash pulse-proactive-intel.sh suggest        # Task suggestions
#   bash pulse-proactive-intel.sh trends         # Trend analysis
#   bash pulse-proactive-intel.sh brief          # One-line summary for boot
#

export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

EVENTS_FILE="$PROJECT_ROOT/psi/state/pulse/events.jsonl"
PATTERNS_FILE="$PROJECT_ROOT/psi/state/pulse/patterns.json"
TASKS_FILE="$PROJECT_ROOT/psi/memory/tasks/active.json"
DISPATCH_LOG="$PROJECT_ROOT/psi/state/pulse/dispatch-log.jsonl"
OUTCOMES_LOG="$PROJECT_ROOT/psi/state/pulse/dispatch-outcomes.jsonl"
INTEL_FILE="$PROJECT_ROOT/psi/state/pulse/proactive-intel.json"
EVENT_WRITER="$PROJECT_ROOT/.claude/hooks/pulse-event-writer.sh"

ACTION="${1:-analyze}"
shift || true

case "$ACTION" in

# ─── ANALYZE: Full proactive intelligence scan ───────────────
analyze)
    python3 << 'PYEOF'
import json
import sys
from collections import defaultdict, Counter
from datetime import datetime, timezone, timedelta
from pathlib import Path

root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path('.')
events_file = root / 'psi' / 'pulse' / 'events.jsonl'
tasks_file = root / 'psi' / 'memory' / 'tasks' / 'active.json'
dispatch_log = root / 'psi' / 'pulse' / 'dispatch-log.jsonl'
outcomes_log = root / 'psi' / 'pulse' / 'dispatch-outcomes.jsonl'
intel_file = root / 'psi' / 'pulse' / 'proactive-intel.json'

now = datetime.now(timezone.utc)
intel = {
    'generated_at': now.isoformat(),
    'anomalies': [],
    'suggestions': [],
    'trends': [],
    'health_score': 100,
    'summary': '',
}

# ─── Load events ─────────────────────────────
events = []
if events_file.exists():
    for line in open(events_file):
        line = line.strip()
        if not line:
            continue
        try:
            e = json.loads(line.rstrip('}') + '}')
            if 'ts' in e:
                try:
                    e['_dt'] = datetime.fromisoformat(e['ts'].replace('Z', '+00:00'))
                except:
                    e['_dt'] = now
            events.append(e)
        except:
            continue

recent = [e for e in events if '_dt' in e and (now - e['_dt']).total_seconds() < 86400]
last_6h = [e for e in events if '_dt' in e and (now - e['_dt']).total_seconds() < 21600]

# ─── Anomaly Detection ─────────────────────────
# 1. Error spike: 3+ failures in 1 hour
hour_buckets = defaultdict(int)
for e in recent:
    if e.get('type', '') in ('ci:fail', 'error:repeated', 'gateway:error'):
        hour_key = e['_dt'].strftime('%Y-%m-%d-%H')
        hour_buckets[hour_key] += 1

for hour, count in hour_buckets.items():
    if count >= 3:
        intel['anomalies'].append({
            'type': 'error_spike',
            'severity': 'critical',
            'message': f'{count} errors in hour {hour}',
            'action': 'Dispatch Smith for investigation',
        })
        intel['health_score'] -= 20

# 2. Dispatch storm: 5+ dispatches in 30 minutes
dispatches = []
if dispatch_log.exists():
    for line in open(dispatch_log):
        try:
            d = json.loads(line.strip())
            if 'ts' in d:
                d['_dt'] = datetime.fromisoformat(d['ts'].replace('Z', '+00:00'))
                dispatches.append(d)
        except:
            continue

recent_dispatches = [d for d in dispatches if '_dt' in d and (now - d['_dt']).total_seconds() < 1800]
if len(recent_dispatches) >= 5:
    intel['anomalies'].append({
        'type': 'dispatch_storm',
        'severity': 'warning',
        'message': f'{len(recent_dispatches)} dispatches in 30 min — possible cascade',
        'action': 'Review dispatch rules for over-triggering',
    })
    intel['health_score'] -= 10

# 3. Silent system: no events in 6+ hours during expected active time
if len(last_6h) == 0 and len(recent) > 10:
    intel['anomalies'].append({
        'type': 'system_silent',
        'severity': 'info',
        'message': 'No events in 6 hours despite recent activity',
        'action': 'Check if services are running',
    })

# 4. Repeated failures on same rule
if outcomes_log.exists():
    rule_failures = defaultdict(int)
    for line in open(outcomes_log):
        try:
            o = json.loads(line.strip())
            if o.get('result') == 'failure':
                rule_failures[o.get('rule_id', 'unknown')] += 1
        except:
            continue
    for rule_id, count in rule_failures.items():
        if count >= 3:
            intel['anomalies'].append({
                'type': 'persistent_failure',
                'severity': 'warning',
                'message': f'Rule {rule_id} failed {count} times — may need tuning',
                'action': f'Run: bash .claude/hooks/pulse-dispatch-learner.sh tune',
            })
            intel['health_score'] -= 5

# ─── Trend Analysis ─────────────────────────
# Events per day trend
day_counts = Counter()
for e in events:
    if '_dt' in e:
        day_counts[e['_dt'].strftime('%Y-%m-%d')] += 1

if len(day_counts) >= 2:
    sorted_days = sorted(day_counts.items())
    recent_avg = sum(v for _, v in sorted_days[-3:]) / min(3, len(sorted_days))
    older_avg = sum(v for _, v in sorted_days[:-3]) / max(1, len(sorted_days) - 3) if len(sorted_days) > 3 else recent_avg

    if recent_avg > older_avg * 1.5:
        intel['trends'].append({
            'type': 'activity_increasing',
            'message': f'Activity trending up: {recent_avg:.0f} events/day (was {older_avg:.0f})',
            'implication': 'System getting more use — monitor resource usage',
        })
    elif recent_avg < older_avg * 0.5 and older_avg > 5:
        intel['trends'].append({
            'type': 'activity_decreasing',
            'message': f'Activity trending down: {recent_avg:.0f} events/day (was {older_avg:.0f})',
            'implication': 'Possible disengagement or shift to different project',
        })

# Git velocity trend
git_events = [e for e in recent if e.get('type', '').startswith('git:')]
if len(git_events) > 10:
    commits = sum(1 for e in git_events if e['type'] == 'git:commit')
    pushes = sum(1 for e in git_events if e['type'] == 'git:push')
    if pushes > 0 and commits / pushes < 0.3:
        intel['trends'].append({
            'type': 'micro_commits',
            'message': f'Low commit density: {commits} commits for {pushes} pushes',
            'implication': 'Consider batching changes into meaningful commits',
        })

# Session frequency
sessions = [e for e in events if e.get('type') == 'session:start']
if len(sessions) >= 5:
    gaps = []
    for i in range(1, len(sessions)):
        if '_dt' in sessions[i] and '_dt' in sessions[i-1]:
            gap = (sessions[i]['_dt'] - sessions[i-1]['_dt']).total_seconds() / 3600
            if 0 < gap < 24:
                gaps.append(gap)
    if gaps:
        avg_gap = sum(gaps) / len(gaps)
        intel['trends'].append({
            'type': 'session_rhythm',
            'message': f'Average {avg_gap:.1f}h between sessions ({len(sessions)} total)',
            'implication': 'deep' if avg_gap < 1 else 'standard' if avg_gap < 4 else 'light',
        })

# ─── Task Suggestions ─────────────────────────
tasks = []
if tasks_file.exists():
    try:
        data = json.load(open(tasks_file))
        tasks = data.get('tasks', [])
    except:
        pass

pending = [t for t in tasks if t.get('status') == 'pending']
completed = [t for t in tasks if t.get('status') == 'completed']

# Suggest oldest pending task
if pending:
    oldest = min(pending, key=lambda t: t.get('created', ''))
    intel['suggestions'].append({
        'type': 'oldest_pending',
        'message': f'Oldest pending task: {oldest["task"][:60]}',
        'assignee': oldest.get('assignee', 'Oracle'),
        'priority': 'medium',
    })

# If all tasks complete, suggest new work
if len(pending) == 0 and len(completed) > 0:
    intel['suggestions'].append({
        'type': 'all_clear',
        'message': 'All tasks complete — ready for new mission',
        'assignee': 'Oracle',
        'priority': 'low',
    })

# Suggest based on dispatch success
if outcomes_log.exists():
    success_rules = defaultdict(int)
    for line in open(outcomes_log):
        try:
            o = json.loads(line.strip())
            if o.get('result') == 'success':
                success_rules[o.get('rule_id', '')] += 1
        except:
            continue
    if success_rules:
        best_rule = max(success_rules, key=success_rules.get)
        intel['suggestions'].append({
            'type': 'proven_pattern',
            'message': f'Rule {best_rule} has {success_rules[best_rule]} successes — consider expanding',
            'assignee': 'Architect',
            'priority': 'low',
        })

# ─── Health Score ─────────────────────────
intel['health_score'] = max(0, min(100, intel['health_score']))

# ─── Summary ─────────────────────────
anomaly_count = len(intel['anomalies'])
suggestion_count = len(intel['suggestions'])
trend_count = len(intel['trends'])

if anomaly_count == 0:
    intel['summary'] = f'System healthy ({intel["health_score"]}/100). {suggestion_count} suggestion(s), {trend_count} trend(s).'
else:
    critical = sum(1 for a in intel['anomalies'] if a['severity'] == 'critical')
    if critical > 0:
        intel['summary'] = f'CRITICAL: {critical} critical anomaly(ies). Health: {intel["health_score"]}/100.'
    else:
        intel['summary'] = f'{anomaly_count} anomaly(ies) detected. Health: {intel["health_score"]}/100.'

# ─── Save ─────────────────────────
with open(intel_file, 'w') as f:
    json.dump(intel, f, indent=2)

print(f'[intel] {intel["summary"]}')
if intel['anomalies']:
    print(f'  Anomalies:')
    for a in intel['anomalies']:
        print(f'    [{a["severity"]}] {a["message"]}')
if intel['trends']:
    print(f'  Trends:')
    for t in intel['trends']:
        print(f'    {t["message"]}')
if intel['suggestions']:
    print(f'  Suggestions:')
    for s in intel['suggestions']:
        print(f'    [{s["priority"]}] {s["message"]}')
PYEOF
    ;;

# ─── ANOMALIES: Quick anomaly check ─────────────────────────
anomalies)
    bash "$0" analyze "$@" 2>/dev/null | grep -A100 "Anomalies:" || echo "[intel] No anomalies detected"
    ;;

# ─── SUGGEST: Task suggestions ──────────────────────────────
suggest)
    bash "$0" analyze "$@" 2>/dev/null | grep -A100 "Suggestions:" || echo "[intel] No suggestions"
    ;;

# ─── TRENDS: Trend analysis ─────────────────────────────────
trends)
    bash "$0" analyze "$@" 2>/dev/null | grep -A100 "Trends:" || echo "[intel] No trends detected"
    ;;

# ─── BRIEF: One-line for boot injection ─────────────────────
brief)
    if [ -f "$INTEL_FILE" ]; then
        python3 -c "
import json
data = json.load(open('$INTEL_FILE'))
print(data.get('summary', 'No intel available'))
" 2>/dev/null || echo "[intel] No intel available"
    else
        bash "$0" analyze "$@" 2>/dev/null | head -1
    fi
    ;;

# ─── HELP ────────────────────────────────────────────────────
*)
    echo "Proactive Intelligence — Phase E"
    echo ""
    echo "Usage:"
    echo "  analyze     Full proactive analysis"
    echo "  anomalies   Detect anomalies only"
    echo "  suggest     Task suggestions"
    echo "  trends      Trend analysis"
    echo "  brief       One-line summary"
    ;;

esac
