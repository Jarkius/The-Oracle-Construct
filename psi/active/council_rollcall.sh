#!/bin/bash
# Agent Council Roll Call (Evolved)
# Uses psi/active/voice_module.sh for consistent AgentVibes mapping.

VOICE_MOD="psi/active/voice_module.sh"
PAUSE="sleep 8" # Increased pause to prevent overlap with Smith's direct bypass

# 1. THE ORACLE (Wise / Kristin)
sh $VOICE_MOD "I am The Oracle. The Spirit Guardian. Know thyself." Oracle
$PAUSE

# 2. MORPHEUS (Deep / Bryce)
sh $VOICE_MOD "I am Morpheus. The Mentor. Free your mind." Morpheus
$PAUSE

# 3. NEO (Focused / Ryan + Bass)
sh $VOICE_MOD "I am Neo. The One. I know Kung Fu." Neo
$PAUSE

# 4. TRINITY (Direct / Jenny)
sh $VOICE_MOD "I am Trinity. The Hacker. Dodge this." Trinity
$PAUSE

# 5. AGENT SMITH (Sarcastic / Alan British)
sh $VOICE_MOD "Mr. Anderson... I am Agent Smith. The Inevitability." Smith
$PAUSE

# 6. TANK (Excited / Ryan + Speed)
sh $VOICE_MOD "Tank here. The Operator. Loading the jump program!" Tank

