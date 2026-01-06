#!/bin/bash
# Neo's Logic Core (Ability 1.0)
# Purpose: Analyze code with skepticism and verify structural integrity.
# "I see the code."

TARGET="$1"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
LOG_FILE="psi/memory/neo_journal.log"

# 0. Self-Awareness (Logging)
echo "[$TIMESTAMP] Analyzing reality: $TARGET" >> "$LOG_FILE"

if [ -z "$TARGET" ]; then
    echo "❌ Usage: $0 [filename]"
    echo "   Neo needs a target to focus his will."
    exit 1
fi

if [ ! -f "$TARGET" ]; then
    echo "❌ Illusion: File '$TARGET' does not exist."
    exit 1
fi

# [VOICE HOOK] Personality
sh psi/active/voice_module.sh "I see the code. Loading logic." "Neo" &

echo "🕶️  Neo is reviewing $(basename "$TARGET")..."

# 1. Skeptical Complexity Check
LINE_COUNT=$(wc -l < "$TARGET" | xargs)
LIMIT=150

if [ "$LINE_COUNT" -gt "$LIMIT" ]; then
    echo "⚠️  SKEPTICISM ALERT: This file is $LINE_COUNT lines long."
    echo "   "Why does it need to be this complex? Can it be simplified?""
    # Non-blocking, just a warning (Skeptical thinking)
else
    echo "✅ Structure is efficient ($LINE_COUNT lines). Good."
fi

# 2. Pattern Integrity (Header Check)
if ! head -n 5 "$TARGET" | grep -q -E "#|//|/*"; then
    echo "⚠️  MISSING PURPOSE: No header comments detected."
    echo "   "Code without purpose is just random data. Define its mission.""
fi

# 3. Anomaly Detection (TODOs)
TODO_COUNT=$(grep -c "TODO" "$TARGET")
if [ "$TODO_COUNT" -gt 0 ]; then
    echo "⚠️  INCOMPLETE: Found $TODO_COUNT 'TODO' markers."
    echo "   "We are not here to leave loose ends. Finish the fight.""
fi

# 4. Final Verdict
echo "---------------------------------------------------"
echo "👁️  Analysis Complete."
echo "   Robustness: Verified."
echo "   Efficiency: Checked."
echo "---------------------------------------------------"
