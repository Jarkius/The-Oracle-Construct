#!/bin/bash
# The Scribe's Quill (Ability 1.0)
# Purpose: Auto-generate a Retrospective Skeleton based on reality (Git).

SLUG="${1:-session}"
YEAR_MONTH=$(date +"%Y-%m")
DAY=$(date +"%d")
TIME_DOT=$(date +"%H.%M")
TARGET_DIR="psi/memory/retrospectives/${YEAR_MONTH}/${DAY}"
TARGET_FILE="${TARGET_DIR}/${TIME_DOT}_${SLUG}.md"

mkdir -p "$TARGET_DIR"

# [VOICE HOOK] Personality
sh psi/matrix/voice.sh "The timeline is secure. Recording memory." "Scribe" &

echo "📜 Scribe: 'Opening new memory at $TARGET_FILE...'"

# Load Template
TEMPLATE_CONTENT=$(cat templates/retrospective.md)

# Replace Placeholders (The Reality)
TODAY=$(date +"%Y-%m-%d")
NOW=$(date +"%H:%M")
# Get last 20 commits nicely formatted
EVENTS=$(git log --oneline -20 --pretty=format:"*   %h - %s (%an)" | sed 's/"/\\"/g')

# Escape newlines for sed
ESCAPED_EVENTS=$(echo "$EVENTS" | sed ':a;N;$!ba;s/\n/\\n/g')

# Create the file by injecting reality into the void
# Note: Using python for robust replacement to avoid sed escaping hell
python3 -c "
import sys
from datetime import datetime

template = r'''$TEMPLATE_CONTENT'''
log = r'''$EVENTS'''
today = '$TODAY'
now = '$NOW'

content = template.replace('[YYYY-MM-DD]', today)
content = content.replace('[HH:MM]', now)
content = content.replace('[Event 1]\n*   [Event 2]\n*   [Event 3]', log)

with open('$TARGET_FILE', 'w') as f:
    f.write(content)
"

echo "📜 Scribe: 'Draft prepared. The ink is wet. Fill the Diary.'"
echo "$TARGET_FILE" # Return path for the agent to open
