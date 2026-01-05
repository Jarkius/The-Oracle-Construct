#!/bin/bash

# Agent Council Roll Call
# Introduces each persona to the human user.
# CASTING: High-Definition macOS Voices

RATE=200 # Slightly slower for dramatic effect
PAUSE="sleep 1.5"

# Function to speak
speak() {
    # $1=Voice, $2=Text
    echo "🔊 Speaking ($1): $2"
    say -v "$1" -r $RATE "$2"
}

# 1. THE ORACLE (Ava - Premium, Realistic, Warm)
speak "Ava" "I am The Oracle. The Spirit Guardian. I ask... Why? I ensure your mission aligns with your truth."
$PAUSE

# 2. THE ARCHITECT (Ralph - Deep, Commanding)
speak "Ralph" "I am The Architect. The System Engineer. I ask... How? I design the blueprints of your reality."
$PAUSE

# 3. NEO (Neural/Ryan - The One)
echo "🔊 Speaking (Neo/Neural)..."
./psi/active/neural_voice.sh "I am Neo. The Lead Developer. I see the code. I transmute your will into logic."
$PAUSE

# 4. THE WOMAN IN RED (Allison - Expressive)
speak "Allison" "I am The Woman in Red. The Designer. I ask... Is it beautiful? I make the Construct feel alive."
$PAUSE

# 5. AGENT SMITH (Fred - Machine, Cold)
speak "Fred" "Mr. Anderson... I am Agent Smith. The Debugger. I find the anomalies. I purify the code."
$PAUSE

# 6. THE OPERATOR (Rishi - Clear, Tech)
speak "Rishi" "I am The Operator. I watch the feeds. All systems are green. We are ready for your command."
