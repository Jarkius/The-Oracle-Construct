#!/usr/bin/env bash
set -euo pipefail
# Phase Q: Notification Intelligence — Adaptive Alert Filtering

export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

EVENT_WRITER="$PROJECT_ROOT/.claude/hooks/pulse/pulse-event-writer.sh"
PREFS_FILE="$PROJECT_ROOT/psi/state/pulse/notification-prefs.json"
NOTIFICATION_LOG="$PROJECT_ROOT/psi/state/pulse/notification-log.jsonl"

# ── Ensure prefs file exists with defaults ──────────────────────────────────

init_defaults() {
  local ts
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  python3 -c "
import json, sys
defaults = {
    'updated': '$ts',
    'event_weights': {
        'ci:fail': 1.0,
        'ci:pass': 0.2,
        'git:push': 0.3,
        'git:commit': 0.3,
        'session:start': 0.1,
        'session:end': 0.1,
        'context:compacted': 0.1,
        'task:completed': 0.6,
        'task:blocked': 0.9,
        'dispatch:outcome': 0.4,
        'heartbeat:alert': 0.9,
        'heartbeat:check': 0.1,
        'watchdog:restart': 0.8,
        'watchdog:restart_failed': 1.0,
        'team:created': 0.3,
        'team:dissolved': 0.2,
        'team:agent_complete': 0.4,
        'continuity:generated': 0.1,
        'metrics:collected': 0.1
    },
    'threshold': 0.5,
    'learning_rate': 0.1,
    'ack_count': {},
    'skip_count': {}
}
json.dump(defaults, sys.stdout, indent=2)
print()
" > "$PREFS_FILE"
}

if [[ ! -f "$PREFS_FILE" ]]; then
  mkdir -p "$(dirname "$PREFS_FILE")"
  init_defaults
fi

mkdir -p "$(dirname "$NOTIFICATION_LOG")"

# ── Commands ────────────────────────────────────────────────────────────────

cmd_filter() {
  # Read JSONL events from stdin, filter through learned preferences, output relevant ones
  python3 -c "
import json, sys, datetime

prefs_file = '$PREFS_FILE'
log_file = '$NOTIFICATION_LOG'

with open(prefs_file, 'r') as f:
    prefs = json.load(f)

weights = prefs.get('event_weights', {})
threshold = prefs.get('threshold', 0.5)

total = 0
passed = 0
suppressed = 0

for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    total += 1
    try:
        event = json.loads(line)
    except json.JSONDecodeError:
        continue

    event_type = event.get('type', event.get('event', ''))
    weight = weights.get(event_type, 0.5)

    if weight >= threshold:
        print(json.dumps(event))
        passed += 1
    else:
        suppressed += 1

# Log filter stats
ts = datetime.datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')
stats = {'ts': ts, 'total': total, 'passed': passed, 'suppressed': suppressed}
with open(log_file, 'a') as f:
    f.write(json.dumps(stats) + '\n')
"
}

