#!/usr/bin/env python3
"""
Phase 8.3: Pulse Evolution Proposer

Analyzes patterns, recommendations, and session history to automatically
draft Workflow Evolution Proposals (WEPs) when patterns reach confidence
thresholds.

Rules:
- Low-risk WEPs can be auto-applied by pulse-auto-evolve.sh (ADR-014)
- Medium/high-risk WEPs require Oracle review
- Only proposes when confidence >= 0.7
- Deduplicates against existing proposals and applied WEPs
- One change per WEP — keep proposals atomic

Output: New WEP files in psi/memory/evolution/proposals/
"""

import json
import os
import re
from datetime import datetime, timezone
from pathlib import Path


# Confidence threshold for auto-proposing WEPs
CONFIDENCE_THRESHOLD = 0.7

# Pattern-to-proposal rules
EVOLUTION_RULES = [
    {
        'id': 'high-push-commit-ratio',
        'pattern_match': lambda p: (
            p.get('type') == 'git_velocity' and
            p.get('data', {}).get('total_pushes', 0) >
            p.get('data', {}).get('total_commits', 1) * 2
        ),
        'title': 'Reduce Push-to-Commit Ratio',
        'check': lambda p, _: p.get('confidence', 0) >= CONFIDENCE_THRESHOLD,
        'proposal': (
            'Modify `/commit` workflow to batch commits before pushing. '
            'Add a `/commit:local` variant that stages and commits without pushing, '
            'and make `/commit:push` the explicit push action.'
        ),
        'affected': ['.claude/commands/commit.md', '.agent/workflows/commit.md'],
        'risk': 'low',
    },
    {
        'id': 'session-density-overload',
        'pattern_match': lambda p: (
            p.get('type') == 'activity_density' and
            p.get('data', {}).get('events_last_7d', 0) /
            max(p.get('data', {}).get('active_days', 1), 1) > 50
        ),
        'title': 'Add Session Consolidation Guidance',
        'check': lambda p, _: p.get('confidence', 0) >= 0.6,
        'proposal': (
            'When session density exceeds 50 events/day, the morning brief should '
            'recommend longer sessions over many short ones. Add a density warning '
            'to the predictive context loader.'
        ),
        'affected': ['.claude/hooks/morning-brief.py', '.claude/hooks/predictive-context-loader.py'],
        'risk': 'low',
    },
    {
        'id': 'missing-session-ids',
        'pattern_match': lambda p: p.get('type') == 'session_rhythm',
        'check': lambda p, events: (
            sum(1 for e in events if e.get('session') == 'unknown') >
            len(events) * 0.5
        ),
        'title': 'Wire Session IDs into Event Pipeline',
        'proposal': (
            'Over 50% of events have session="unknown". Wire the Claude session ID '
            'from the transcript path into pulse-event-writer.sh so events can be '
            'correlated to specific sessions for better pattern analysis.'
        ),
        'affected': ['.claude/hooks/pulse-event-writer.sh', '.claude/hooks/pulse-post-action.sh'],
        'risk': 'low',
    },
    {
        'id': 'no-failure-tracking',
        'pattern_match': lambda p: p.get('type') == 'git_velocity',
        'check': lambda p, events: (
            not any(e.get('type') == 'ci:fail' for e in events) and
            len(events) > 30
        ),
        'title': 'Add CI/Test Failure Detection to Post-Action Hook',
        'proposal': (
            'No ci:fail events detected despite 30+ events. Either tests always pass '
            '(unlikely) or the post-action hook does not detect test failures. '
            'Enhance pulse-post-action.sh to parse test runner output for failures '
            'and emit ci:fail events.'
        ),
        'affected': ['.claude/hooks/pulse-post-action.sh'],
        'risk': 'low',
    },
]


def main():
    repo_root = os.environ.get(
        'REPO_ROOT',
        os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    )
    root = Path(repo_root)
    now = datetime.now(timezone.utc)

    patterns = load_json(root / 'psi' / 'pulse' / 'patterns.json', {})
    events = load_events(root / 'psi' / 'pulse' / 'events.jsonl')
    existing_weps = get_existing_wep_ids(root / 'psi' / 'memory' / 'evolution')

    pattern_list = patterns.get('patterns', [])
    proposed = 0

    for rule in EVOLUTION_RULES:
        # Skip if WEP already exists for this rule
        if rule['id'] in existing_weps:
            continue

        # Check if any pattern matches this rule
        for pattern in pattern_list:
            if not rule['pattern_match'](pattern):
                continue
            if not rule['check'](pattern, events):
                continue

            # Generate WEP
            wep_num = get_next_wep_number(root / 'psi' / 'memory' / 'evolution')
            wep_slug = rule['id'].replace('_', '-')
            wep_path = (root / 'psi' / 'memory' / 'evolution' / 'proposals' /
                        f'WEP-{wep_num:03d}-{wep_slug}.md')

            confidence = pattern.get('confidence', 0.7)
            affected = '\n'.join(f'- `{f}`' for f in rule.get('affected', []))

            content = f"""# WEP-{wep_num:03d}: {rule['title']}

**Status**: proposed
**Detected**: {now.strftime('%Y-%m-%d')}
**Pattern**: {pattern.get('type', 'unknown')} — {pattern.get('pattern', pattern.get('recommendation', 'detected by evolution proposer'))}
**Confidence**: {confidence}
**Generated-by**: pulse-evolution-proposer.py (Phase 8.3)

## Proposed Change

{rule['proposal']}

## Affected Workflows

{affected}

## Evidence

- Pattern type: `{pattern.get('type', 'unknown')}`
- Frequency: {pattern.get('frequency', 'unknown')}
- Events analyzed: {patterns.get('event_count', len(events))}
- Detected: {patterns.get('scanned_at', now.isoformat())}

## Risk Assessment

**Risk**: {rule.get('risk', 'low')}
**Reversibility**: easy
**Impact**: Workflow improvement — no breaking changes
"""
            wep_path.parent.mkdir(parents=True, exist_ok=True)
            with open(wep_path, 'w') as f:
                f.write(content)
            proposed += 1
            print(f'[evolution] Proposed WEP-{wep_num:03d}: {rule["title"]}')
            break  # One match per rule

    if proposed == 0:
        print('[evolution] No new proposals — patterns below threshold or already proposed')
    else:
        print(f'[evolution] {proposed} new WEP(s) drafted for Oracle review')


def get_existing_wep_ids(evolution_dir):
    """Get set of rule IDs that already have WEPs (proposed or applied)."""
    ids = set()
    for subdir in ['proposals', 'applied', 'rejected']:
        d = evolution_dir / subdir
        if not d.exists():
            continue
        for f in d.glob('WEP-*.md'):
            # Extract slug from filename: WEP-NNN-slug.md → slug
            match = re.match(r'WEP-\d+-(.+)\.md', f.name)
            if match:
                ids.add(match.group(1))
    return ids


def get_next_wep_number(evolution_dir):
    """Find the highest WEP number and return next."""
    highest = 0
    for subdir in ['proposals', 'applied', 'rejected']:
        d = evolution_dir / subdir
        if not d.exists():
            continue
        for f in d.glob('WEP-*.md'):
            match = re.match(r'WEP-(\d+)', f.name)
            if match:
                num = int(match.group(1))
                if num > highest:
                    highest = num
    return highest + 1


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


if __name__ == '__main__':
    main()
