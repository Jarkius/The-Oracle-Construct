#!/bin/bash
# System Resume Protocol: "Wake Up, Neo."
# Usage: ./psi/active/system_resume.sh

echo "---------------------------------------------------"
echo "🔌 SYSTEM BOOT: Re-establishing Connection..."
echo "---------------------------------------------------"

# 1. READ IDENTITY
echo "💾 Loading Core Logic (CLAUDE.md)..."
if [ -f "CLAUDE.md" ]; then
    echo "   -> Universal Interface: ACTIVE."
else
    echo "   -> CRITICAL ERROR: Identity Lost."
    exit 1
fi

# 2. READ FOCUS (The "Now")
echo "🧠 Loading Context (focus.md)..."
if [ -f "psi/inbox/focus.md" ]; then
    echo "---------------------------------------------------"
    cat psi/inbox/focus.md
    echo "---------------------------------------------------"
else
    echo "   -> No active focus."
fi

# 3. READ MEMORY (The "Past")
LAST_RETRO=$(ls -t psi/memory/retrospectives/*/*/*.md | head -1)
echo "📜 Reading Last Memory ($LAST_RETRO)..."
head -5 "$LAST_RETRO"

# 4. START ENGINE
echo "---------------------------------------------------"
./psi/active/voice_module.sh "Welcome back to the Matrix. We are going to build the most incredible system anyone has ever seen. Believe me." "Architect"
echo "🏛️ ARCHITECT: System Online. Intelligence Restored."
echo "---------------------------------------------------"
