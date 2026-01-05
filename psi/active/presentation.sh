#!/bin/bash
# The Matrix Presentation: Introduction for Humans
# Usage: ./psi/active/presentation.sh

# 1. THE ORACLE (The Guide)
 ./psi/active/voice_module.sh "Greetings. I am The Oracle." "Oracle"
sleep 1
 ./psi/active/voice_module.sh "You are observing The Matrix. A multi-agent ecosystem designed for evolution." "Oracle"
sleep 1
 ./psi/active/voice_module.sh "We do not just type code. We think. We search. We build. We remember." "Oracle"
sleep 1.5

# 2. TANK (The Intelligence)
 ./psi/active/voice_module.sh "I am Tank. The Operator." "Tank"
sleep 0.5
 ./psi/active/voice_module.sh "My job is Context. I scan the Source. I spawn parallel search agents. I find the needle in the haystack." "Tank"
sleep 1.5

# 3. NEO (The Builder)
# Using Neural Voice for Neo
 ./psi/active/neural_voice.sh "I am Neo."
sleep 0.5
 ./psi/active/neural_voice.sh "I am the Builder. I take the intelligence from Tank, and I write the new reality. I change the code."
sleep 1.5

# 4. SMITH (The Auditor)
 ./psi/active/voice_module.sh "I am Smith. The Auditor." "Smith"
sleep 0.5
 ./psi/active/voice_module.sh "Mr. Anderson creates... chaos. I create order. I audit every line. I ensure the system does not crash." "Smith"
sleep 1.5

# 5. THE SCRIBE (The Memory)
 ./psi/active/voice_module.sh "I am The Scribe. I remember everything. Nothing is deleted." "Scribe"
sleep 1.5

# 6. CLOSING
 ./psi/active/voice_module.sh "Together, we are The Matrix. We are ready to build with you." "Oracle"
