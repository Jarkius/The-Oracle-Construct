#!/usr/bin/env bash
#
# File: .claude/hooks/matrix-verify-voices.sh
#
# The Matrix - AI Development Environment
# Repository: https://github.com/Jarkius/The-Oracle-Construct
#
# Co-created by Jarkius with Claude AI (The Council)
# "Know Thyself." - The Oracle
#
# ---
#
# @fileoverview Voice Configuration Audit - Verify agent voice mappings
# @context Part of Smith's /patrol duties - checks voice config consistency
# @agent Smith (The Debugger)
#
# USAGE:
#   .claude/hooks/matrix-verify-voices.sh
#
# CHECKS:
#   - voices.json (source of truth) exists
#   - Current voice matches an agent
#   - All voice models are present
#
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Source of truth
VOICES_JSON="$PROJECT_ROOT/.claude/config/voices.json"
VOICE_FILE="$PROJECT_ROOT/tts-voice.txt"
PERSONALITY_FILE="$PROJECT_ROOT/tts-personality.txt"

echo "=== VOICE CONFIGURATION AUDIT ==="
echo "Source of Truth: $VOICES_JSON"
echo ""

# Check if source of truth exists
if [[ ! -f "$VOICES_JSON" ]]; then
    echo "❌ CRITICAL: Source of truth missing!"
    exit 1
fi

echo "Agent Voice Mappings (from voices.json):"
echo "---"
jq -r 'to_entries[] | "   \(.key): \(.value.voice) (\(.value.personality))"' "$VOICES_JSON"
echo ""

# Check current active voice
CURRENT_VOICE=$(cat "$VOICE_FILE" 2>/dev/null || echo "NOT SET")
CURRENT_PERSONALITY=$(cat "$PERSONALITY_FILE" 2>/dev/null || echo "NOT SET")

echo "Current Active Voice:"
echo "   Voice: $CURRENT_VOICE"
echo "   Personality: $CURRENT_PERSONALITY"
echo ""

# Check if current voice matches any agent
MATCHING_AGENT=$(jq -r --arg voice "$CURRENT_VOICE" 'to_entries[] | select(.value.voice == $voice) | .key' "$VOICES_JSON" | head -1)

if [[ -n "$MATCHING_AGENT" ]]; then
    echo "✅ Current voice matches agent: $MATCHING_AGENT"
else
    echo "⚠️  Current voice doesn't match any agent in voices.json"
    echo "   This may indicate drift or manual override"
fi
echo ""

# Check for voice model files
echo "Voice Model Status:"
VOICE_DIR="$HOME/.claude/piper-voices"
ISSUES=0

while IFS= read -r agent; do
    voice=$(jq -r --arg key "$agent" '.[$key].voice' "$VOICES_JSON")
    model_file="$VOICE_DIR/${voice}.onnx"

    if [[ -f "$model_file" ]]; then
        echo "   ✅ $agent: $voice (model exists)"
    else
        echo "   ❌ $agent: $voice (MODEL MISSING!)"
        ISSUES=$((ISSUES + 1))
    fi
done < <(jq -r 'keys[]' "$VOICES_JSON")

echo ""
if [[ $ISSUES -eq 0 ]]; then
    echo "✅ All voice models present"
else
    echo "❌ $ISSUES voice model(s) missing - run voice download"
fi

echo ""
echo "=== END VOICE AUDIT ==="
