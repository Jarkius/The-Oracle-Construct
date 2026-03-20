#!/usr/bin/env python3
"""
Phase 8.2: Predictive Context Loader

Analyzes operator patterns from PULSE events to predict what context
should be pre-loaded at session start. Outputs a context profile
that the boot sequence can use.

Output: psi/state/pulse/context-profile.json
"""

import json
import os
from datetime import datetime, timedelta, timezone
from collections import Counter
from pathlib import Path


def main():
    repo_root = os.environ.get(
        'REPO_ROOT',
        os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    )
    root = Path(repo_root)

    events = load_events(root / 'psi' / 'pulse' / 'events.jsonl')
    patterns = load_json(root / 'psi' / 'pulse' / 'patterns.json', {})
    focus = read_file(root / 'psi' / 'inbox' / 'focus.md')

    now = datetime.now(timezone.utc)
    profile = build_profile(events, patterns, focus, now)

    out_file = root / 'psi' / 'pulse' / 'context-profile.json'
    with open(out_file, 'w') as f:
        json.dump(profile, f, indent=2)

    depth = profile.get('context_depth', 'standard')
    print(f'[predictive-loader] Context depth: {depth}, '
          f'predicted focus: {profile.get("predicted_focus", "unknown")}')


def build_profile(events, patterns, focus, now):
    """Build a context profile based on operator patterns."""
    profile = {
        'generated_at': now.isoformat(),
        'context_depth': 'standard',
        'predicted_focus': 'unknown',
        'session_density': 'normal',
        'recommended_agent': 'Oracle',
        'preload_files': [],
        'insights': [],
    }

    # --- Rhythm Analysis ---
    session_starts = [e for e in events if e.get('type') == 'session:start']
    current_hour = now.hour

    if session_starts:
        hours = extract_hours(session_starts)
        hour_counts = Counter(hours)

        # Is this a typical session time?
        if current_hour in hour_counts:
            profile['insights'].append(
                f'Session at typical hour ({current_hour:02d}:00 UTC, '
                f'{hour_counts[current_hour]} prior sessions)'
            )
        else:
            profile['insights'].append(
                f'Unusual session time ({current_hour:02d}:00 UTC) — '
                f'may indicate different work mode'
            )

    # --- Session Density (how many sessions in last 24h) ---
    recent_sessions = count_recent(session_starts, now, hours=24)
    if recent_sessions >= 4:
        profile['session_density'] = 'high'
        profile['context_depth'] = 'deep'
        profile['insights'].append(
            f'High session density ({recent_sessions} in 24h) — '
            f'deep context loading recommended'
        )
    elif recent_sessions == 0:
        profile['session_density'] = 'cold_start'
        profile['context_depth'] = 'comprehensive'
        profile['insights'].append(
            'Cold start (no sessions in 24h) — '
            'comprehensive context loading recommended'
        )

    # --- Activity Pattern (what kind of work was done recently) ---
    recent_events = get_recent_events(events, now, hours=48)
    event_types = Counter(e.get('type', '') for e in recent_events)

    git_activity = event_types.get('git:commit', 0) + event_types.get('git:push', 0)
    task_activity = event_types.get('task:completed', 0) + event_types.get('task:blocked', 0)

    if git_activity > 5:
        profile['recommended_agent'] = 'Neo'
        profile['insights'].append('Heavy git activity — likely in implementation mode')
    elif task_activity > 3:
        profile['recommended_agent'] = 'Oracle'
        profile['insights'].append('Task management activity — planning/orchestration mode')

    # --- Focus Prediction ---
    if focus:
        if 'CIS' in focus or 'cis' in focus:
            profile['predicted_focus'] = 'CIS Modernization'
            profile['preload_files'].extend([
                'psi/projects/cis-modern/CONTEXT.md',
                'psi/memory/adr/',
            ])
        elif 'Oracle Construct' in focus or 'Self-Improvement' in focus:
            profile['predicted_focus'] = 'Oracle Construct Evolution'
            profile['preload_files'].extend([
                'psi/state/focus.md',
                'psi/memory/evolution/',
            ])
        elif 'matrix-memory' in focus.lower():
            profile['predicted_focus'] = 'Memory System'
            profile['preload_files'].append('lib/matrix-memory-agents/')

    # --- Gap Detection (time since last session) ---
    if session_starts:
        last_start = get_latest_timestamp(session_starts)
        if last_start:
            gap_hours = (now - last_start).total_seconds() / 3600
            if gap_hours > 72:
                profile['context_depth'] = 'comprehensive'
                profile['insights'].append(
                    f'{gap_hours:.0f}h gap since last session — '
                    f'full context restore needed'
                )
            elif gap_hours < 1:
                profile['context_depth'] = 'minimal'
                profile['insights'].append(
                    'Rapid re-entry (<1h gap) — minimal context needed'
                )

    # --- Failure Memory ---
    failures = [e for e in recent_events if e.get('type') in ('ci:fail', 'error:repeated')]
    if failures:
        profile['insights'].append(
            f'{len(failures)} recent failure(s) — Smith may need to investigate'
        )
        if profile['recommended_agent'] == 'Oracle':
            profile['recommended_agent'] = 'Smith'

    return profile


def load_events(path):
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
    return events


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


def extract_hours(events):
    hours = []
    for e in events:
        try:
            ts = datetime.fromisoformat(e['ts'].replace('Z', '+00:00'))
            hours.append(ts.hour)
        except (ValueError, KeyError):
            pass
    return hours


def count_recent(events, now, hours=24):
    cutoff = now - timedelta(hours=hours)
    count = 0
    for e in events:
        try:
            ts = datetime.fromisoformat(e['ts'].replace('Z', '+00:00'))
            if ts > cutoff:
                count += 1
        except (ValueError, KeyError):
            pass
    return count


def get_recent_events(events, now, hours=48):
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


def get_latest_timestamp(events):
    latest = None
    for e in events:
        try:
            ts = datetime.fromisoformat(e['ts'].replace('Z', '+00:00'))
            if latest is None or ts > latest:
                latest = ts
        except (ValueError, KeyError):
            pass
    return latest


if __name__ == '__main__':
    main()
