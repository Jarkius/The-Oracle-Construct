#!/bin/bash
# Smith's Audit Tool (Ability 1.0)
# Purpose: Detect anomalies and purge imperfections.
# "Mr. Anderson..."

TARGET_DIR="${1:-.}"
echo "🕵️  Smith is scanning the system..."

# [VOICE HOOK] Personality
sh psi/active/voice_module.sh "Mr. Anderson. Searching for anomalies..." "Smith" &

# 1. Skeptical Audit of "Loose Ends" (Untracked Files)
UNTRACKED=$(git ls-files --others --exclude-standard | wc -l | xargs)
if [ "$UNTRACKED" -gt 0 ]; then
    echo "⚠️  ANOMALY: $UNTRACKED files are outside the Matrix (Untracked)."
    echo "   "Why are you hiding them? Commit to the system.""
    # git ls-files --others --exclude-standard | head -3 | sed 's/^/   - /'
fi

# 2. Hunting for Weakness (FIXMEs)
FIXMES=$(grep -r "FIXME" "$TARGET_DIR" --exclude-dir={node_modules,.git,vendor,storage,dist,build} 2>/dev/null | wc -l | xargs)
if [ "$FIXMES" -gt 0 ]; then
    echo "🚨 DETECTED: $FIXMES broken logic nodes (FIXME)."
    echo "   "It is the sound of inevitability... the sound of bad code.""
fi

# 3. Efficiency Check (Large Files)
# Find files larger than 1MB (Agents shouldn't be bloated)
LARGE_FILES=$(find "$TARGET_DIR" -type f -size +1M -not -path "*/.*" -not -path "*/node_modules/*" -not -path "*/vendor/*" -not -path "*/storage/*" -not -path "*/dist/*" 2>/dev/null)
if [ ! -z "$LARGE_FILES" ]; then
    echo "🐘 BLOAT: Found heavy constructs:"
    echo "$LARGE_FILES" | sed 's/^/   - /'
    echo "   "The system is heavy. Purge what is unnecessary.""
else
    echo "✅ Efficiency: System weight is nominal."
fi

echo "---------------------------------------------------"
echo "🛡️  System Audit Complete."
echo "---------------------------------------------------"
