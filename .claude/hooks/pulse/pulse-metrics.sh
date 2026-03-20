#!/usr/bin/env bash
set -euo pipefail
#
# File: .claude/hooks/pulse-metrics.sh
#
# Phase O: Metric Tracking — Historical Performance Data
#
# Tracks historical performance metrics over time, building a data set
# for trend analysis. Appends snapshots to metrics.jsonl and provides
# summary, trend, and report commands.
#
# Usage: bash pulse-metrics.sh <command>
#
# Commands:
#   collect  — Collect current metrics snapshot and append to JSONL
#   summary  — Generate summary statistics from historical data
#   trends   — Analyze trends (increasing/decreasing/stable)
#   report   — Human-readable report
#   daily    — Daily digest (collect + report)
#

export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

EVENT_WRITER="$PROJECT_ROOT/.claude/hooks/pulse/pulse-event-writer.sh"
METRICS_FILE="$PROJECT_ROOT/psi/state/pulse/metrics.jsonl"
METRICS_SUMMARY="$PROJECT_ROOT/psi/state/pulse/metrics-summary.json"

mkdir -p "$(dirname "$METRICS_FILE")"

# ---------------------------------------------------------------------------
# collect — Gather current metrics and append as one JSONL line
# ---------------------------------------------------------------------------
cmd_collect() {
  local ts
  ts="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

  # --- Git metrics ---
  local commits_today=0 branches=0 uncommitted=0
  if git -C "$PROJECT_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    commits_today=$(git -C "$PROJECT_ROOT" log --since=midnight --oneline 2>/dev/null | wc -l | tr -d ' ')
    branches=$(git -C "$PROJECT_ROOT" branch 2>/dev/null | wc -l | tr -d ' ')
    uncommitted=$(git -C "$PROJECT_ROOT" status --short 2>/dev/null | wc -l | tr -d ' ')
  fi

  # --- Task metrics ---
  local pending=0 completed=0 blocked=0
  local tasks_file="$PROJECT_ROOT/psi/memory/tasks/active.json"
  if [[ -f "$tasks_file" ]]; then
    pending=$(python3 -c "
import json, sys
try:
    data = json.load(open('$tasks_file'))
    tasks = data.get('tasks', [])
    print(sum(1 for t in tasks if t.get('status') == 'pending'))
except Exception:
    print(0)
" 2>/dev/null || echo 0)
    completed=$(python3 -c "
import json, sys
try:
    data = json.load(open('$tasks_file'))
    tasks = data.get('tasks', [])
    print(sum(1 for t in tasks if t.get('status') == 'completed'))
except Exception:
    print(0)
" 2>/dev/null || echo 0)
    blocked=$(python3 -c "
import json, sys
try:
    data = json.load(open('$tasks_file'))
    tasks = data.get('tasks', [])
    print(sum(1 for t in tasks if t.get('status') == 'blocked'))
except Exception:
    print(0)
" 2>/dev/null || echo 0)
  fi

  # --- Event metrics (last 24h) ---
  local total_24h=0 failures_24h=0 commits_24h=0 sessions_24h=0
  local events_file="$PROJECT_ROOT/psi/state/pulse/events.jsonl"
  if [[ -f "$events_file" ]]; then
    local cutoff
    cutoff="$(date -u -d '24 hours ago' '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u -v-24H '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || echo '')"
    if [[ -n "$cutoff" ]]; then
      total_24h=$(python3 -c "
import json, sys
cutoff = '$cutoff'
count = 0
for line in open('$events_file'):
    line = line.strip()
    if not line:
        continue
    try:
        ev = json.loads(line)
        if ev.get('ts', ev.get('timestamp', '')) >= cutoff:
            count += 1
    except Exception:
        pass
print(count)
" 2>/dev/null || echo 0)
      failures_24h=$(python3 -c "
import json, sys
cutoff = '$cutoff'
count = 0
fail_types = {'ci:fail', 'dispatch:failure', 'dispatch:failed'}
for line in open('$events_file'):
    line = line.strip()
    if not line:
        continue
    try:
        ev = json.loads(line)
        if ev.get('ts', ev.get('timestamp', '')) >= cutoff and ev.get('type', ev.get('event', '')) in fail_types:
            count += 1
    except Exception:
        pass
print(count)
" 2>/dev/null || echo 0)
      commits_24h=$(python3 -c "
import json, sys
cutoff = '$cutoff'
count = 0
for line in open('$events_file'):
    line = line.strip()
    if not line:
        continue
    try:
        ev = json.loads(line)
        if ev.get('ts', ev.get('timestamp', '')) >= cutoff and ev.get('type', ev.get('event', '')) in ('git:commit', 'git:push'):
            count += 1
    except Exception:
        pass
print(count)
" 2>/dev/null || echo 0)
      sessions_24h=$(python3 -c "
import json, sys
cutoff = '$cutoff'
count = 0
for line in open('$events_file'):
    line = line.strip()
    if not line:
        continue
    try:
        ev = json.loads(line)
        if ev.get('ts', ev.get('timestamp', '')) >= cutoff and ev.get('type', ev.get('event', '')) == 'session:start':
            count += 1
    except Exception:
        pass
print(count)
" 2>/dev/null || echo 0)
    fi
  fi

  # --- Skills metrics ---
  local skills_total=0
  local commands_dir="$PROJECT_ROOT/.claude/commands"
  local workflows_dir="$PROJECT_ROOT/.agent/workflows"
  if [[ -d "$commands_dir" ]]; then
    skills_total=$(find "$commands_dir" -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
  fi
  if [[ -d "$workflows_dir" ]]; then
    local wf_count
    wf_count=$(find "$workflows_dir" -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
    skills_total=$((skills_total + wf_count))
  fi

  # --- Health metrics ---
  local hooks_executable=0 hooks_total=0 services_running=0
  local hooks_dir="$PROJECT_ROOT/.claude/hooks"
  if [[ -d "$hooks_dir" ]]; then
    hooks_total=$(find "$hooks_dir" -name '*.sh' 2>/dev/null | wc -l | tr -d ' ')
    hooks_executable=$(find "$hooks_dir" -name '*.sh' -executable 2>/dev/null | wc -l | tr -d ' ')
  fi

  # Count PID files with live processes
  local pid_dir="$PROJECT_ROOT/psi/state/pulse/daemon-logs"
  if [[ -d "$pid_dir" ]]; then
    for pidfile in "$pid_dir"/*.pid; do
      [[ -f "$pidfile" ]] || continue
      local pid
      pid="$(cat "$pidfile" 2>/dev/null || echo '')"
      if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
        services_running=$((services_running + 1))
      fi
    done
  fi

  # --- Build JSON and append ---
  local json_line
  json_line=$(python3 -c "
import json
data = {
    'ts': '$ts',
    'git': {
        'commits_today': int('$commits_today'),
        'branches': int('$branches'),
        'uncommitted': int('$uncommitted')
    },
    'tasks': {
        'pending': int('$pending'),
        'completed': int('$completed'),
        'blocked': int('$blocked')
    },
    'events': {
        'total_24h': int('$total_24h'),
        'failures_24h': int('$failures_24h'),
        'commits_24h': int('$commits_24h'),
        'sessions_24h': int('$sessions_24h')
    },
    'skills': {
        'total': int('$skills_total')
    },
    'health': {
        'hooks_executable': int('$hooks_executable'),
        'hooks_total': int('$hooks_total'),
        'services_running': int('$services_running')
    }
}
print(json.dumps(data, separators=(',', ':')))
")

  echo "$json_line" >> "$METRICS_FILE"
  echo "Metrics collected at $ts"

  # Log event
  if [[ -x "$EVENT_WRITER" ]]; then
    bash "$EVENT_WRITER" "metrics:collected" "System" '{"file":"'"$METRICS_FILE"'"}' 2>/dev/null || true
  fi
}

# ---------------------------------------------------------------------------
# summary — Generate summary statistics from historical data
# ---------------------------------------------------------------------------
cmd_summary() {
  if [[ ! -f "$METRICS_FILE" ]]; then
    echo "No metrics data found. Run 'collect' first."
    return 1
  fi

  python3 << 'PYEOF'
import json, sys, os
from datetime import datetime

metrics_file = os.environ.get("METRICS_FILE", "")
summary_file = os.environ.get("METRICS_SUMMARY", "")

entries = []
with open(metrics_file) as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            entries.append(json.loads(line))
        except Exception:
            pass

if not entries:
    print("No valid entries found.")
    sys.exit(1)

# Flatten nested dicts to dot-notation keys
def flatten(d, prefix=""):
    result = {}
    for k, v in d.items():
        key = f"{prefix}.{k}" if prefix else k
        if isinstance(v, dict):
            result.update(flatten(v, key))
        elif isinstance(v, (int, float)):
            result[key] = v
    return result

flat_entries = [flatten(e) for e in entries]

# Collect all numeric keys (skip 'ts')
all_keys = set()
for fe in flat_entries:
    all_keys.update(fe.keys())
all_keys.discard("ts")
all_keys = sorted(all_keys)

stats = {}
for key in all_keys:
    values = [fe[key] for fe in flat_entries if key in fe]
    if not values:
        continue
    stats[key] = {
        "avg": round(sum(values) / len(values), 2),
        "min": min(values),
        "max": max(values),
        "latest": values[-1]
    }

# Latest entry
latest = entries[-1] if entries else {}

summary = {
    "generated": datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ"),
    "total_entries": len(entries),
    "date_range": {
        "first": entries[0].get("ts", "unknown"),
        "last": entries[-1].get("ts", "unknown")
    },
    "stats": stats,
    "latest": latest
}

with open(summary_file, "w") as f:
    json.dump(summary, f, indent=2)

print(f"Summary generated: {len(entries)} entries, {len(stats)} metrics tracked.")
print(f"Date range: {summary['date_range']['first']} — {summary['date_range']['last']}")
print(f"Saved to: {summary_file}")
PYEOF
}

# ---------------------------------------------------------------------------
# trends — Analyze trends (increasing/decreasing/stable)
# ---------------------------------------------------------------------------
cmd_trends() {
  if [[ ! -f "$METRICS_FILE" ]]; then
    echo "No metrics data found. Run 'collect' first."
    return 1
  fi

  python3 << 'PYEOF'
import json, os

metrics_file = os.environ.get("METRICS_FILE", "")

entries = []
with open(metrics_file) as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            entries.append(json.loads(line))
        except Exception:
            pass

if len(entries) < 2:
    print("Need at least 2 snapshots for trend analysis.")
    raise SystemExit(1)

# Take last 5 (or fewer)
recent = entries[-5:]

def flatten(d, prefix=""):
    result = {}
    for k, v in d.items():
        key = f"{prefix}.{k}" if prefix else k
        if isinstance(v, dict):
            result.update(flatten(v, key))
        elif isinstance(v, (int, float)):
            result[key] = v
    return result

flat = [flatten(e) for e in recent]

# Key metrics to track
key_metrics = [
    "git.commits_today",
    "git.branches",
    "git.uncommitted",
    "tasks.pending",
    "tasks.completed",
    "tasks.blocked",
    "events.total_24h",
    "events.failures_24h",
    "events.commits_24h",
    "events.sessions_24h",
    "skills.total",
    "health.hooks_executable",
    "health.services_running",
]

print("=== Metric Trends (last {} snapshots) ===\n".format(len(recent)))

for metric in key_metrics:
    values = [f.get(metric) for f in flat if metric in f]
    if not values or len(values) < 2:
        continue
    latest = values[-1]
    previous = values[:-1]
    avg_prev = sum(previous) / len(previous)

    if latest > avg_prev:
        arrow = "\u2191"  # up arrow
        direction = "increasing"
    elif latest < avg_prev:
        arrow = "\u2193"  # down arrow
        direction = "decreasing"
    else:
        arrow = "\u2192"  # right arrow
        direction = "stable"

    print(f"  {arrow} {metric}: {latest} ({direction}, prev avg: {avg_prev:.1f})")

print()
PYEOF
}

# ---------------------------------------------------------------------------
# report — Human-readable report combining latest metrics + trends
# ---------------------------------------------------------------------------
cmd_report() {
  if [[ ! -f "$METRICS_FILE" ]]; then
    echo "No metrics data found. Run 'collect' first."
    return 1
  fi

  python3 << 'PYEOF'
import json, os
from datetime import datetime

metrics_file = os.environ.get("METRICS_FILE", "")

entries = []
with open(metrics_file) as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            entries.append(json.loads(line))
        except Exception:
            pass

if not entries:
    print("No valid entries found.")
    raise SystemExit(1)

latest = entries[-1]
g = latest.get("git", {})
t = latest.get("tasks", {})
e = latest.get("events", {})
h = latest.get("health", {})
s = latest.get("skills", {})

now = datetime.utcnow().strftime("%Y-%m-%d %H:%M UTC")

print("=== Matrix Metrics Report ===")
print(f"Generated: {now}")
print()
print(f"Git: {g.get('commits_today', 0)} commits today, {g.get('branches', 0)} branches, {g.get('uncommitted', 0)} uncommitted")
print(f"Tasks: {t.get('pending', 0)} pending, {t.get('completed', 0)} completed, {t.get('blocked', 0)} blocked")
print(f"Events (24h): {e.get('total_24h', 0)} total, {e.get('failures_24h', 0)} failures, {e.get('commits_24h', 0)} commits")
print(f"Health: {h.get('hooks_executable', 0)}/{h.get('hooks_total', 0)} hooks executable, {h.get('services_running', 0)} services running")
print(f"Skills: {s.get('total', 0)} total")
print()

# Inline trends if enough data
if len(entries) >= 2:
    recent = entries[-5:]

    def flatten(d, prefix=""):
        result = {}
        for k, v in d.items():
            key = f"{prefix}.{k}" if prefix else k
            if isinstance(v, dict):
                result.update(flatten(v, key))
            elif isinstance(v, (int, float)):
                result[key] = v
        return result

    flat = [flatten(e) for e in recent]

    key_metrics = [
        ("git.commits_today", "Commits today"),
        ("tasks.pending", "Pending tasks"),
        ("tasks.blocked", "Blocked tasks"),
        ("events.total_24h", "Events (24h)"),
        ("events.failures_24h", "Failures (24h)"),
        ("health.hooks_executable", "Hooks executable"),
    ]

    trends = []
    for metric, label in key_metrics:
        values = [f.get(metric) for f in flat if metric in f]
        if not values or len(values) < 2:
            continue
        latest_val = values[-1]
        previous = values[:-1]
        avg_prev = sum(previous) / len(previous)
        if latest_val > avg_prev:
            trends.append(f"\u2191 {label}")
        elif latest_val < avg_prev:
            trends.append(f"\u2193 {label}")
        else:
            trends.append(f"\u2192 {label}")

    if trends:
        print("Trends: " + "  |  ".join(trends))
        print()
else:
    print("Trends: Not enough data yet (need 2+ snapshots)")
    print()
PYEOF
}

# ---------------------------------------------------------------------------
# daily — Daily digest: collect then report
# ---------------------------------------------------------------------------
cmd_daily() {
  cmd_collect
  echo ""
  cmd_report
}

# ---------------------------------------------------------------------------
# Main: route command
# ---------------------------------------------------------------------------
export METRICS_FILE
export METRICS_SUMMARY

COMMAND="${1:-help}"

case "$COMMAND" in
  collect)
    cmd_collect
    ;;
  summary)
    cmd_summary
    ;;
  trends)
    cmd_trends
    ;;
  report)
    cmd_report
    ;;
  daily)
    cmd_daily
    ;;
  *)
    echo "Phase O: Metric Tracking — Historical Performance Data"
    echo ""
    echo "Usage: bash $(basename "$0") <command>"
    echo ""
    echo "Commands:"
    echo "  collect  — Collect current metrics snapshot and append to JSONL"
    echo "  summary  — Generate summary statistics from historical data"
    echo "  trends   — Analyze trends (increasing/decreasing/stable)"
    echo "  report   — Human-readable report"
    echo "  daily    — Daily digest (collect + report)"
    echo ""
    echo "Files:"
    echo "  Metrics: $METRICS_FILE"
    echo "  Summary: $METRICS_SUMMARY"
    exit 1
    ;;
esac
