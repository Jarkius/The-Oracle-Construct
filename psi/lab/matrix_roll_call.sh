#!/bin/bash

AGENTS=(
  "Neo:en_US-ryan-high"
  "Smith:en_GB-alan-medium"
  "Tank:en_US-danny-low"
)

echo "🟢 Wake Up, Neo..."
echo "--------------------------------"

for agent_info in "${AGENTS[@]}"; do
  NAME="${agent_info%%:*}"
  VOICE="${agent_info##*:}"
  
  echo "👉 Agent: $NAME (Voice: $VOICE)"
  .claude/hooks/personality-manager.sh set "$NAME" > /dev/null
  
  if [[ "$NAME" == "Neo" ]]; then
      TEXT="I know Kung Fu."
  elif [[ "$NAME" == "Smith" ]]; then
      TEXT="Mr. Anderson. We miss you."
  else
      TEXT="Operator here. Loading program."
  fi
  
  .claude/hooks/play-tts.sh "$TEXT"
  sleep 1
done

echo "--------------------------------"
echo "System restore complete."
