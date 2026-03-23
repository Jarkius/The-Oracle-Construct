"""
Task Registry Auto-Sync Helper
Called by pulse-task-sync.sh — handles JSON mutation reliably.

Usage:
  python pulse-task-sync-helper.py complete <tasks_file> <task_id> <timestamp>
  python pulse-task-sync-helper.py archive  <tasks_file> <archive_file> <timestamp>
  python pulse-task-sync-helper.py reconcile <tasks_file> <events_file> <timestamp> <project_root>
"""

import json
import os
import re
import subprocess
import sys

# Ensure UTF-8 on Windows
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')


def load_json(path, default=None):
    try:
        with open(path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return default if default is not None else {}


def save_json(path, data):
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write('\n')


def cmd_complete(tasks_file, task_id, timestamp):
    data = load_json(tasks_file)
    found = False
    for task in data.get('tasks', []):
        if task['id'] == task_id:
            if task['status'] == 'completed':
                print(f'[task-sync] {task_id} already completed')
                return
            task['status'] = 'completed'
            task['updated'] = timestamp
            found = True
            break

    if not found:
        print(f'[task-sync] {task_id} not found')
        sys.exit(1)

    data['lastUpdated'] = timestamp
    save_json(tasks_file, data)
    print(f'[task-sync] {task_id} -> completed')


def cmd_archive(tasks_file, archive_file, timestamp):
    data = load_json(tasks_file)
    completed = [t for t in data.get('tasks', []) if t['status'] == 'completed']
    active = [t for t in data.get('tasks', []) if t['status'] != 'completed']

    if not completed:
        print('[task-sync] No completed tasks to archive')
        return

    # Append to archive file
    archive = load_json(archive_file, [])
    if not isinstance(archive, list):
        archive = []
    archive.extend(completed)
    save_json(archive_file, archive)

    # Update active
    data['tasks'] = active
    data['lastUpdated'] = timestamp
    save_json(tasks_file, data)
    print(f'[task-sync] Archived {len(completed)} task(s) -> {archive_file}')
    print(f'[task-sync] {len(active)} active task(s) remaining')


def cmd_reconcile(tasks_file, events_file, timestamp, project_root):
    data = load_json(tasks_file)

    # Get recent git log
    git_log = ''
    try:
        result = subprocess.run(
            ['git', '-C', project_root, 'log', '--oneline', '-50'],
            capture_output=True, timeout=5
        )
        git_log = result.stdout.decode('utf-8', errors='replace').lower()
    except Exception:
        pass

    # Get recent events
    events_text = ''
    try:
        with open(events_file, 'r') as f:
            lines = f.readlines()
            events_text = ''.join(lines[-50:]).lower()
    except Exception:
        pass

    changes = []

    for task in data.get('tasks', []):
        if task['status'] == 'completed':
            continue

        tid = task['id']
        ctx = task.get('context', '').lower()

        # Signal 1: Context already says "completed via PR"
        if 'completed via pr' in ctx:
            task['status'] = 'completed'
            task['updated'] = timestamp
            changes.append(f'{tid}: context says completed via PR')
            continue

        # Signal 2: PULSE event says task:completed
        if f'"task_id":"{tid}"' in events_text and '"task:completed"' in events_text:
            task['status'] = 'completed'
            task['updated'] = timestamp
            changes.append(f'{tid}: completion event found in PULSE')
            continue

        # Signal 3: Git log mentions task ID in commit message
        if tid.lower() in git_log:
            # Only if the commit message suggests completion
            # e.g. "task-0008: done" or "complete task-0008"
            for line in git_log.split('\n'):
                if tid.lower() in line and any(w in line for w in ['done', 'complete', 'finish', 'close']):
                    task['status'] = 'completed'
                    task['updated'] = timestamp
                    changes.append(f'{tid}: git commit mentions completion')
                    break

    if changes:
        data['lastUpdated'] = timestamp
        save_json(tasks_file, data)
        for c in changes:
            print(f'[task-sync] {c}')
    else:
        print('[task-sync] All tasks consistent - no changes needed')


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print('Usage: pulse-task-sync-helper.py <action> [args...]')
        sys.exit(1)

    action = sys.argv[1]

    if action == 'complete' and len(sys.argv) >= 5:
        cmd_complete(sys.argv[2], sys.argv[3], sys.argv[4])
    elif action == 'archive' and len(sys.argv) >= 5:
        cmd_archive(sys.argv[2], sys.argv[3], sys.argv[4])
    elif action == 'reconcile' and len(sys.argv) >= 6:
        cmd_reconcile(sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5])
    else:
        print(f'Unknown action or missing args: {action}')
        sys.exit(1)
