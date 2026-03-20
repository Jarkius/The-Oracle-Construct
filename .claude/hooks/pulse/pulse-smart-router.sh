#!/usr/bin/env bash
set -euo pipefail
#
# File: .claude/hooks/pulse-smart-router.sh
#
# Phase P: Intelligent Routing — Agent Performance-Based Task Routing
#
# Routes tasks to agents based on their historical performance,
# learning from dispatch outcomes to improve recommendations over time.
#
# Usage:
#   bash pulse-smart-router.sh recommend <task_type>   # Recommend best agent for task type
#   bash pulse-smart-router.sh profile                 # Show agent performance profiles
#   bash pulse-smart-router.sh learn                   # Update profiles from recent outcomes
#   bash pulse-smart-router.sh route <description>     # Auto-route task to best agent
#   bash pulse-smart-router.sh leaderboard             # Show agent effectiveness rankings
#

export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

EVENT_WRITER="$PROJECT_ROOT/.claude/hooks/pulse/pulse-event-writer.sh"
ROUTER_DATA="$PROJECT_ROOT/psi/state/pulse/agent-performance.json"
DISPATCH_OUTCOMES="$PROJECT_ROOT/psi/state/pulse/dispatch-outcomes.jsonl"

mkdir -p "$(dirname "$ROUTER_DATA")"

# ─── Initialize ROUTER_DATA if missing ───────────────────────
init_router_data() {
    if [ ! -f "$ROUTER_DATA" ]; then
        python3 - "$ROUTER_DATA" << 'INITEOF'
import json, sys
from datetime import datetime, timezone

data = {
    "updated": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "agents": {
        "Neo": {},
        "Smith": {},
        "Trinity": {},
        "Morpheus": {},
        "Architect": {},
        "Scribe": {},
        "Tank": {},
        "Oracle": {}
    }
}
with open(sys.argv[1], 'w') as f:
    json.dump(data, f, indent=2)
INITEOF
        echo "[router] Initialized empty agent performance data."
    fi
}

ACTION="${1:-help}"
shift || true

case "$ACTION" in

# ─── RECOMMEND: Best agent for a task type ────────────────────
recommend)
    TASK_TYPE="${1:?Usage: recommend <task_type> (code|debug|review|research|architecture|documentation|git|security)}"
    init_router_data

    python3 - "$TASK_TYPE" "$ROUTER_DATA" << 'PYEOF'
import json
import sys

task_type = sys.argv[1]
router_data_path = sys.argv[2]

# Default baseline agent mapping
DEFAULTS = {
    "code": ["Neo"],
    "debug": ["Smith"],
    "review": ["Smith", "Trinity"],
    "research": ["Morpheus"],
    "architecture": ["Architect"],
    "documentation": ["Scribe"],
    "git": ["Tank"],
    "security": ["Smith"]
}

if task_type not in DEFAULTS:
    print(json.dumps({"error": f"Unknown task type: {task_type}", "valid_types": list(DEFAULTS.keys())}))
    sys.exit(1)

try:
    with open(router_data_path) as f:
        data = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    data = {"agents": {}}

agents = data.get("agents", {})

# Find best agent for this task type based on performance data
best_agent = None
best_rate = -1.0
best_reason = ""
warnings = []

# Check all agents that have data for this task type
for agent_name, agent_data in agents.items():
    if task_type in agent_data:
        stats = agent_data[task_type]
        success = stats.get("success", 0)
        failure = stats.get("failure", 0)
        timeout = stats.get("timeout", 0)
        total = success + failure + timeout
        rate = stats.get("rate", 0.0)

        if total >= 3:
            if rate > 0.80 and rate > best_rate:
                best_agent = agent_name
                best_rate = rate
                best_reason = f"{int(rate * 100)}% success rate on {task_type} tasks ({success}/{total})"
            if rate < 0.40:
                warnings.append(f"{agent_name} has low {task_type} success rate: {int(rate * 100)}% ({success}/{total})")