cmd_digest() {
  local events_file="$PROJECT_ROOT/psi/state/pulse/events.jsonl"
  if [[ ! -f "$events_file" ]]; then
    echo "No events file found at $events_file"
    exit 1
  fi

  python3 -c "
import json, sys, datetime

events_file = '$events_file'
prefs_file = '$PREFS_FILE'

with open(prefs_file, 'r') as f:
    prefs = json.load(f)

weights = prefs.get('event_weights', {})
threshold = prefs.get('threshold', 0.5)

# Read last 50 events
lines = []
with open(events_file, 'r') as f:
    for line in f:
        line = line.strip()
        if line:
            lines.append(line)
last_50 = lines[-50:] if len(lines) >= 50 else lines

total = len(last_50)
critical = {}    # weight >= 0.8
notable = {}     # weight >= 0.5
suppressed_count = 0
suppressed_types = set()

for raw in last_50:
    try:
        event = json.loads(raw)
    except json.JSONDecodeError:
        continue

    event_type = event.get('type', event.get('event', ''))
    weight = weights.get(event_type, 0.5)

    if weight >= 0.8:
        critical[event_type] = critical.get(event_type, 0) + 1
    elif weight >= threshold:
        notable[event_type] = notable.get(event_type, 0) + 1
    else:
        suppressed_count += 1
        suppressed_types.add(event_type)

passed = sum(critical.values()) + sum(notable.values())
ts = datetime.datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S UTC')

print('=== Smart Digest ===')
print(f'Generated: {ts}')
print(f'Filtered: {total} events -> {passed} relevant')
print()

if critical:
    print('Critical:')
    for etype, count in sorted(critical.items(), key=lambda x: -x[1]):
        if 'fail' in etype:
            label = f'{count} failure{\"s\" if count != 1 else \"\"} detected'
        elif 'restart_failed' in etype:
            label = f'{count} service{\"s\" if count != 1 else \"\"} could not restart'
        else:
            label = f'{count} event{\"s\" if count != 1 else \"\"}'
        print(f'  - {etype}: {label}')
    print()

if notable:
    print('Notable:')
    for etype, count in sorted(notable.items(), key=lambda x: -x[1]):
        if 'completed' in etype:
            label = f'{count} task{\"s\" if count != 1 else \"\"} finished'
        elif 'dispatch' in etype:
            label = f'{count} successful dispatch{\"es\" if count != 1 else \"\"}'
        else:
            label = f'{count} event{\"s\" if count != 1 else \"\"}'
        print(f'  - {etype}: {label}')
    print()

if suppressed_count > 0:
    type_list = ', '.join(sorted(suppressed_types))
    print(f'Suppressed: {suppressed_count} low-priority events ({type_list})')
elif total == 0:
    print('No events to digest.')
"
}

cmd_learn_ack() {
  local event_type="${1:?Usage: pulse-notification-intel.sh learn-ack <event_type>}"

  python3 -c "
import json, sys, datetime

prefs_file = '$PREFS_FILE'
event_type = sys.argv[1]

with open(prefs_file, 'r') as f:
    prefs = json.load(f)

weights = prefs.get('event_weights', {})
learning_rate = prefs.get('learning_rate', 0.1)
ack_count = prefs.get('ack_count', {})

old_weight = weights.get(event_type, 0.5)
new_weight = min(1.0, old_weight + learning_rate)
new_weight = round(new_weight, 2)

weights[event_type] = new_weight
ack_count[event_type] = ack_count.get(event_type, 0) + 1

prefs['event_weights'] = weights
prefs['ack_count'] = ack_count
prefs['updated'] = datetime.datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')

with open(prefs_file, 'w') as f:
    json.dump(prefs, f, indent=2)
    f.write('\n')

print(f'Acknowledged: {event_type}')
print(f'  Weight: {old_weight:.2f} -> {new_weight:.2f}')
print(f'  Total acks: {ack_count[event_type]}')
" "$event_type"

  # Log the learning event
  if [[ -x "$EVENT_WRITER" ]]; then
    bash "$EVENT_WRITER" "notification:learn-ack" "System" "{\"event_type\":\"$event_type\"}" 2>/dev/null || true
  fi
}

