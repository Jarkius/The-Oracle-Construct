#!/usr/bin/env bash
set -euo pipefail
#
# File: .claude/hooks/pulse-skill-discovery.sh
#
# Phase L: Skill Auto-Discovery
#
# Scans skill directories for new/unregistered skills,
# validates their structure, and maintains a skill registry.
#
# Usage:
#   bash pulse-skill-discovery.sh scan        # Discover new skills
#   bash pulse-skill-discovery.sh validate    # Validate all skills
#   bash pulse-skill-discovery.sh registry    # Show skill registry
#   bash pulse-skill-discovery.sh stats       # Skill usage stats
#

export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

SKILL_DIRS=(
    "$PROJECT_ROOT/.claude/commands"
    "$PROJECT_ROOT/.agent/workflows"
)
REGISTRY_FILE="$PROJECT_ROOT/psi/state/pulse/skill-registry.json"
EVENT_WRITER="$PROJECT_ROOT/.claude/hooks/pulse/pulse-event-writer.sh"

mkdir -p "$(dirname "$REGISTRY_FILE")"

ACTION="${1:-help}"
shift || true

case "$ACTION" in

# ─── SCAN: Discover new skills ───────────────────────────────
scan)
    python3 << 'PYEOF'
import json
import sys
import os
from pathlib import Path
from datetime import datetime, timezone

root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path('.')
registry_file = root / 'psi' / 'pulse' / 'skill-registry.json'

skill_dirs = [
    root / '.claude' / 'commands',
    root / '.agent' / 'workflows',
]

# Load existing registry
registry = {'skills': {}, 'last_scan': None}
if registry_file.exists():
    try:
        registry = json.load(open(registry_file))
    except:
        pass

existing_ids = set(registry.get('skills', {}).keys())
discovered = []

for skill_dir in skill_dirs:
    if not skill_dir.exists():
        continue

    # Scan for .md files (skill definitions)
    for md_file in sorted(skill_dir.rglob('*.md')):
        rel_path = str(md_file.relative_to(root))
        skill_id = md_file.stem

        # Handle namespaced skills (e.g., learn/concept.md → learn:concept)
        if md_file.parent != skill_dir:
            namespace = md_file.parent.name
            skill_id = f"{namespace}:{skill_id}"

        # Parse frontmatter
        content = md_file.read_text()
        frontmatter = {}
        if content.startswith('---'):
            end = content.find('---', 3)
            if end > 0:
                fm_text = content[3:end].strip()
                for line in fm_text.split('\n'):
                    if ':' in line:
                        key, val = line.split(':', 1)
                        frontmatter[key.strip()] = val.strip().strip('"').strip("'")

        # Extract description from first paragraph after frontmatter
        body = content
        if content.startswith('---'):
            end = content.find('---', 3)
            if end > 0:
                body = content[end+3:].strip()

        first_line = ''
        for line in body.split('\n'):
            line = line.strip()
            if line and not line.startswith('#') and not line.startswith('>'):
                first_line = line[:120]
                break

        skill_info = {
            'id': skill_id,
            'path': rel_path,
            'name': frontmatter.get('name', skill_id),
            'description': frontmatter.get('description', first_line),
            'agent': frontmatter.get('agent', 'any'),
            'user_invocable': frontmatter.get('user-invocable', frontmatter.get('user_invocable', 'true')).lower() == 'true',
            'has_frontmatter': bool(frontmatter),
            'size_bytes': md_file.stat().st_size,
            'modified': datetime.fromtimestamp(md_file.stat().st_mtime, timezone.utc).isoformat(),
        }

        # Check if new
        if skill_id not in existing_ids:
            skill_info['discovered_at'] = datetime.now(timezone.utc).isoformat()
            discovered.append(skill_info)

        registry['skills'][skill_id] = skill_info

    # Scan for script companions
    for sh_file in sorted(skill_dir.rglob('*.sh')):
        skill_id = sh_file.stem
        if skill_id in registry['skills']:
            registry['skills'][skill_id]['has_script'] = True
            registry['skills'][skill_id]['script_path'] = str(sh_file.relative_to(root))

registry['last_scan'] = datetime.now(timezone.utc).isoformat()
registry['total'] = len(registry['skills'])