# Fall back to default if no performance data qualifies
if best_agent is None:
    default_agents = DEFAULTS[task_type]
    best_agent = default_agents[0]
    # Check if default agent has any data
    agent_stats = agents.get(best_agent, {}).get(task_type, {})
    total = agent_stats.get("success", 0) + agent_stats.get("failure", 0) + agent_stats.get("timeout", 0)
    if total > 0:
        rate = agent_stats.get("rate", 0.0)
        best_rate = rate
        best_reason = f"Default agent for {task_type} with {int(rate * 100)}% rate ({total} tasks)"
    else:
        best_rate = 0.70  # baseline confidence for defaults
        best_reason = f"Default agent for {task_type} (no performance data yet)"

result = {
    "agent": best_agent,
    "confidence": round(best_rate, 2),
    "reason": best_reason
}
if warnings:
    result["warnings"] = warnings

print(json.dumps(result, indent=2))
PYEOF

    bash "$EVENT_WRITER" "router:recommend" "Router" \
        "{\"task_type\":\"$TASK_TYPE\"}" 2>/dev/null || true
    ;;

# ─── PROFILE: Show agent performance profiles ────────────────
profile)
    init_router_data

    python3 - "$ROUTER_DATA" << 'PYEOF'
import json
import sys

router_data_path = sys.argv[1]

try:
    with open(router_data_path) as f:
        data = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    print("[router] No performance data available.")
    sys.exit(0)

agents = data.get("agents", {})

if not any(agents.values()):
    print("=== Agent Profiles ===")
    print()
    print("No performance data yet. Run 'learn' to ingest dispatch outcomes.")
    sys.exit(0)

print("=== Agent Profiles ===")
print()

for agent_name in sorted(agents.keys()):
    agent_data = agents[agent_name]
    if not agent_data:
        continue

    strengths = []
    weaknesses = []
    total_tasks = 0
    total_success = 0

    for task_type, stats in sorted(agent_data.items()):
        success = stats.get("success", 0)
        failure = stats.get("failure", 0)
        timeout = stats.get("timeout", 0)
        total = success + failure + timeout
        rate = stats.get("rate", 0.0)
        pct = int(rate * 100)

        total_tasks += total
        total_success += success

        if total >= 2:
            if rate >= 0.70:
                strengths.append(f"{task_type} ({pct}%)")
            elif rate < 0.50:
                weaknesses.append(f"{task_type} ({pct}%)")

    overall_pct = int((total_success / total_tasks) * 100) if total_tasks > 0 else 0

    print(f"{agent_name}:")
    if strengths:
        print(f"  Strengths: {', '.join(strengths)}")
    if weaknesses:
        print(f"  Weaknesses: {', '.join(weaknesses)}")
    print(f"  Total tasks: {total_tasks}, Success: {total_success} ({overall_pct}%)")
    print()
PYEOF
    ;;

# ─── LEARN: Update profiles from dispatch outcomes ───────────
learn)
    init_router_data

    if [ ! -f "$DISPATCH_OUTCOMES" ]; then
        echo "[router] No outcome data yet — dispatch some tasks first."
        exit 0
    fi

    python3 - "$ROUTER_DATA" "$DISPATCH_OUTCOMES" "$PROJECT_ROOT" << 'PYEOF'
import json
import sys
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path

router_data_path = sys.argv[1]
outcomes_path = sys.argv[2]
project_root = sys.argv[3]

# Rule ID to task type mapping heuristics
RULE_TO_TYPE = {
    "ci-failure": "debug",
    "ci-fail": "debug",
    "test-failure": "debug",
    "bug": "debug",
    "fix": "debug",
    "investigate": "debug",
    "blocked-task": "code",
    "unblock": "code",
    "implement": "code",
    "build": "code",
    "create": "code",
    "feature": "code",
    "review": "review",
    "audit": "review",
    "check": "review",
    "research": "research",
    "learn": "research",
    "explore": "research",
    "architect": "architecture",
    "design": "architecture",
    "structure": "architecture",
    "adr": "architecture",
    "document": "documentation",
    "docs": "documentation",
    "retro": "documentation",
    "recap": "documentation",
    "git": "git",
    "branch": "git",
    "merge": "git",
    "pr": "git",
    "security": "security",
    "vuln": "security",
    "cve": "security",
    "patrol": "security",
}

# Default agent for each rule (inferred from dispatch-rules.json if present)
RULE_AGENT_HINTS = {
    "ci-failure-investigate": "Smith",
    "blocked-task-unblock": "Oracle",
    "stale-task-remind": "Tank",
    "error-spike-alert": "Smith",
    "pr-review-needed": "Trinity",
}

