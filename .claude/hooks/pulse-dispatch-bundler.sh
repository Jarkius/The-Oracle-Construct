#!/usr/bin/env bash
set -euo pipefail
#
# File: .claude/hooks/pulse-dispatch-bundler.sh
#
# Phase H: Smart Dispatch Bundling
#
# Groups related dispatches into coordinated team operations.
# Instead of spawning 3 separate agents, creates a team with shared context.
#
# Usage:
#   bash pulse-dispatch-bundler.sh bundle       # Bundle pending dispatches
#   bash pulse-dispatch-bundler.sh preview      # Preview what would bundle
#   bash pulse-dispatch-bundler.sh history      # Show past bundles
#

export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

DISPATCH_LOG="$PROJECT_ROOT/psi/state/pulse/dispatch-log.jsonl"
BUNDLE_LOG="$PROJECT_ROOT/psi/state/pulse/bundle-log.jsonl"
ORCHESTRATOR="$PROJECT_ROOT/.claude/hooks/pulse-team-orchestrator.sh"
EVENT_WRITER="$PROJECT_ROOT/.claude/hooks/pulse-event-writer.sh"

mkdir -p "$(dirname "$BUNDLE_LOG")"

ACTION="${1:-help}"
shift || true

case "$ACTION" in

# ─── BUNDLE: Group pending dispatches into teams ─────────────
bundle|preview)
    DRY_RUN=false
    [ "$ACTION" = "preview" ] && DRY_RUN=true

    python3 << PYEOF
import json
import sys
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path

root = Path('$PROJECT_ROOT')
dispatch_log = root / 'psi' / 'pulse' / 'dispatch-log.jsonl'
bundle_log = root / 'psi' / 'pulse' / 'bundle-log.jsonl'
dry_run = $( [ "$DRY_RUN" = "true" ] && echo "True" || echo "False" )

if not dispatch_log.exists():
    print("[bundler] No dispatch log found")
    sys.exit(0)

# Load recent pending dispatches (last 30 minutes)
now = datetime.now(timezone.utc)
pending = []
for line in open(dispatch_log):
    line = line.strip()
    if not line:
        continue
    try:
        d = json.loads(line)
        if d.get('status') in ('dispatched', 'pending_approval'):
            try:
                ts = datetime.fromisoformat(d['ts'].replace('Z', '+00:00'))
                age_min = (now - ts).total_seconds() / 60
                if age_min < 30:
                    pending.append(d)
            except:
                continue
    except:
        continue

if len(pending) < 2:
    print(f"[bundler] Only {len(pending)} dispatch(es) — no bundling needed")
    sys.exit(0)

# Group by agent
agent_groups = defaultdict(list)
for d in pending:
    agent = d.get('agent', 'Oracle')
    agent_groups[agent].append(d)

# Group by related topics (same rule type prefix)
topic_groups = defaultdict(list)
for d in pending:
    rule_id = d.get('rule_id', '')
    # Extract topic prefix: "ci-failure-investigate" → "ci"
    topic = rule_id.split('-')[0] if '-' in rule_id else 'general'
    topic_groups[topic].append(d)

bundles = []

# Bundle same-topic dispatches with different agents into teams
for topic, dispatches in topic_groups.items():
    if len(dispatches) < 2:
        continue

    agents = list(set(d.get('agent', 'Oracle') for d in dispatches))
    tasks = [d.get('task', '')[:80] for d in dispatches]
    mission = f"Coordinated {topic} response: " + "; ".join(tasks[:3])

    bundles.append({
        'topic': topic,
        'agents': agents,
        'dispatches': dispatches,
        'mission': mission[:200],
        'count': len(dispatches),
    })

# Also bundle if same agent gets 3+ tasks
for agent, dispatches in agent_groups.items():
    if len(dispatches) >= 3:
        # Check if already in a topic bundle
        bundled_ids = set()
        for b in bundles:
            for d in b['dispatches']:
                bundled_ids.add(d.get('rule_id', '') + d.get('ts', ''))

        unbundled = [d for d in dispatches
                     if (d.get('rule_id', '') + d.get('ts', '')) not in bundled_ids]
        if len(unbundled) >= 2:
            tasks = [d.get('task', '')[:60] for d in unbundled]
            bundles.append({
                'topic': f'{agent.lower()}-multi',
                'agents': [agent],
                'dispatches': unbundled,
                'mission': f"{agent} batch: " + "; ".join(tasks[:3]),
                'count': len(unbundled),
            })

if not bundles:
    print(f"[bundler] {len(pending)} dispatches but no bundling opportunities")
    sys.exit(0)

print(f"[bundler] Found {len(bundles)} bundle(s):")
for b in bundles:
    agents_str = ", ".join(b['agents'])
    print(f"  [{b['topic']}] {b['count']} dispatches → Team({agents_str})")
    print(f"    Mission: {b['mission'][:100]}")

if dry_run:
    print("\n[bundler] Preview mode — no teams created")
else:
    # Log bundles
    for b in bundles:
        entry = {
            'ts': now.isoformat(),
            'topic': b['topic'],
            'agents': b['agents'],
            'count': b['count'],
            'mission': b['mission'],
        }
        with open(bundle_log, 'a') as f:
            f.write(json.dumps(entry) + '\n')

    print(f"\n[bundler] {len(bundles)} bundle(s) logged")
    print("[bundler] Use team orchestrator to create teams from bundles")
PYEOF
    ;;

# ─── HISTORY: Show past bundles ──────────────────────────────
history)
    if [ ! -f "$BUNDLE_LOG" ]; then
        echo "[bundler] No bundle history"
        exit 0
    fi

    echo "=== Bundle History ==="
    tail -10 "$BUNDLE_LOG" | while IFS= read -r line; do
        python3 -c "
import json
b = json.loads('$(echo "$line" | sed "s/'/'\\\\''/g")')
print(f\"  [{b['ts'][:16]}] {b['topic']}: {b['count']} dispatches → {', '.join(b['agents'])}\")
" 2>/dev/null || true
    done
    ;;

# ─── HELP ────────────────────────────────────────────────────
*)
    echo "Smart Dispatch Bundler — Phase H"
    echo ""
    echo "Usage:"
    echo "  bundle      Group pending dispatches into teams"
    echo "  preview     Preview bundles without creating"
    echo "  history     Show past bundles"
    ;;

esac
