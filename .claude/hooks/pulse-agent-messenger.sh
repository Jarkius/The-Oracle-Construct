#!/usr/bin/env bash
set -euo pipefail
#
# File: .claude/hooks/pulse-agent-messenger.sh
#
# Phase B: Agent Message Bus (ADR-017)
#
# File-based messaging for agent coordination within Claude Code sessions.
# Agents spawned as Task subagents can't use WebSockets, so they communicate
# via shared JSONL files in psi/swarm/messages/.
#
# Usage:
#   bash pulse-agent-messenger.sh send <team_id> <from_agent> <to_agent|all> <message>
#   bash pulse-agent-messenger.sh read <team_id> <agent_name> [--unread]
#   bash pulse-agent-messenger.sh status <team_id>
#   bash pulse-agent-messenger.sh report <team_id> <agent_name> <status> <summary>
#   bash pulse-agent-messenger.sh block <team_id> <agent_name> <blocker_description>
#   bash pulse-agent-messenger.sh complete <team_id> <agent_name> <result_summary>
#

export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

MESSAGES_DIR="$PROJECT_ROOT/psi/swarm/messages"
TEAMS_DIR="$PROJECT_ROOT/psi/swarm/teams"
EVENT_WRITER="$PROJECT_ROOT/.claude/hooks/pulse-event-writer.sh"

mkdir -p "$MESSAGES_DIR" "$TEAMS_DIR"

ACTION="${1:-help}"
shift || true

case "$ACTION" in

# ─── SEND: Post a message to the team channel ────────────────
send)
    TEAM_ID="${1:?Usage: send <team_id> <from> <to|all> <message>}"
    FROM="${2:?Missing from_agent}"
    TO="${3:?Missing to_agent (or 'all')}"
    MESSAGE="${4:?Missing message}"

    CHANNEL="$MESSAGES_DIR/${TEAM_ID}.jsonl"
    TIMESTAMP=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

    printf '{"ts":"%s","from":"%s","to":"%s","type":"message","content":"%s"}\n' \
        "$TIMESTAMP" "$FROM" "$TO" "$(echo "$MESSAGE" | sed 's/"/\\"/g')" \
        >> "$CHANNEL"

    echo "[msg] $FROM → $TO: sent"
    ;;

# ─── READ: Get messages for an agent ─────────────────────────
read)
    TEAM_ID="${1:?Usage: read <team_id> <agent_name> [--unread]}"
    AGENT="${2:?Missing agent_name}"
    UNREAD_ONLY="${3:-}"

    CHANNEL="$MESSAGES_DIR/${TEAM_ID}.jsonl"
    READ_MARKER="$MESSAGES_DIR/${TEAM_ID}.${AGENT}.lastread"

    if [ ! -f "$CHANNEL" ]; then
        echo "[msg] No messages for team $TEAM_ID"
        exit 0
    fi

    if [ "$UNREAD_ONLY" = "--unread" ] && [ -f "$READ_MARKER" ]; then
        LAST_READ=$(cat "$READ_MARKER")
        # Show messages after the marker line
        TOTAL=$(wc -l < "$CHANNEL")
        if [ "$LAST_READ" -ge "$TOTAL" ]; then
            echo "[msg] No unread messages for $AGENT"
            exit 0
        fi
        tail -n "+$((LAST_READ + 1))" "$CHANNEL" | \
            grep -E "\"to\":\"$AGENT\"|\"to\":\"all\"" || echo "[msg] No unread messages for $AGENT"
    else
        # Show all messages for this agent
        grep -E "\"to\":\"$AGENT\"|\"to\":\"all\"" "$CHANNEL" || echo "[msg] No messages for $AGENT"
    fi

    # Update read marker
    wc -l < "$CHANNEL" > "$READ_MARKER"
    ;;

# ─── STATUS: Show team message activity ──────────────────────
status)
    TEAM_ID="${1:?Usage: status <team_id>}"
    CHANNEL="$MESSAGES_DIR/${TEAM_ID}.jsonl"
    TEAM_FILE="$TEAMS_DIR/${TEAM_ID}.json"

    if [ ! -f "$CHANNEL" ]; then
        echo "[msg] No messages for team $TEAM_ID"
    else
        TOTAL=$(wc -l < "$CHANNEL")
        echo "[msg] Team $TEAM_ID: $TOTAL messages"

        # Show per-agent message counts
        python3 -c "
import json, sys
from collections import Counter
msgs = []
for line in open('$CHANNEL'):
    line = line.strip()
    if not line: continue
    try: msgs.append(json.loads(line))
    except: continue

senders = Counter(m.get('from','?') for m in msgs)
types = Counter(m.get('type','?') for m in msgs)

for agent, count in senders.most_common():
    print(f'  {agent}: {count} message(s)')

reports = [m for m in msgs if m.get('type') in ('report', 'complete', 'blocked')]
if reports:
    print('')
    print('  Status reports:')
    for r in reports[-5:]:
        print(f'    [{r[\"type\"]}] {r[\"from\"]}: {r.get(\"content\",\"?\")[:80]}')