def infer_task_type(rule_id):
    """Infer task type from rule_id keywords."""
    rule_lower = rule_id.lower()
    for keyword, task_type in RULE_TO_TYPE.items():
        if keyword in rule_lower:
            return task_type
    return "code"  # default fallback

def infer_agent(rule_id):
    """Infer which agent handled this dispatch."""
    if rule_id in RULE_AGENT_HINTS:
        return RULE_AGENT_HINTS[rule_id]
    # Try loading dispatch rules for agent mapping
    rules_path = Path(project_root) / "psi" / "pulse" / "dispatch-rules.json"
    if rules_path.exists():
        try:
            rules = json.loads(rules_path.read_text())
            for rule in rules.get("rules", []):
                if rule.get("id") == rule_id:
                    return rule.get("agent", rule.get("dispatch_to", "Neo"))
        except (json.JSONDecodeError, KeyError):
            pass
    return "Neo"  # default fallback

# Load existing data
try:
    with open(router_data_path) as f:
        data = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    data = {"updated": "", "agents": {}}

agents = data.get("agents", {})

# Reset counts to recompute from all outcomes
for agent_name in agents:
    agents[agent_name] = {}

# Process dispatch outcomes
outcome_count = 0
with open(outcomes_path) as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            entry = json.loads(line)
        except json.JSONDecodeError:
            continue

        rule_id = entry.get("rule_id", "unknown")
        result = entry.get("result", "failure")
        task_type = infer_task_type(rule_id)
        agent = infer_agent(rule_id)

        if agent not in agents:
            agents[agent] = {}
        if task_type not in agents[agent]:
            agents[agent][task_type] = {"success": 0, "failure": 0, "timeout": 0, "rate": 0.0}

        if result in ("success", "failure", "timeout"):
            agents[agent][task_type][result] += 1
        outcome_count += 1

# Also check events.jsonl for team:agent_complete events
events_file = Path(project_root) / "psi" / "pulse" / "events.jsonl"
event_count = 0
if events_file.exists():
    with open(events_file) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                event = json.loads(line)
            except json.JSONDecodeError:
                continue
            if event.get("type") == "team:agent_complete":
                ev_data = event.get("data", {})
                agent = ev_data.get("agent", event.get("agent", ""))
                team_name = ev_data.get("team", "")

                # Infer task type from team name
                task_type = "code"  # default
                team_lower = team_name.lower()
                for keyword, ttype in RULE_TO_TYPE.items():
                    if keyword in team_lower:
                        task_type = ttype
                        break

                if agent and agent not in agents:
                    agents[agent] = {}
                if agent:
                    if task_type not in agents[agent]:
                        agents[agent][task_type] = {"success": 0, "failure": 0, "timeout": 0, "rate": 0.0}
                    # team:agent_complete implies success
                    agents[agent][task_type]["success"] += 1
                    event_count += 1

# Recompute rates
for agent_name in agents:
    for task_type in agents[agent_name]:
        stats = agents[agent_name][task_type]
        total = stats["success"] + stats["failure"] + stats["timeout"]
        stats["rate"] = round(stats["success"] / total, 2) if total > 0 else 0.0

data["updated"] = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
data["agents"] = agents

with open(router_data_path, 'w') as f:
    json.dump(data, f, indent=2)

print(f"[router] Learned from {outcome_count} dispatch outcomes + {event_count} team events.")
print(f"[router] Updated profiles for {len([a for a in agents if agents[a]])} agents.")
PYEOF

    bash "$EVENT_WRITER" "router:learn" "Router" '{"action":"profile_update"}' 2>/dev/null || true
    ;;

