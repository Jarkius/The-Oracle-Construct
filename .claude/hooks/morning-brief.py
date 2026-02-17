#!/usr/bin/env python3
"""
Phase 8.5: Morning Brief Synthesizer

Combines all intelligence layers into a single synthesized briefing:
- Focus (psi/inbox/focus.md)
- Tasks (psi/memory/tasks/active.json)
- Events (psi/pulse/events.jsonl — recent)
- Patterns (psi/pulse/patterns.json)
- Recommendations (psi/pulse/recommendations.json)
- Context Profile (psi/pulse/context-profile.json)
- Reminders (psi/pulse/reminders.json)
- Last Session (psi/memory/sessions/ — latest)

Output: Markdown to stdout (injected by session-start hook)
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
    now = datetime.now(timezone.utc)

    # Load all sources
    focus = read_file(root / 'psi' / 'inbox' / 'focus.md')
    tasks = load_json(root / 'psi' / 'memory' / 'tasks' / 'active.json', {})
    recommendations = load_json(root / 'psi' / 'pulse' / 'recommendations.json', {})
    context_profile = load_json(root / 'psi' / 'pulse' / 'context-profile.json', {})
    reminders = load_json(root / 'psi' / 'pulse' / 'reminders.json', {})
    patterns = load_json(root / 'psi' / 'pulse' / 'patterns.json', {})
    events = load_events(root / 'psi' / 'pulse' / 'events.jsonl', limit=50)
    last_session = find_last_session(root / 'psi' / 'memory' / 'sessions')

    # Build brief
    lines = []
    date_str = now.strftime('%Y-%m-%d %H:%M UTC')
    lines.append(f'## Morning Brief — {date_str}')
    lines.append('')

    # Focus
    focus_task = extract_focus_task(focus)
    if focus_task:
        lines.append(f'**Focus**: {focus_task}')

    # Last session
    if last_session:
        lines.append(f'**Last session**: {last_session}')

    # Context depth
    depth = context_profile.get('context_depth', 'standard')
    agent = context_profile.get('recommended_agent', 'Oracle')
    lines.append(f'**Context**: {depth} depth | Recommended agent: {agent}')
    lines.append('')

    # Tasks
    task_list = tasks.get('tasks', [])
    if task_list:
        blocked = [t for t in task_list if t.get('status') == 'blocked']
        in_progress = [t for t in task_list if t.get('status') == 'in_progress']
        pending = [t for t in task_list if t.get('status') == 'pending']

        lines.append(f'### Tasks — {len(task_list)} registered')
        if blocked:
            for t in blocked:
                lines.append(f'- **BLOCKED**: {t["task"]} ({t.get("assignee", "?")})')
        if in_progress:
            for t in in_progress:
                lines.append(f'- **Active**: {t["task"]} ({t.get("assignee", "?")})')
        if pending:
            for t in pending:
                lines.append(f'- Pending: {t["task"]} ({t.get("assignee", "?")})')
        lines.append('')

    # Events since last session
    recent = get_recent_events(events, now, hours=24)
    if recent:
        type_counts = {}
        for e in recent:
            t = e.get('type', 'unknown')
            type_counts[t] = type_counts.get(t, 0) + 1

        event_summary = ', '.join(f'{v} {k}' for k, v in sorted(type_counts.items()))
        lines.append(f'### System Pulse')
        lines.append(f'- {len(recent)} events in last 24h: {event_summary}')

        # Notable patterns
        for p in patterns.get('patterns', []):
            if p.get('recommendation'):
                lines.append(f'- Pattern: {p["pattern"]}')
        lines.append('')

    # Reminders
    overdue = get_overdue_reminders(reminders, now)
    if overdue:
        lines.append('### Reminders')
        for r in overdue:
            lines.append(f'- **Overdue**: {r.get("message", "?")} (due {r.get("due", "?")})')
        lines.append('')

    # Recommendations
    recs = recommendations.get('recommendations', [])
    if recs:
        lines.append('### Recommendations')
        for r in recs:
            urgency = r.get('urgency', 'low').upper()
            lines.append(f'- [{urgency}] {r.get("message", "")}')
            lines.append(f'  → {r.get("action", "")}')
        lines.append('')

    # Insights from predictive loader
    insights = context_profile.get('insights', [])
    if insights:
        lines.append('### Insights')
        for i in insights:
            lines.append(f'- {i}')
        lines.append('')

    # Service health (Phase 9 / ADR-011)
    service_health = check_daemon_health(root)
    if service_health:
        lines.append('### Service Health')
        for svc_line in service_health:
            lines.append(f'- {svc_line}')
        lines.append('')

    # Heartbeat alerts since last session (Phase 10 / ADR-012)
    heartbeat_alerts = get_heartbeat_alerts(events, now)
    if heartbeat_alerts:
        lines.append('### Heartbeat Alerts')
        for alert_msg in heartbeat_alerts:
            lines.append(f'- {alert_msg}')
        lines.append('')

    # Final recommendation
    lines.append('### Oracle Recommends')
    recommendation = synthesize_recommendation(
        focus_task, task_list, recs, context_profile, depth
    )
    lines.append(recommendation)
    lines.append('')

    print('\n'.join(lines))


def extract_focus_task(focus_text):
    """Extract the active task from focus.md."""
    for line in focus_text.split('\n'):
        if line.startswith('**Task**:'):
            return line.replace('**Task**:', '').strip()
    return None


def find_last_session(sessions_dir):
    """Get a one-line summary of the last session."""
    if not sessions_dir.exists():
        return None
    files = sorted(sessions_dir.rglob('*.md'))
    if not files:
        return None
    last = files[-1]
    # Extract date from filename
    name = last.stem
    return f'{name} ({last.parent.name})'


def get_recent_events(events, now, hours=24):
    cutoff = now - timedelta(hours=hours)
    result = []
    for e in events:
        try:
            ts = datetime.fromisoformat(e['ts'].replace('Z', '+00:00'))
            if ts > cutoff:
                result.append(e)
        except (ValueError, KeyError):
            pass
    return result


def get_overdue_reminders(reminders, now):
    overdue = []
    for r in reminders.get('reminders', []):
        if r.get('status') != 'pending':
            continue
        try:
            due = datetime.fromisoformat(r['due'].replace('Z', '+00:00'))
            if due < now:
                overdue.append(r)
        except (ValueError, KeyError):
            pass
    return overdue


def synthesize_recommendation(focus, tasks, recs, profile, depth):
    """Generate Oracle's recommendation based on all inputs."""
    blocked = [t for t in tasks if t.get('status') == 'blocked']
    critical_recs = [r for r in recs if r.get('urgency') in ('critical', 'high')]

    if blocked:
        return (f'Unblock **{blocked[0]["task"]}** first. '
                f'Blocked tasks slow everything downstream.')

    if critical_recs:
        return (f'Address: {critical_recs[0].get("message", "critical issue")}. '
                f'{critical_recs[0].get("action", "")}')

    predicted_focus = profile.get('predicted_focus', '')
    agent = profile.get('recommended_agent', 'Oracle')

    if predicted_focus:
        return (f'Continue with **{predicted_focus}**. '
                f'{agent} is ready. Context depth: {depth}.')

    if focus:
        return f'Continue with current focus: **{focus}**.'

    return 'No blockers. Proceed with highest-priority pending task.'