with open(registry_file, 'w') as f:
    json.dump(registry, f, indent=2)

print(f"[skills] Scanned {registry['total']} skill(s)")
if discovered:
    print(f"  NEW ({len(discovered)}):")
    for s in discovered:
        print(f"    /{s['id']} — {s.get('description', 'No description')[:60]}")
else:
    print("  No new skills discovered")

# Validate
issues = []
for sid, s in registry['skills'].items():
    if not s.get('has_frontmatter'):
        issues.append(f"  [warn] /{sid}: missing frontmatter")
    if not s.get('description'):
        issues.append(f"  [warn] /{sid}: missing description")
    if s.get('size_bytes', 0) < 50:
        issues.append(f"  [warn] /{sid}: very small ({s['size_bytes']} bytes)")

if issues:
    print(f"\n  Quality issues ({len(issues)}):")
    for i in issues[:10]:
        print(i)
PYEOF
    ;;

# ─── VALIDATE: Check skill quality ──────────────────────────
validate)
    if [ ! -f "$REGISTRY_FILE" ]; then
        bash "$0" scan "$@"
    fi

    python3 -c "
import json
data = json.load(open('$REGISTRY_FILE'))
skills = data.get('skills', {})
total = len(skills)
valid = 0
issues = []

for sid, s in skills.items():
    ok = True
    if not s.get('has_frontmatter'):
        issues.append(f'  /{sid}: missing frontmatter')
        ok = False
    if not s.get('description'):
        issues.append(f'  /{sid}: missing description')
        ok = False
    if ok:
        valid += 1

print(f'[skills] Validation: {valid}/{total} skills pass quality check')
if issues:
    for i in issues[:15]:
        print(i)
" 2>/dev/null
    ;;

# ─── REGISTRY: Show skill registry ──────────────────────────
registry)
    if [ ! -f "$REGISTRY_FILE" ]; then
        bash "$0" scan "$@"
    fi

    python3 -c "
import json
data = json.load(open('$REGISTRY_FILE'))
skills = data.get('skills', {})
print(f'=== Skill Registry ({len(skills)} skills) ===')
print(f'Last scan: {data.get(\"last_scan\", \"never\")}')
print()

# Group by namespace
namespaces = {}
for sid, s in sorted(skills.items()):
    ns = sid.split(':')[0] if ':' in sid else 'core'
    namespaces.setdefault(ns, []).append(s)

for ns, ns_skills in sorted(namespaces.items()):
    print(f'  [{ns}] ({len(ns_skills)} skills)')
    for s in ns_skills:
        invocable = 'cmd' if s.get('user_invocable') else 'int'
        print(f'    /{s[\"id\"]:20s} [{invocable}] {s.get(\"description\", \"\")[:50]}')
" 2>/dev/null
    ;;

# ─── STATS: Usage statistics ────────────────────────────────
stats)
    if [ ! -f "$REGISTRY_FILE" ]; then
        bash "$0" scan "$@"
    fi

    python3 -c "
import json
data = json.load(open('$REGISTRY_FILE'))
skills = data.get('skills', {})
total = len(skills)
with_fm = sum(1 for s in skills.values() if s.get('has_frontmatter'))
with_scripts = sum(1 for s in skills.values() if s.get('has_script'))
invocable = sum(1 for s in skills.values() if s.get('user_invocable'))

print(f'=== Skill Stats ===')
print(f'  Total skills: {total}')
print(f'  With frontmatter: {with_fm}/{total}')
print(f'  With scripts: {with_scripts}/{total}')
print(f'  User-invocable: {invocable}/{total}')
print(f'  Internal-only: {total - invocable}/{total}')

# Size distribution
sizes = [s.get('size_bytes', 0) for s in skills.values()]
if sizes:
    avg = sum(sizes) / len(sizes)
    print(f'  Avg size: {avg:.0f} bytes')
    print(f'  Total: {sum(sizes)/1024:.1f} KB')
" 2>/dev/null
    ;;

# ─── HELP ────────────────────────────────────────────────────
*)
    echo "Skill Auto-Discovery — Phase L"
    echo ""
    echo "Usage:"
    echo "  scan        Discover new skills"
    echo "  validate    Check skill quality"
    echo "  registry    Show skill registry"
    echo "  stats       Skill usage statistics"
    ;;

esac
