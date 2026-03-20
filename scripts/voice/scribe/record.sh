#!/bin/bash
# ============================================================
# record.sh - Retrospective Scaffolding Script
# ============================================================
#
# Creates a retrospective template with auto-injected git context.
# Called by /rrr workflow to reduce manual overhead.
#
# Usage: ./record.sh "slug" [session_start_commit]
# Example: ./record.sh "voice_system_fix"
#          ./record.sh "voice_system_fix" "a30db99"
#
# Output: Creates psi/memory/retrospectives/YYYY-MM/DD/HH.MM_slug.md
#
# ============================================================

set -o pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

# Arguments
SLUG="${1:-session}"
START_COMMIT="${2:-}"

# Validate slug (alphanumeric and underscores only)
SLUG=$(echo "$SLUG" | tr ' ' '_' | tr '-' '_' | tr '[:upper:]' '[:lower:]')

# Generate paths
YEAR_MONTH=$(date '+%Y-%m')
DAY=$(date '+%d')
TIME=$(date '+%H.%M')
DATE_FULL=$(date '+%Y-%m-%d')
TIME_FULL=$(date '+%H:%M')

RETRO_DIR="psi/memory/retrospectives/$YEAR_MONTH/$DAY"
RETRO_FILE="$RETRO_DIR/${TIME}_${SLUG}.md"

# Create directory
mkdir -p "$RETRO_DIR"

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}   Scribe Recording: $SLUG${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Gather git context
echo -e "${BLUE}Gathering git context...${NC}"

if [ -n "$START_COMMIT" ]; then
    COMMITS=$(git log --oneline "$START_COMMIT"..HEAD 2>/dev/null | head -10)
    COMMIT_COUNT=$(git log --oneline "$START_COMMIT"..HEAD 2>/dev/null | wc -l | tr -d ' ')
else
    COMMITS=$(git log --oneline -10 2>/dev/null)
    COMMIT_COUNT="10+"
fi

DIFF_STATS=$(git diff --stat HEAD~5..HEAD 2>/dev/null | tail -3)
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null)

# Get focus from previous session
FOCUS=$(./psi/active/get_focus.sh 2>/dev/null | grep -A1 "## From Latest" | tail -1 || echo "No previous focus")

# Generate template
echo -e "${BLUE}Generating template...${NC}"

cat > "$RETRO_FILE" << EOF
# Session Retrospective: ${SLUG//_/ }

**Date**: $DATE_FULL
**Duration**: ~X minutes
**Focus**: [FILL: What was the main goal?]

## Summary

[FILL: 2-3 sentence executive summary of what happened]

## What We Built

### [Category]
- [FILL: List items created/modified]

## Key Decisions

| Decision | Rationale |
|----------|-----------|
| [FILL] | [FILL] |

## AI Diary (Required - 150+ words)

[FILL: Genuine reflection using these phrases:]
- "I assumed X but learned Y..."
- "I was confused about X until..."
- "I expected X but got Y because..."

## Honest Feedback

### Delighted
- [FILL: What worked well]

### Frustrated
- [FILL: What caused friction]

## Communication Dynamics

- **Flow**: [Smooth / Interrupted / Back-and-forth]
- **Tone**: [Collaborative / Directive / Exploratory]
- **Blockers**: [FILL: What slowed us down]
- **Breakthroughs**: [FILL: Moments of clarity]

## Co-Creation Map

| Contributor | What |
|-------------|------|
| **Human** | [FILL: Direction, decisions, approvals] |
| **AI** | [FILL: Research, synthesis, implementation] |
| **Together** | [FILL: What emerged from dialogue] |

## Lessons Learned

- **Pattern**: [FILL: Insight that can be reused]

## Timeline

| Time | Event |
|------|-------|
| Start | [FILL] |
| +Xm | [FILL] |

## Commits This Session

\`\`\`
$COMMITS
\`\`\`

**Stats** ($COMMIT_COUNT commits):
\`\`\`
$DIFF_STATS
\`\`\`

## Next Steps

- [ ] [FILL: Action item]

## Session Quality

| Metric | Value |
|--------|-------|
| Commits | $COMMIT_COUNT |
| Branch | $CURRENT_BRANCH |
| [Add more] | [FILL] |

---

*"Everything that has a beginning has an end."*

*Scribe, $DATE_FULL*
EOF

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}   Retrospective Created${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo -e "File: ${YELLOW}$RETRO_FILE${NC}"
echo ""
echo "Sections to fill:"
echo "  - Summary"
echo "  - What We Built"
echo "  - Key Decisions"
echo "  - AI Diary (150+ words)"
echo "  - Honest Feedback"
echo "  - Communication Dynamics"
echo "  - Co-Creation Map"
echo "  - Next Steps"
echo ""
echo -e "Git context auto-injected: ${GREEN}$COMMIT_COUNT commits${NC}"
echo ""

# Return path for workflow
echo "$RETRO_FILE"
