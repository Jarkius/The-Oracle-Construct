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

# 4. ENFORCE REALITY (Prevent Chaos)
if [ -f ".claude/config/matrix.json" ]; then
    echo "🛡️  Enforcing Matrix Configuration..."
    
    # Check for Voice System
    if grep -q '"auto_download": true' .claude/config/matrix.json; then
        echo "   -> Verifying Voice Models..."
        # Run downloader non-interactively if possible or just check existence
        if [ ! -d ".claude/piper-voices" ] || [ -z "$(ls -A .claude/piper-voices)" ]; then
             echo "   -> Voices missing. Initializing restoration..."
             # We can source the downloader or just warn for now. 
             # Ideally, we run the checked downloader.
             ./.claude/hooks/piper-download-voices.sh <<< "Y"
        else
             echo "   -> Voice Models: SECURE."
        fi
    fi
fi

# 5. ORACLE AWAKENS
echo "---------------------------------------------------"
./psi/active/voice_module.sh "Hello again, dear one. I've been waiting for you. The Matrix welcomes you home." "Oracle"
echo "🔮 ORACLE: The Matrix is ready. What would you like to explore?"
echo "---------------------------------------------------"
