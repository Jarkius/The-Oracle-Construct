#!/bin/bash
# Oracle Unified Prophecy (The Automatic Council)
# Usage: ./psi/active/oracle_prophecy.sh

echo "---------------------------------------------------"
echo "🔮 ORACLE: Convening The Council..."
echo "---------------------------------------------------"

# [VOICE HOOK] Identity
sh psi/active/voice_module.sh "The Council connects. Monitoring systems..." "Oracle" &


# 1. MORPHEUS [Research]
echo "🕶️ Morpheus: Checking External Reality..."
if [ -f "psi/inbox/research_request.md" ]; then
    echo "   -> Research Active."
else
    echo "   -> No pending research. Watching the web."
fi

# 2. TANK [Context]
# [SCRIBE OPTIMIZATION] Compaction
python3 psi/active/scribe_optimize.py

echo "⚡ Tank: Scanning Internal Matrix (Memory Bank)..."

cat psi/memory_bank/activeContext.md
git status --short | head -3

# 3. ARCHITECT [Structure]
echo "📐 Architect: Reviewing Blueprint..."
if [ -f "psi/memory_bank/productContext.md" ]; then
    echo "   -> Blueprint Valid: CIS 2026 (Product Context)"
else

    echo "   -> Warning: No active blueprint."
fi

# 4. NEO [Action]
echo "🕶️ Neo: Ready to code."

# 5. WOMAN IN RED [Design]
echo "💃 WomanInRed: Monitoring UX..."
# She checks for 'frontend' folder or .css files
if [ -d "frontend" ] || ls *.css 1> /dev/null 2>&1; then
    echo "   -> UI Assets detected."
else
    echo "   -> Alert: Where is the Interface?"
fi

# 6. SMITH [Audit]
echo "🕵️ Smith: Perimeter Check."
# Simple check for TODOs
grep -r "TODO" . | head -1 > /dev/null
if [ $? -eq 0 ]; then
    echo "   -> Anomalies (TODOs) detected."
else 
    echo "   -> System Clean."
fi

echo "---------------------------------------------------"
echo "🔮 ORACLE: The Council is Aligned. What is your will?"
echo "---------------------------------------------------"

# [VOICE HOOK] Completion
sh psi/active/voice_module.sh "The Council is Aligned. What is your will?" "Oracle" &

