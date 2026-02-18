#!/usr/bin/env bash
set -euo pipefail
#
# File: .claude/hooks/pulse-dashboard.sh
#
# Phase K: Health Dashboard
#
# Generates a static HTML dashboard showing system health, services,
# tasks, events, and dispatch activity. Served via heartbeat HTTP endpoint.
#
# Usage:
#   bash pulse-dashboard.sh generate     # Generate dashboard HTML
#   bash pulse-dashboard.sh serve        # Generate + open in browser
#   bash pulse-dashboard.sh json         # Raw JSON data for dashboard
#

export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

DASHBOARD_FILE="$PROJECT_ROOT/psi/pulse/dashboard.html"
DASHBOARD_JSON="$PROJECT_ROOT/psi/pulse/dashboard.json"

ACTION="${1:-help}"
shift || true

case "$ACTION" in

# ─── GENERATE: Create dashboard HTML ────────────────────────
generate)
    # First generate JSON data
    python3 << 'PYEOF'
import json
import sys
from datetime import datetime, timezone, timedelta
from collections import Counter, defaultdict
from pathlib import Path

root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path('.')

now = datetime.now(timezone.utc)
dashboard = {
    'generated_at': now.isoformat(),
    'health': {'score': 100, 'status': 'healthy'},
    'services': {},
    'tasks': {'pending': 0, 'completed': 0, 'blocked': 0, 'total': 0},
    'events': {'total': 0, 'last_24h': 0, 'by_type': {}},
    'dispatches': {'total': 0, 'success': 0, 'failure': 0},
    'patterns': [],
    'intel': {},
}

# Services
watchdog_status = root / 'psi' / 'pulse' / 'watchdog-status.json'
if watchdog_status.exists():
    try:
        ws = json.load(open(watchdog_status))
        dashboard['services'] = ws.get('services', {})
    except: pass

# Tasks
tasks_file = root / 'psi' / 'memory' / 'tasks' / 'active.json'
if tasks_file.exists():
    try:
        data = json.load(open(tasks_file))
        tasks = data.get('tasks', [])
        dashboard['tasks']['total'] = len(tasks)
        for t in tasks:
            s = t.get('status', 'pending')
            dashboard['tasks'][s] = dashboard['tasks'].get(s, 0) + 1
    except: pass

# Events
events_file = root / 'psi' / 'pulse' / 'events.jsonl'
if events_file.exists():
    events = []
    for line in open(events_file):
        line = line.strip()
        if not line: continue
        try:
            e = json.loads(line.rstrip('}') + '}')
            events.append(e)
        except: continue

    dashboard['events']['total'] = len(events)
    type_counts = Counter(e.get('type', 'unknown') for e in events)
    dashboard['events']['by_type'] = dict(type_counts.most_common(15))

    # Last 24h
    for e in events:
        try:
            ts = datetime.fromisoformat(e['ts'].replace('Z', '+00:00'))
            if (now - ts).total_seconds() < 86400:
                dashboard['events']['last_24h'] += 1
        except: continue

# Dispatches
outcomes_file = root / 'psi' / 'pulse' / 'dispatch-outcomes.jsonl'
if outcomes_file.exists():
    for line in open(outcomes_file):
        try:
            o = json.loads(line.strip())
            dashboard['dispatches']['total'] += 1
            r = o.get('result', 'unknown')
            dashboard['dispatches'][r] = dashboard['dispatches'].get(r, 0) + 1
        except: continue

# Patterns
patterns_file = root / 'psi' / 'pulse' / 'patterns.json'
if patterns_file.exists():
    try:
        data = json.load(open(patterns_file))
        dashboard['patterns'] = [
            {'type': p['type'], 'pattern': p['pattern'], 'confidence': p.get('confidence', 0)}
            for p in data.get('patterns', [])
        ]
    except: pass

# Intel
intel_file = root / 'psi' / 'pulse' / 'proactive-intel.json'
if intel_file.exists():
    try:
        intel = json.load(open(intel_file))
        dashboard['intel'] = {
            'health_score': intel.get('health_score', 100),
            'anomalies': len(intel.get('anomalies', [])),
            'suggestions': len(intel.get('suggestions', [])),
            'trends': len(intel.get('trends', [])),
            'summary': intel.get('summary', ''),
        }
        dashboard['health']['score'] = intel.get('health_score', 100)
        score = dashboard['health']['score']
        dashboard['health']['status'] = (
            'critical' if score < 50 else
            'warning' if score < 80 else
            'healthy'
        )
    except: pass

