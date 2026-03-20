#!/usr/bin/env bash
set -euo pipefail
#
# File: .claude/hooks/pulse-team-orchestrator.sh
#
# Phase B: Team Orchestrator (ADR-017)
#
# Creates teams, manages shared state, and generates spawn prompts
# with messaging instructions so agents can coordinate.
#
# Usage:
#   bash pulse-team-orchestrator.sh create <team_name> <agent1,agent2,...> <mission>
#   bash pulse-team-orchestrator.sh spawn-prompt <team_id> <agent_name>
#   bash pulse-team-orchestrator.sh status <team_id>
#   bash pulse-team-orchestrator.sh collect <team_id>
#   bash pulse-team-orchestrator.sh dissolve <team_id>
#

export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

TEAMS_DIR="$PROJECT_ROOT/psi/swarm/teams"
MESSAGES_DIR="$PROJECT_ROOT/psi/swarm/messages"
CONTEXT_LOADER="$PROJECT_ROOT/.claude/hooks/pulse/pulse-context-loader.sh"
MESSENGER="$PROJECT_ROOT/.claude/hooks/pulse/pulse-agent-messenger.sh"
EVENT_WRITER="$PROJECT_ROOT/.claude/hooks/pulse/pulse-event-writer.sh"

mkdir -p "$TEAMS_DIR" "$MESSAGES_DIR"

ACTION="${1:-help}"
shift || true

case "$ACTION" in

# ─── CREATE: Initialize a new team ───────────────────────────
create)
    TEAM_NAME="${1:?Usage: create <team_name> <agent1,agent2,...> <mission>}"
    AGENTS_CSV="${2:?Missing agents (comma-separated)}"
    MISSION="${3:?Missing mission description}"

    # Generate team ID
    TEAM_ID="team-$(date +%Y%m%d-%H%M%S)-$(echo "$TEAM_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')"
    TEAM_FILE="$TEAMS_DIR/${TEAM_ID}.json"

    # Build agents array
    IFS=',' read -ra AGENT_ARRAY <<< "$AGENTS_CSV"

    python3 -c "
import json
from datetime import datetime, timezone

agents = []
for name in '${AGENTS_CSV}'.split(','):
    name = name.strip()
    agents.append({
        'name': name,
        'status': 'pending',
        'last_report': None,
        'last_summary': None,
        'result': None
    })

team = {
    'id': '$TEAM_ID',
    'name': '$TEAM_NAME',
    'mission': '''$(echo "$MISSION" | sed "s/'/'\\''/g")''',
    'status': 'active',
    'created': datetime.now(timezone.utc).isoformat(),
    'agents': agents,
    'lead': 'Oracle',
    'message_channel': 'psi/swarm/messages/${TEAM_ID}.jsonl'
}

with open('$TEAM_FILE', 'w') as f:
    json.dump(team, f, indent=2)

print(f'[team] Created {team[\"id\"]} with {len(agents)} agents')
for a in agents:
    print(f'  - {a[\"name\"]}: pending')
"

    # Initialize message channel
    touch "$MESSAGES_DIR/${TEAM_ID}.jsonl"

    # Log team creation event
    bash "$EVENT_WRITER" "team:created" "Oracle" \
        "{\"team\":\"$TEAM_ID\",\"agents\":\"$AGENTS_CSV\",\"mission\":\"$(echo "$MISSION" | sed 's/"/\\"/g' | head -c 100)\"}" \
        2>/dev/null || true

    echo ""
    echo "Team ID: $TEAM_ID"
    echo "Channel: psi/swarm/messages/${TEAM_ID}.jsonl"
    ;;

