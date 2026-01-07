#!/bin/bash

# Define Agents and their Voices (Based on available models in .claude/piper-voices)
# Format: Name:Voice
AGENTS=(
  "John:en_US-bryce-medium"
  "Amelia:en_US-amy-medium"
  "Mary:en_US-kristin-medium"
  "Bob:en_GB-alan-medium"
  "Murat:en_US-ryan-medium"
  "Sally:en_US-lessac-medium"
  "Paige:en_US-kathleen-low"
  "Saif:en_US-danny-low"
  "BMad Master:en_US-ryan-high"
)

PERSONALITY_DIR=".claude/personalities"
mkdir -p "$PERSONALITY_DIR"

echo "📢 Starting Roll Call..."
echo "--------------------------------"

for agent_info in "${AGENTS[@]}"; do
  NAME="${agent_info%%:*}"
  VOICE="${agent_info##*:}"
  
  FILE="$PERSONALITY_DIR/$NAME.md"
  
  # Create Personality File if missing
  if [[ ! -f "$FILE" ]]; then
    echo "Creating personality for $NAME..."
    cat > "$FILE" <<EOF
---
name: $NAME
description: Audio Effect Test
piper_voice: $VOICE
---
# $NAME Personality
## AI Instructions
You are $NAME. Speak naturally.
EOF
  fi
  
  # Set Personality
  echo "👉 Activating Agent: $NAME (Voice: $VOICE)"
  .claude/hooks/personality-manager.sh set "$NAME" > /dev/null
  
  # Speak
  # Using a short phrase to keep it quick
  .claude/hooks/play-tts.sh "This is $NAME. Checking into the Matrix."
  
  sleep 1
  echo "--------------------------------"
done

# Restore Winston/Architect
echo "👑 Restoring The Architect..."
.claude/hooks/personality-manager.sh set Winston > /dev/null
.claude/hooks/play-tts.sh "Roll call complete. The system is populated."