# Save JSON
json_path = root / 'psi' / 'pulse' / 'dashboard.json'
with open(json_path, 'w') as f:
    json.dump(dashboard, f, indent=2)
PYEOF

    # Generate HTML from JSON
    python3 << 'PYEOF'
import json
import sys
from pathlib import Path

root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path('.')
json_path = root / 'psi' / 'pulse' / 'dashboard.json'
html_path = root / 'psi' / 'pulse' / 'dashboard.html'

data = json.load(open(json_path))

health = data['health']
health_color = '#22c55e' if health['status'] == 'healthy' else '#eab308' if health['status'] == 'warning' else '#ef4444'

html = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Oracle Construct — Dashboard</title>
<style>
  * {{ margin: 0; padding: 0; box-sizing: border-box; }}
  body {{ font-family: 'Courier New', monospace; background: #0a0a0a; color: #00ff41; padding: 20px; }}
  .header {{ text-align: center; margin-bottom: 30px; border-bottom: 1px solid #1a3a1a; padding-bottom: 15px; }}
  .header h1 {{ font-size: 24px; color: #00ff41; }}
  .header .subtitle {{ color: #666; font-size: 12px; margin-top: 5px; }}
  .grid {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; }}
  .card {{ background: #111; border: 1px solid #1a3a1a; border-radius: 8px; padding: 15px; }}
  .card h2 {{ font-size: 14px; color: #888; margin-bottom: 10px; text-transform: uppercase; letter-spacing: 1px; }}
  .health-score {{ font-size: 48px; text-align: center; color: {health_color}; }}
  .health-label {{ text-align: center; color: #888; font-size: 12px; }}
  .stat {{ display: flex; justify-content: space-between; padding: 4px 0; border-bottom: 1px solid #1a1a1a; }}
  .stat-label {{ color: #888; }}
  .stat-value {{ color: #00ff41; }}
  .stat-value.warn {{ color: #eab308; }}
  .stat-value.crit {{ color: #ef4444; }}
  .service {{ display: flex; justify-content: space-between; padding: 6px 0; }}
  .service-status {{ padding: 2px 8px; border-radius: 4px; font-size: 11px; }}
  .service-status.running {{ background: #0a2a0a; color: #22c55e; }}
  .service-status.stopped {{ background: #2a0a0a; color: #ef4444; }}
  .service-status.restarted {{ background: #2a2a0a; color: #eab308; }}
  .pattern {{ padding: 6px 0; border-bottom: 1px solid #1a1a1a; font-size: 12px; }}
  .event-type {{ display: inline-block; padding: 2px 6px; margin: 2px; border-radius: 3px; background: #1a2a1a; font-size: 11px; }}
  .footer {{ text-align: center; margin-top: 30px; color: #333; font-size: 11px; }}
</style>
</head>
<body>
<div class="header">
  <h1>THE ORACLE CONSTRUCT</h1>
  <div class="subtitle">System Dashboard — Generated {data['generated_at'][:19]}Z</div>
</div>

<div class="grid">
  <div class="card">
    <h2>System Health</h2>
    <div class="health-score">{health['score']}</div>
    <div class="health-label">{health['status'].upper()}</div>
"""

# Intel summary
intel = data.get('intel', {})
if intel:
    html += f"""
    <div style="margin-top: 15px; font-size: 12px; color: #888;">
      {intel.get('summary', 'No intel available')}
    </div>
    <div style="margin-top: 10px;">
      <div class="stat"><span class="stat-label">Anomalies</span><span class="stat-value {'crit' if intel.get('anomalies', 0) > 0 else ''}">{intel.get('anomalies', 0)}</span></div>
      <div class="stat"><span class="stat-label">Suggestions</span><span class="stat-value">{intel.get('suggestions', 0)}</span></div>
      <div class="stat"><span class="stat-label">Trends</span><span class="stat-value">{intel.get('trends', 0)}</span></div>
    </div>
"""

html += """  </div>

  <div class="card">
    <h2>Services</h2>
"""

services = data.get('services', {})
if services:
    for name, info in services.items():
        status = info.get('status', 'unknown')
        css_class = 'running' if status == 'running' else 'stopped' if status in ('stopped', 'failed') else 'restarted'
        html += f'    <div class="service"><span>{name}</span><span class="service-status {css_class}">{status}</span></div>\n'
else:
    html += '    <div style="color: #666;">No service data (run watchdog check)</div>\n'

html += """  </div>

  <div class="card">
    <h2>Tasks</h2>
"""

tasks = data.get('tasks', {})
html += f"""
    <div class="stat"><span class="stat-label">Total</span><span class="stat-value">{tasks.get('total', 0)}</span></div>
    <div class="stat"><span class="stat-label">Pending</span><span class="stat-value">{tasks.get('pending', 0)}</span></div>
    <div class="stat"><span class="stat-label">Completed</span><span class="stat-value">{tasks.get('completed', 0)}</span></div>
    <div class="stat"><span class="stat-label">Blocked</span><span class="stat-value {'crit' if tasks.get('blocked', 0) > 0 else ''}">{tasks.get('blocked', 0)}</span></div>
"""

html += """  </div>

  <div class="card">
    <h2>Events</h2>
"""

events = data.get('events', {})
html += f"""
    <div class="stat"><span class="stat-label">Total</span><span class="stat-value">{events.get('total', 0)}</span></div>
    <div class="stat"><span class="stat-label">Last 24h</span><span class="stat-value">{events.get('last_24h', 0)}</span></div>
"""

html += '    <div style="margin-top: 10px;">\n'
for etype, count in list(events.get('by_type', {}).items())[:8]:
    html += f'      <span class="event-type">{etype}: {count}</span>\n'
html += '    </div>\n'

html += """  </div>

  <div class="card">
    <h2>Dispatches</h2>
"""

dispatches = data.get('dispatches', {})
total_d = dispatches.get('total', 0)
success_d = dispatches.get('success', 0)
rate = f"{success_d/total_d*100:.0f}%" if total_d > 0 else "N/A"
html += f"""
    <div class="stat"><span class="stat-label">Total</span><span class="stat-value">{total_d}</span></div>
    <div class="stat"><span class="stat-label">Success</span><span class="stat-value">{success_d}</span></div>
    <div class="stat"><span class="stat-label">Failure</span><span class="stat-value {'crit' if dispatches.get('failure', 0) > 0 else ''}">{dispatches.get('failure', 0)}</span></div>
    <div class="stat"><span class="stat-label">Success Rate</span><span class="stat-value">{rate}</span></div>
"""

html += """  </div>

  <div class="card">
    <h2>Patterns</h2>
"""

for p in data.get('patterns', []):
    conf = p.get('confidence', 0)
    bar = '#' * int(conf * 10)
    html += f'    <div class="pattern">{p["type"]}: {p["pattern"][:60]} <span style="color:#555">[{bar}]</span></div>\n'

if not data.get('patterns'):
    html += '    <div style="color: #666;">No patterns detected</div>\n'

html += """  </div>
</div>

<div class="footer">
  Oracle Construct Dashboard v1.0 — Phase K<br>
  "Everything that has a beginning has an end."
</div>
</body>
</html>"""

with open(html_path, 'w') as f:
    f.write(html)

print(f"[dashboard] Generated: {html_path}")
PYEOF
    ;;

# ─── SERVE: Generate and attempt to open ─────────────────────
serve)
    bash "$0" generate "$@"
    if command -v open &>/dev/null; then
        open "$DASHBOARD_FILE"
    elif command -v xdg-open &>/dev/null; then
        xdg-open "$DASHBOARD_FILE"
    else
        echo "[dashboard] Open: $DASHBOARD_FILE"
    fi
    ;;

# ─── JSON: Raw data ─────────────────────────────────────────
json)
    bash "$0" generate "$@" >/dev/null 2>&1
    cat "$DASHBOARD_JSON" 2>/dev/null || echo "{}"
    ;;

# ─── HELP ────────────────────────────────────────────────────
*)
    echo "Health Dashboard — Phase K"
    echo ""
    echo "Usage:"
    echo "  generate    Generate dashboard HTML"
    echo "  serve       Generate + open in browser"
    echo "  json        Raw JSON data"
    ;;

esac
