#!/bin/bash
# AgentVibes System Roll Call (Self-Check)
# Iterates through all agents defined in audio-effects.cfg to verify audio pipeline.

CONFIG_FILE=".claude/config/audio-effects.cfg"
PER_MGR=".claude/hooks/personality-manager.sh"
TTS=".claude/hooks/play-tts.sh"

echo "🎙️  Initiating AgentVibes System Self-Check..."
echo "==========================================="

# Extract agent names (lines starting with Name|)
grep "^[^#]" "$CONFIG_FILE" | cut -d'|' -f1 | while read -r AGENT; do
  # Skip internal keys
  if [[ "$AGENT" == "default" ]] || [[ "$AGENT" == "_party_mode" ]]; then
    continue
  fi

  echo "Testing: $AGENT"
  
  # 1. Set Personality (Suppress output)
  if $PER_MGR set "$AGENT" >/dev/null 2>&1; then
      echo "  ✅ Personality Loaded"
  else
      # If personality file doesn't exist, create a temp one or skip?
      # For now, we assume if it's in audio-effects, it should be testable.
      # But if the .md file is missing, personality-manager fails.
      # We will just try to speak using the effect mapping directly (which play-tts-piper does).
      # However, play-tts-piper needs the personality to be set to trigger the lookup.
      echo "  ⚠️  Personality definition missing (using default voice with effects)"
      # Force the mapping in memory if possible? No, we rely on the file.
  fi

  # 2. Speak
  $TTS "$AGENT online. Audio check."
  
  # 3. Pause
  sleep 1
  echo ""
done

# Restore Architect
$PER_MGR set Winston >/dev/null
echo "==========================================="
echo "✅ Self-Check Complete."