def get_heartbeat_alerts(events, now):
    """Extract heartbeat alerts since last session:start."""
    # Find last session:start to know where to look from
    last_session_start = None
    for e in reversed(events):
        if e.get('type') == 'session:start':
            try:
                last_session_start = datetime.fromisoformat(e['ts'].replace('Z', '+00:00'))
            except (ValueError, KeyError):
                pass
            break

    # If no session start found, look at last 24h
    cutoff = last_session_start or (now - timedelta(hours=24))

    alerts = []
    for e in events:
        if e.get('type') != 'heartbeat:alert':
            continue
        try:
            ts = datetime.fromisoformat(e['ts'].replace('Z', '+00:00'))
            if ts > cutoff:
                data = e.get('data', {})
                severity = data.get('severity', 'info').upper()
                message = data.get('message', 'Unknown alert')
                alerts.append(f'**[{severity}]** {message}')
        except (ValueError, KeyError):
            pass

    return alerts


def check_daemon_health(root):
    """Check daemon service health via matrix-services.sh status."""
    import subprocess

    services_script = root / '.claude' / 'hooks' / 'matrix-services.sh'
    if not services_script.exists():
        return None

    try:
        result = subprocess.run(
            ['bash', str(services_script), 'status'],
            capture_output=True, text=True, timeout=10,
            cwd=str(root)
        )
        # Parse output lines, skip header/footer
        lines = []
        for line in result.stdout.strip().split('\n'):
            line = line.strip()
            if line.startswith('[') and 'Status:' in line:
                # [indexer] Status: stopped → Indexer: stopped
                svc = line.split(']')[0].replace('[', '').strip().capitalize()
                status = line.split('Status:')[1].strip()
                lines.append(f'{svc}: {status}')
        return lines if lines else None
    except (subprocess.TimeoutExpired, FileNotFoundError, OSError):
        return None


def load_events(path, limit=50):
    events = []
    try:
        with open(path) as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    while line.endswith('}}') and not line.endswith('"}}'):
                        line = line[:-1]
                    events.append(json.loads(line))
                except json.JSONDecodeError:
                    continue
    except FileNotFoundError:
        pass
    return events[-limit:] if len(events) > limit else events


def load_json(path, default):
    try:
        with open(path) as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return default


def read_file(path):
    try:
        with open(path) as f:
            return f.read()
    except FileNotFoundError:
        return ''


if __name__ == '__main__':
    main()
