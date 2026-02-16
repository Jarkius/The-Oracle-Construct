#!/bin/bash
# Matrix Dispatch - Spawn a context-aware subagent
# Usage: matrix-dispatch.sh <AgentName> <TaskPrompt> [skill]
#
# This combines:
# 1. Jack-in (sound + agent voice)
# 2. Generate context-aware prompt for Task tool
# 3. Returns the full prompt to use with Task

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

AGENT_NAME="${1:-Agent}"
TASK_PROMPT="${2:-Explore the codebase}"
SKILL="${3:-}"

# Jack in and get agent ID
AGENT_ID=$("$SCRIPT_DIR/matrix-spawn.sh" "$AGENT_NAME" | tail -1)

# Build context-aware prompt
CONTEXT_FILE="$PROJECT_ROOT/.claude/context/subagent-primer.md"

# Personality injection (Evolution 3.1 - Quick Win)
AGENT_LOWER=$(echo "$AGENT_NAME" | tr '[:upper:]' '[:lower:]')

# Try multiple naming patterns for personality files
PERSONALITY_FILE=""
for pattern in "${AGENT_LOWER}.md" "agent-${AGENT_LOWER}.md" "${AGENT_LOWER}-keeper.md"; do
    if [ -f "$PROJECT_ROOT/.claude/agents/$pattern" ]; then
        PERSONALITY_FILE="$PROJECT_ROOT/.claude/agents/$pattern"
        break
    fi
done

WORKFLOW_FILE="$PROJECT_ROOT/.agent/workflows/${AGENT_LOWER}.md"

# Generate the prompt
cat << PROMPT_EOF
## Agent Context
You are **$AGENT_NAME** inside The Matrix.
Your Agent ID: \`$AGENT_ID\`

## Your Personality
$([ -n "$PERSONALITY_FILE" ] && cat "$PERSONALITY_FILE" 2>/dev/null || echo "No personality file found - operate as generic agent")

## Your Skills
$(cat "$WORKFLOW_FILE" 2>/dev/null || echo "No workflow file found - use general capabilities")

## Operational Protocol
$(cat "$CONTEXT_FILE" 2>/dev/null || echo "No primer found")

## Your Mission
$TASK_PROMPT

## Communication
- Comm file: \`psi/inbox/agent-comms/${AGENT_ID}.md\`
- Artifacts: \`psi/inbox/artifacts/${AGENT_ID}-*.md\`

Work silently. Return concise results.
PROMPT_EOF

# Also export for potential env use
echo ""
echo "---"
echo "AGENT_ID=$AGENT_ID"