cmd_learn_skip() {
  local event_type="${1:?Usage: pulse-notification-intel.sh learn-skip <event_type>}"

  python3 -c "
import json, sys, datetime

prefs_file = '$PREFS_FILE'
event_type = sys.argv[1]

with open(prefs_file, 'r') as f:
    prefs = json.load(f)

weights = prefs.get('event_weights', {})
learning_rate = prefs.get('learning_rate', 0.1)
skip_count = prefs.get('skip_count', {})

old_weight = weights.get(event_type, 0.5)
new_weight = max(0.0, old_weight - learning_rate)
new_weight = round(new_weight, 2)

weights[event_type] = new_weight
skip_count[event_type] = skip_count.get(event_type, 0) + 1

prefs['event_weights'] = weights
prefs['skip_count'] = skip_count
prefs['updated'] = datetime.datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')

with open(prefs_file, 'w') as f:
    json.dump(prefs, f, indent=2)
    f.write('\n')

print(f'Skipped: {event_type}')
print(f'  Weight: {old_weight:.2f} -> {new_weight:.2f}')
print(f'  Total skips: {skip_count[event_type]}')
" "$event_type"

  # Log the learning event
  if [[ -x "$EVENT_WRITER" ]]; then
    bash "$EVENT_WRITER" "notification:learn-skip" "System" "{\"event_type\":\"$event_type\"}" 2>/dev/null || true
  fi
}

cmd_preferences() {
  python3 -c "
import json, sys

prefs_file = '$PREFS_FILE'

with open(prefs_file, 'r') as f:
    prefs = json.load(f)

weights = prefs.get('event_weights', {})
threshold = prefs.get('threshold', 0.5)
learning_rate = prefs.get('learning_rate', 0.1)
ack_count = prefs.get('ack_count', {})
skip_count = prefs.get('skip_count', {})

# Sort by weight descending
sorted_weights = sorted(weights.items(), key=lambda x: -x[1])

active = [(k, v) for k, v in sorted_weights if v >= threshold]
suppressed = [(k, v) for k, v in sorted_weights if v < threshold]

print('=== Notification Preferences ===')
print(f'Threshold: {threshold} | Learning rate: {learning_rate}')
print()

if active:
    print('ACTIVE (shown):')
    for etype, weight in active:
        suffix = ''
        if etype in ack_count:
            suffix = f' (acked {ack_count[etype]}x)'
        print(f'  {etype:<24} — {weight:.2f}{suffix}')
    print()

if suppressed:
    print('SUPPRESSED (hidden):')
    for etype, weight in suppressed:
        suffix = ''
        if etype in skip_count:
            suffix = f' (skipped {skip_count[etype]}x)'
        print(f'  {etype:<24} — {weight:.2f}{suffix}')
"
}

cmd_reset() {
  init_defaults
  echo "Notification preferences reset to defaults."

  # Log the reset event
  if [[ -x "$EVENT_WRITER" ]]; then
    bash "$EVENT_WRITER" "notification:reset" "System" '{}' 2>/dev/null || true
  fi
}

show_help() {
  cat <<'HELP'
Phase Q: Notification Intelligence — Adaptive Alert Filtering

Usage: pulse-notification-intel.sh <command> [args]

Commands:
  filter              Filter events from stdin (JSONL), output relevant ones
  digest              Generate a smart digest of recent events
  learn-ack <type>    Record that operator acted on this event type (increases weight)
  learn-skip <type>   Record that operator dismissed this event type (decreases weight)
  preferences         Show current notification preferences
  reset               Reset all preferences to defaults

Examples:
  cat events.jsonl | bash pulse-notification-intel.sh filter
  bash pulse-notification-intel.sh digest
  bash pulse-notification-intel.sh learn-ack "ci:fail"
  bash pulse-notification-intel.sh learn-skip "session:start"
  bash pulse-notification-intel.sh preferences
  bash pulse-notification-intel.sh reset
HELP
}

# ── Command routing ─────────────────────────────────────────────────────────

command="${1:-help}"
shift || true

case "$command" in
  filter)
    cmd_filter
    ;;
  digest)
    cmd_digest
    ;;
  learn-ack)
    cmd_learn_ack "${1:-}"
    ;;
  learn-skip)
    cmd_learn_skip "${1:-}"
    ;;
  preferences)
    cmd_preferences
    ;;
  reset)
    cmd_reset
    ;;
  help|--help|-h)
    show_help
    ;;
  *)
    echo "Unknown command: $command"
    echo ""
    show_help
    exit 1
    ;;
esac
