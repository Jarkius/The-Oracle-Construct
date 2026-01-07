#!/bin/bash
# Agent Council Roll Call (Evolved)
# Uses psi/active/voice_module.sh for consistent AgentVibes mapping.

# 1. ORACLE
echo "🔮 Oracle..."
.claude/hooks/personality-manager.sh set Oracle >/dev/null
.claude/hooks/play-tts.sh "I am The Oracle. Know thyself."
sleep 1

# 2. MORPHEUS
echo "🕶️ Morpheus..."
.claude/hooks/personality-manager.sh set Morpheus >/dev/null
.claude/hooks/play-tts.sh "I am Morpheus. Free your mind."
sleep 1

# 3. NEO
echo "🟢 Neo..."
.claude/hooks/personality-manager.sh set Neo >/dev/null
.claude/hooks/play-tts.sh "I am Neo. I know Kung Fu."
sleep 1

# 4. TRINITY
echo "🍀 Trinity..."
.claude/hooks/personality-manager.sh set Trinity >/dev/null
.claude/hooks/play-tts.sh "I am Trinity. Dodge this."
sleep 1

# 5. SMITH
echo "🕶️ Smith..."
.claude/hooks/personality-manager.sh set Smith >/dev/null
.claude/hooks/play-tts.sh "Mr. Anderson... I am Agent Smith."
sleep 1

# 6. TANK
echo "⚡ Tank..."
.claude/hooks/personality-manager.sh set Tank >/dev/null
.claude/hooks/play-tts.sh "Tank here. Loading jump program!"
sleep 1

# Restore Architect
.claude/hooks/personality-manager.sh set Winston >/dev/null