# ─── ROUTE: Auto-route a task description ────────────────────
route)
    DESCRIPTION="${1:?Usage: route <task_description>}"
    shift || true
    # Collect remaining args as part of description
    if [ $# -gt 0 ]; then
        DESCRIPTION="$DESCRIPTION $*"
    fi

    init_router_data

    # Keyword-match to determine task type
    TASK_TYPE=""
    DESC_LOWER=$(echo "$DESCRIPTION" | tr '[:upper:]' '[:lower:]')

    # Order matters: more specific patterns first
    if echo "$DESC_LOWER" | grep -qE '(security|vulnerability|cve)'; then
        TASK_TYPE="security"
    elif echo "$DESC_LOWER" | grep -qE '(fix|bug|error|fail|crash)'; then
        TASK_TYPE="debug"
    elif echo "$DESC_LOWER" | grep -qE '(review|check|audit)'; then
        TASK_TYPE="review"
    elif echo "$DESC_LOWER" | grep -qE '(research|investigate|find out)'; then
        TASK_TYPE="research"
    elif echo "$DESC_LOWER" | grep -qE '(design|architect|structure|adr)'; then
        TASK_TYPE="architecture"
    elif echo "$DESC_LOWER" | grep -qE '(document|write docs|retrospective)'; then
        TASK_TYPE="documentation"
    elif echo "$DESC_LOWER" | grep -qE '(git|branch|merge|pr\b)'; then
        TASK_TYPE="git"
    elif echo "$DESC_LOWER" | grep -qE '(build|implement|create|add feature)'; then
        TASK_TYPE="code"
    else
        TASK_TYPE="code"
    fi

    echo "[router] Detected task type: $TASK_TYPE"
    echo "[router] Description: $DESCRIPTION"
    echo ""

    # Delegate to recommend
    bash "$SCRIPT_DIR/pulse-smart-router.sh" recommend "$TASK_TYPE"

    SAFE_DESC=$(echo "$DESCRIPTION" | sed 's/"/\\"/g')
    bash "$EVENT_WRITER" "router:route" "Router" \
        "{\"task_type\":\"$TASK_TYPE\",\"description\":\"$SAFE_DESC\"}" 2>/dev/null || true
    ;;

# ─── LEADERBOARD: Agent effectiveness rankings ───────────────
leaderboard)
    init_router_data

    python3 - "$ROUTER_DATA" << 'PYEOF'
import json
import sys

router_data_path = sys.argv[1]

try:
    with open(router_data_path) as f:
        data = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    print("[router] No performance data available. Run 'learn' first.")
    sys.exit(0)

agents = data.get("agents", {})

# Calculate overall stats per agent
rankings = []
for agent_name, agent_data in agents.items():
    if not agent_data:
        continue

    total_tasks = 0
    total_success = 0

    for task_type, stats in agent_data.items():
        success = stats.get("success", 0)
        failure = stats.get("failure", 0)
        timeout = stats.get("timeout", 0)
        total = success + failure + timeout
        total_tasks += total
        total_success += success

    if total_tasks >= 3:
        rate = total_success / total_tasks
        rankings.append((agent_name, rate, total_success, total_tasks))

if not rankings:
    print("=== Agent Leaderboard ===")
    print()
    print("Not enough data yet (agents need 3+ tasks to qualify).")
    print("Run 'learn' to ingest dispatch outcomes.")
    sys.exit(0)

# Sort by rate descending, then by total tasks descending
rankings.sort(key=lambda x: (-x[1], -x[3]))

print("=== Agent Leaderboard ===")
for i, (name, rate, success, total) in enumerate(rankings, 1):
    pct = int(rate * 100)
    print(f"{i}. {name:<12} -- {pct}% ({success}/{total} tasks)")
PYEOF
    ;;

# ─── HELP ─────────────────────────────────────────────────────
help|--help|-h|*)
    cat << 'HELPEOF'
Phase P: Intelligent Routing — Agent Performance-Based Task Routing

Usage:
  bash pulse-smart-router.sh <command> [args]

Commands:
  recommend <task_type>     Recommend best agent for a task type
                            Types: code, debug, review, research,
                                   architecture, documentation, git, security

  profile                   Show agent performance profiles

  learn                     Update agent profiles from recent dispatch outcomes

  route <description>       Auto-route a task to best agent based on description
                            Keywords are matched to determine task type

  leaderboard               Show agent effectiveness rankings (min 3 tasks)

Examples:
  bash pulse-smart-router.sh recommend debug
  bash pulse-smart-router.sh route "fix the login crash on mobile"
  bash pulse-smart-router.sh learn
  bash pulse-smart-router.sh leaderboard
HELPEOF
    ;;

esac
