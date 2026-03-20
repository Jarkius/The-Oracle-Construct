#!/usr/bin/env python3
"""
Phase 8.1: Pattern-to-Recommendation Engine

Reads patterns.json + active.json + recent sessions and generates
actionable recommendations for the morning brief.

Output: psi/state/pulse/recommendations.json
"""

import json
import os
from datetime import datetime, timedelta, timezone
from pathlib import Path


def main():
    repo_root = os.environ.get(
        'REPO_ROOT',
        os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    )
    root = Path(repo_root)

    patterns = load_json(root / 'psi' / 'pulse' / 'patterns.json', {})
    tasks = load_json(root / 'psi' / 'memory' / 'tasks' / 'active.json', {})
    reminders = load_json(root / 'psi' / 'pulse' / 'reminders.json', {})

    recommendations = []
    now = datetime.now(timezone.utc)

    # --- Rule 1: Blocked tasks need immediate attention ---
    blocked = [t for t in tasks.get('tasks', []) if t.get('status') == 'blocked']
    if blocked:
        for t in blocked:
            age = task_age_days(t, now)
            urgency = 'critical' if age > 2 else 'high'
            recommendations.append({
                'type': 'blocked_task',
                'urgency': urgency,
                'message': f"Task '{t['task']}' blocked for {age}d — needs unblocking",
                'action': f"Investigate blocker for {t['id']}. Escalate if external dependency.",
                'assignee': t.get('assignee', 'Oracle')
            })

    # --- Rule 2: Stale pending tasks (>3 days untouched) ---
    pending = [t for t in tasks.get('tasks', []) if t.get('status') == 'pending']
    for t in pending:
        age = task_age_days(t, now)
        if age > 3:
            recommendations.append({
                'type': 'stale_task',
                'urgency': 'medium',
                'message': f"Task '{t['task']}' pending for {age}d — start or deprioritize",
                'action': f"Either begin {t['id']} or move to backlog with reason.",
                'assignee': t.get('assignee', 'Oracle')
            })

    # --- Rule 3: Pattern-based recommendations ---
    for p in patterns.get('patterns', []):
        ptype = p.get('type')

        # High failure rate
        if ptype == 'failure_cluster' and p.get('frequency', 0) >= 3:
            recommendations.append({
                'type': 'failure_alert',
                'urgency': 'high',
                'message': f"{p['frequency']} failures detected — Smith should investigate",
                'action': '/smith to review failure cluster and root-cause',
                'assignee': 'Smith'
            })

        # Low task throughput
        if ptype == 'task_velocity':
            throughput = p.get('data', {}).get('throughput', 1.0)
            if throughput < 0.5:
                recommendations.append({
                    'type': 'low_throughput',
                    'urgency': 'medium',
                    'message': f"Task throughput at {throughput:.0%} — more blocked than completed",
                    'action': 'Oracle should review task sizing and blockers',
                    'assignee': 'Oracle'
                })

        # Focus churn (too many context switches)
        if ptype == 'focus_shifts' and p.get('frequency', 0) > 3:
            recommendations.append({
                'type': 'focus_churn',
                'urgency': 'medium',
                'message': f"{p['frequency']} focus changes — potential scope creep",
                'action': 'Pick ONE focus and hold it for at least 2 sessions',
                'assignee': 'Oracle'
            })

        # High git velocity with low commits-per-push ratio
        if ptype == 'git_velocity':
            commits = p.get('data', {}).get('total_commits', 0)
            pushes = p.get('data', {}).get('total_pushes', 0)
            if pushes > 0 and commits / pushes < 0.5:
                recommendations.append({
                    'type': 'push_heavy',
                    'urgency': 'low',
                    'message': f"Push:commit ratio high ({pushes} pushes for {commits} commits) — batch commits",
                    'action': 'Group related changes into fewer, meaningful commits',
                    'assignee': 'Neo'
                })

    # --- Rule 4: Overdue reminders ---
    for r in reminders.get('reminders', []):
        if r.get('status') == 'pending':
            due = r.get('due', '')
            try:
                due_dt = datetime.fromisoformat(due.replace('Z', '+00:00'))
                if due_dt < now:
                    days_overdue = (now - due_dt).days
                    recommendations.append({
                        'type': 'overdue_reminder',
                        'urgency': 'high' if days_overdue > 3 else 'medium',
                        'message': f"Reminder overdue by {days_overdue}d: {r.get('message', 'unknown')}",
                        'action': f"Address or reschedule reminder from {r.get('created_by', 'unknown')}",
                        'assignee': 'Oracle'
                    })
            except (ValueError, TypeError):
                pass

    # --- Rule 5: Session continuity ---
    sessions_dir = root / 'psi' / 'memory' / 'sessions'
    if sessions_dir.exists():
        session_files = sorted(sessions_dir.rglob('*.md'))
        if session_files:
            latest = session_files[-1]
            try:
                mtime = datetime.fromtimestamp(latest.stat().st_mtime, tz=timezone.utc)
                gap = (now - mtime).total_seconds() / 3600
                if gap > 48:
                    recommendations.append({
                        'type': 'session_gap',
                        'urgency': 'low',
                        'message': f"Last session was {gap:.0f}h ago — context may be stale",
                        'action': 'Run /recap to restore context before starting deep work',
                        'assignee': 'Oracle'
                    })
            except (OSError, ValueError):
                pass

    # --- Rule 6: Positive momentum ---
    if not recommendations:
        recommendations.append({
            'type': 'all_clear',
            'urgency': 'none',
            'message': 'No blockers, no failures, no overdue items. System is healthy.',
            'action': 'Proceed with current focus. Consider starting next priority task.',
            'assignee': 'Oracle'
        })

    # Sort by urgency
    urgency_order = {'critical': 0, 'high': 1, 'medium': 2, 'low': 3, 'none': 4}
    recommendations.sort(key=lambda r: urgency_order.get(r.get('urgency', 'low'), 3))

    output = {
        'recommendations': recommendations,
        'generated_at': now.isoformat(),
        'pattern_count': len(patterns.get('patterns', [])),
        'task_count': len(tasks.get('tasks', [])),
    }

    out_file = root / 'psi' / 'pulse' / 'recommendations.json'
    with open(out_file, 'w') as f:
        json.dump(output, f, indent=2)

    # Summary for stdout
    urgencies = [r['urgency'] for r in recommendations]
    critical = urgencies.count('critical')
    high = urgencies.count('high')
    summary = f"[recommender] {len(recommendations)} recommendation(s)"
    if critical:
        summary += f" ({critical} CRITICAL)"
    elif high:
        summary += f" ({high} high priority)"
    print(summary)


def load_json(path, default):
    try:
        with open(path) as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return default


def task_age_days(task, now):
    updated = task.get('updated', task.get('created', ''))
    try:
        dt = datetime.fromisoformat(updated.replace('Z', '+00:00'))
        return (now - dt).days
    except (ValueError, TypeError):
        return 0


if __name__ == '__main__':
    main()