# ─── SPAWN-PROMPT: Generate a context-rich prompt for an agent ─
spawn-prompt)
    TEAM_ID="${1:?Usage: spawn-prompt <team_id> <agent_name>}"
    AGENT_NAME="${2:?Missing agent_name}"

    TEAM_FILE="$TEAMS_DIR/${TEAM_ID}.json"
    if [ ! -f "$TEAM_FILE" ]; then
        echo "Error: Team $TEAM_ID not found" >&2
        exit 1
    fi

    # Extract team info
    MISSION=$(python3 -c "import json; t=json.load(open('$TEAM_FILE')); print(t['mission'])" 2>/dev/null)
    TEAMMATES=$(python3 -c "
import json
t = json.load(open('$TEAM_FILE'))
for a in t['agents']:
    if a['name'] != '$AGENT_NAME':
        print(f\"- {a['name']} ({a['status']})\")
" 2>/dev/null)

    # Load base context (personality, memory, tasks, events)
    BASE_CONTEXT=""
    if [ -f "$CONTEXT_LOADER" ] && [ -x "$CONTEXT_LOADER" ]; then
        BASE_CONTEXT=$(bash "$CONTEXT_LOADER" "$AGENT_NAME" "$MISSION" 2>/dev/null || echo "")
    fi

    # Generate spawn prompt with team awareness
    cat << PROMPT_EOF
$BASE_CONTEXT

## Team Coordination — $TEAM_ID

You are part of a team. Your teammates:
$TEAMMATES

### Mission
$MISSION

### How to Communicate

You have access to a message bus. Use these commands via Bash:

**Send a message to a teammate:**
\`\`\`bash
bash .claude/hooks/pulse-agent-messenger.sh send "$TEAM_ID" "$AGENT_NAME" "<teammate_or_all>" "<message>"
\`\`\`

**Read messages sent to you:**
\`\`\`bash
bash .claude/hooks/pulse-agent-messenger.sh read "$TEAM_ID" "$AGENT_NAME" --unread
\`\`\`

**Report your progress:**
\`\`\`bash
bash .claude/hooks/pulse-agent-messenger.sh report "$TEAM_ID" "$AGENT_NAME" "working" "What you're doing"
\`\`\`

**Report a blocker (escalates to Oracle):**
\`\`\`bash
bash .claude/hooks/pulse-agent-messenger.sh block "$TEAM_ID" "$AGENT_NAME" "What's blocking you"
\`\`\`

**Report completion:**
\`\`\`bash
bash .claude/hooks/pulse-agent-messenger.sh complete "$TEAM_ID" "$AGENT_NAME" "Summary of what you accomplished"
\`\`\`

### Rules
1. **Report progress** before doing heavy work (so teammates know your status)
2. **Check messages** periodically — teammates may send you findings
3. **Report blockers immediately** — don't spin on something alone
4. **Complete when done** — this lets the orchestrator know you're finished
5. Work within your agent role. If you need another agent's skills, message them.
PROMPT_EOF
    ;;

# ─── STATUS: Show team progress ──────────────────────────────
status)
    TEAM_ID="${1:?Usage: status <team_id>}"
    TEAM_FILE="$TEAMS_DIR/${TEAM_ID}.json"

    if [ ! -f "$TEAM_FILE" ]; then
        echo "[team] Team $TEAM_ID not found"
        exit 1
    fi

    python3 -c "
import json

team = json.load(open('$TEAM_FILE'))
print(f\"Team: {team['name']} ({team['id']})\")
print(f\"Status: {team['status']}\")
print(f\"Mission: {team['mission'][:100]}\")
print(f\"Lead: {team.get('lead', 'Oracle')}\")
print()

complete = sum(1 for a in team['agents'] if a['status'] == 'complete')
total = len(team['agents'])
print(f'Progress: {complete}/{total} agents complete')
print()

for a in team['agents']:
    status = a['status']
    icon = {'pending': '⏳', 'working': '🔨', 'blocked': '🚫', 'complete': '✅', 'reviewing': '👀'}.get(status, '❓')
    summary = a.get('last_summary', '') or ''
    print(f'  {icon} {a[\"name\"]}: {status}')
    if summary:
        print(f'     └─ {summary[:80]}')
"

    # Show message activity
    echo ""
    bash "$MESSENGER" status "$TEAM_ID" 2>/dev/null || true
    ;;

# ─── COLLECT: Gather all agent results ───────────────────────
collect)
    TEAM_ID="${1:?Usage: collect <team_id>}"
    TEAM_FILE="$TEAMS_DIR/${TEAM_ID}.json"

    if [ ! -f "$TEAM_FILE" ]; then
        echo "[team] Team $TEAM_ID not found"
        exit 1
    fi

    echo "## Team Results: $TEAM_ID"
    echo ""

    python3 -c "
import json

team = json.load(open('$TEAM_FILE'))
print(f'**Mission**: {team[\"mission\"]}')
print(f'**Status**: {team[\"status\"]}')
print()

for a in team['agents']:
    print(f'### {a[\"name\"]}')
    print(f'**Status**: {a[\"status\"]}')
    if a.get('result'):
        print(f'**Result**: {a[\"result\"]}')
    elif a.get('last_summary'):
        print(f'**Last Report**: {a[\"last_summary\"]}')
    else:
        print('*No result reported*')
    print()
"

    # Include message highlights
    CHANNEL="$MESSAGES_DIR/${TEAM_ID}.jsonl"
    if [ -f "$CHANNEL" ]; then
        TOTAL=$(wc -l < "$CHANNEL")
        echo "### Communication Log"
        echo "$TOTAL total messages exchanged."
        echo ""

        # Show completion and blocker messages
        grep -E '"type":"(complete|blocked)"' "$CHANNEL" 2>/dev/null | while IFS= read -r line; do
            python3 -c "
import json
m = json.loads('$(echo "$line" | sed "s/'/'\\''/g")')
icon = '✅' if m['type'] == 'complete' else '🚫'
print(f'{icon} **{m[\"from\"]}**: {m[\"content\"][:120]}')
" 2>/dev/null || true
        done
    fi
    ;;

# ─── DISSOLVE: Archive and close a team ──────────────────────
dissolve)
    TEAM_ID="${1:?Usage: dissolve <team_id>}"
    TEAM_FILE="$TEAMS_DIR/${TEAM_ID}.json"

    if [ ! -f "$TEAM_FILE" ]; then
        echo "[team] Team $TEAM_ID not found"
        exit 1
    fi

    # Update status
    python3 -c "
import json
from datetime import datetime, timezone
team = json.load(open('$TEAM_FILE'))
team['status'] = 'dissolved'
team['dissolved'] = datetime.now(timezone.utc).isoformat()
with open('$TEAM_FILE', 'w') as f:
    json.dump(team, f, indent=2)
print(f'[team] {team[\"id\"]} dissolved')
"

    bash "$EVENT_WRITER" "team:dissolved" "Oracle" \
        "{\"team\":\"$TEAM_ID\"}" 2>/dev/null || true
    ;;

# ─── HELP ─────────────────────────────────────────────────────
*)
    echo "Team Orchestrator — Phase B (ADR-017)"
    echo ""
    echo "Usage:"
    echo "  create <name> <agents> <mission>    Create a team"
    echo "  spawn-prompt <team_id> <agent>       Generate agent spawn prompt"
    echo "  status <team_id>                     Show team progress"
    echo "  collect <team_id>                    Gather all results"
    echo "  dissolve <team_id>                   Archive and close"
    ;;

esac
