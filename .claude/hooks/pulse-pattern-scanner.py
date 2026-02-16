#!/usr/bin/env python3
"""
Sprint 4.1: PULSE Pattern Scanner

Scans psi/pulse/events.jsonl for recurring patterns and writes
detected patterns to psi/pulse/patterns.json
"""

import json
import sys
import os
from datetime import datetime, timedelta, timezone
from collections import Counter
from pathlib import Path

def main():
    repo_root = os.environ.get('REPO_ROOT', os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
    events_file = Path(repo_root) / 'psi' / 'pulse' / 'events.jsonl'
    patterns_file = Path(repo_root) / 'psi' / 'pulse' / 'patterns.json'

    # Read events
    events = []
    try:
        with open(events_file) as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    # Handle trailing }}} (malformed JSON from hooks)
                    while line.endswith('}}') and not line.endswith('"}}'):
                        line = line[:-1]
                    events.append(json.loads(line))
                except json.JSONDecodeError:
                    continue
    except FileNotFoundError:
        pass

    if not events:
        with open(patterns_file, 'w') as f:
            json.dump({
                'patterns': [],
                'scanned_at': datetime.now(timezone.utc).isoformat(),
                'event_count': 0
            }, f, indent=2)
        print('[pulse-scanner] No events found')
        return

    now = datetime.now(timezone.utc)
    patterns = []

    # --- Pattern 1: Session Rhythm ---
    session_starts = [e for e in events if e.get('type') == 'session:start']

    if len(session_starts) >= 3:
        hours = []
        for s in session_starts:
            try:
                ts = datetime.fromisoformat(s['ts'].replace('Z', '+00:00'))
                hours.append(ts.hour)
            except (ValueError, KeyError):
                pass
        if hours:
            hour_counts = Counter(hours)
            peak_hour = hour_counts.most_common(1)[0]
            patterns.append({
                'type': 'session_rhythm',
                'pattern': f'Peak activity at {peak_hour[0]:02d}:00 UTC ({peak_hour[1]} sessions)',
                'frequency': peak_hour[1],
                'confidence': min(peak_hour[1] / len(session_starts), 1.0),
                'data': {'peak_hour': peak_hour[0], 'total_sessions': len(session_starts)},
                'recommendation': f'Context preloading optimized for {peak_hour[0]:02d}:00 UTC sessions'
            })

    # --- Pattern 2: Git Velocity ---
    git_commits = [e for e in events if e.get('type') == 'git:commit']
    git_pushes = [e for e in events if e.get('type') == 'git:push']

    if len(git_commits) >= 3:
        sessions = max(len(session_starts), 1)
        cps = len(git_commits) / sessions
        patterns.append({
            'type': 'git_velocity',
            'pattern': f'{cps:.1f} commits/session ({len(git_commits)} total)',
            'frequency': len(git_commits),
            'confidence': 0.8,
            'data': {'total_commits': len(git_commits), 'total_pushes': len(git_pushes)},
            'recommendation': None
        })

    # --- Pattern 3: Failure Detection ---
    failures = [e for e in events if e.get('type') in ('ci:fail', 'error:repeated')]
    if failures:
        patterns.append({
            'type': 'failure_cluster',
            'pattern': f'{len(failures)} failure event(s) detected',
            'frequency': len(failures),
            'confidence': 0.9,
            'data': {'failure_types': list(set(e.get('type') for e in failures))},
            'recommendation': 'Smith should investigate recurring failures'
        })

    # --- Pattern 4: Task Velocity ---
    task_completed = [e for e in events if e.get('type') == 'task:completed']
    task_blocked = [e for e in events if e.get('type') == 'task:blocked']

    if task_completed or task_blocked:
        c = len(task_completed)
        b = len(task_blocked)
        ratio = c / max(c + b, 1)
        patterns.append({
            'type': 'task_velocity',
            'pattern': f'{c} completed, {b} blocked (throughput: {ratio:.0%})',
            'frequency': c + b,
            'confidence': 0.7,
            'data': {'completed': c, 'blocked': b, 'throughput': ratio},
            'recommendation': 'Blocked tasks need Oracle attention' if b > c else None
        })

    # --- Pattern 5: Activity Density (last 7 days) ---
    recent_events = []
    week_ago = now - timedelta(days=7)
    for e in events:
        try:
            ts = datetime.fromisoformat(e['ts'].replace('Z', '+00:00'))
            if ts > week_ago:
                recent_events.append(e)
        except (ValueError, KeyError):
            pass

    if recent_events:
        days_active = len(set(
            datetime.fromisoformat(e['ts'].replace('Z', '+00:00')).date()
            for e in recent_events if 'ts' in e
        ))
        epd = len(recent_events) / max(days_active, 1)
        patterns.append({
            'type': 'activity_density',
            'pattern': f'{epd:.0f} events/day over {days_active} active day(s)',
            'frequency': len(recent_events),
            'confidence': 0.6,
            'data': {'events_last_7d': len(recent_events), 'active_days': days_active},
            'recommendation': None
        })

    # --- Pattern 6: Focus Changes ---
    focus_changes = [e for e in events if e.get('type') == 'focus:changed']
    if len(focus_changes) >= 2:
        patterns.append({
            'type': 'focus_shifts',
            'pattern': f'{len(focus_changes)} focus change(s)',
            'frequency': len(focus_changes),
            'confidence': 0.5,
            'data': {'changes': len(focus_changes)},
            'recommendation': 'Review if focus changes indicate scope creep' if len(focus_changes) > 5 else None
        })

    # Write patterns
    output = {
        'patterns': patterns,
        'scanned_at': now.isoformat(),
        'event_count': len(events),
        'recent_event_count': len(recent_events) if recent_events else 0,
    }

    with open(patterns_file, 'w') as f:
        json.dump(output, f, indent=2)

    print(f'[pulse-scanner] {len(patterns)} patterns from {len(events)} events')

if __name__ == '__main__':
    main()