" 2>/dev/null
    fi

    # Show team state if exists
    if [ -f "$TEAM_FILE" ]; then
        echo ""
        echo "  Team state:"
        python3 -c "
import json
team = json.load(open('$TEAM_FILE'))
for agent in team.get('agents', []):
    status = agent.get('status', 'unknown')
    print(f'    {agent[\"name\"]}: {status}')
" 2>/dev/null
    fi
    ;;

# ─── REPORT: Agent reports progress ──────────────────────────
report)
    TEAM_ID="${1:?Usage: report <team_id> <agent_name> <status> <summary>}"
    AGENT="${2:?Missing agent_name}"
    STATUS="${3:?Missing status (working|blocked|reviewing|done)}"
    SUMMARY="${4:?Missing summary}"

    CHANNEL="$MESSAGES_DIR/${TEAM_ID}.jsonl"
    TEAM_FILE="$TEAMS_DIR/${TEAM_ID}.json"
    TIMESTAMP=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

    # Write status message
    printf '{"ts":"%s","from":"%s","to":"all","type":"report","status":"%s","content":"%s"}\n' \
        "$TIMESTAMP" "$AGENT" "$STATUS" "$(echo "$SUMMARY" | sed 's/"/\\"/g')" \
        >> "$CHANNEL"

    # Update team state if exists
    if [ -f "$TEAM_FILE" ]; then
        python3 -c "
import json
team = json.load(open('$TEAM_FILE'))
for agent in team.get('agents', []):
    if agent['name'] == '$AGENT':
        agent['status'] = '$STATUS'
        agent['last_report'] = '$TIMESTAMP'
        agent['last_summary'] = '''$SUMMARY'''[:200]
with open('$TEAM_FILE', 'w') as f:
    json.dump(team, f, indent=2)
" 2>/dev/null
    fi

    echo "[msg] $AGENT reported: $STATUS"
    ;;

# ─── BLOCK: Agent reports a blocker ──────────────────────────
block)
    TEAM_ID="${1:?Usage: block <team_id> <agent_name> <blocker>}"
    AGENT="${2:?Missing agent_name}"
    BLOCKER="${3:?Missing blocker description}"

    CHANNEL="$MESSAGES_DIR/${TEAM_ID}.jsonl"
    TIMESTAMP=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

    printf '{"ts":"%s","from":"%s","to":"all","type":"blocked","content":"%s"}\n' \
        "$TIMESTAMP" "$AGENT" "$(echo "$BLOCKER" | sed 's/"/\\"/g')" \
        >> "$CHANNEL"

    # Log event for dispatcher to pick up
    bash "$EVENT_WRITER" "team:blocked" "$AGENT" \
        "{\"team\":\"$TEAM_ID\",\"agent\":\"$AGENT\",\"blocker\":\"$(echo "$BLOCKER" | sed 's/"/\\"/g')\"}" \
        2>/dev/null || true

    echo "[msg] $AGENT BLOCKED: $BLOCKER"
    ;;

# ─── COMPLETE: Agent reports task completion ──────────────────
complete)
    TEAM_ID="${1:?Usage: complete <team_id> <agent_name> <result>}"
    AGENT="${2:?Missing agent_name}"
    RESULT="${3:?Missing result summary}"

    CHANNEL="$MESSAGES_DIR/${TEAM_ID}.jsonl"
    TEAM_FILE="$TEAMS_DIR/${TEAM_ID}.json"
    TIMESTAMP=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

    printf '{"ts":"%s","from":"%s","to":"all","type":"complete","content":"%s"}\n' \
        "$TIMESTAMP" "$AGENT" "$(echo "$RESULT" | sed 's/"/\\"/g')" \
        >> "$CHANNEL"

    # Update team state
    if [ -f "$TEAM_FILE" ]; then
        python3 -c "
import json
team = json.load(open('$TEAM_FILE'))
for agent in team.get('agents', []):
    if agent['name'] == '$AGENT':
        agent['status'] = 'complete'
        agent['last_report'] = '$TIMESTAMP'
        agent['result'] = '''$RESULT'''[:500]

# Check if all agents complete
all_done = all(a.get('status') == 'complete' for a in team.get('agents', []))
team['status'] = 'complete' if all_done else team.get('status', 'active')

with open('$TEAM_FILE', 'w') as f:
    json.dump(team, f, indent=2)
" 2>/dev/null
    fi

    bash "$EVENT_WRITER" "team:agent_complete" "$AGENT" \
        "{\"team\":\"$TEAM_ID\",\"agent\":\"$AGENT\"}" 2>/dev/null || true

    echo "[msg] $AGENT COMPLETE: $RESULT"
    ;;

# ─── HELP ─────────────────────────────────────────────────────
*)
    echo "Agent Messenger — Phase B (ADR-017)"
    echo ""
    echo "Usage:"
    echo "  send <team_id> <from> <to|all> <message>   Send a message"
    echo "  read <team_id> <agent> [--unread]           Read messages"
    echo "  status <team_id>                            Team activity"
    echo "  report <team_id> <agent> <status> <summary> Report progress"
    echo "  block <team_id> <agent> <blocker>           Report blocker"
    echo "  complete <team_id> <agent> <result>         Report completion"
    ;;

esac
