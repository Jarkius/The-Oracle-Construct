#!/bin/bash
# The Matrix: Chain Reaction (Autonomous Handoff)
# Usage: ./psi/active/chain_reaction.sh

echo "---------------------------------------------------"
echo "🔗 The Chain: WomanInRed -> Neo -> Smith -> Scribe"
echo "---------------------------------------------------"
sleep 1

# 1. NEO (Takes the Baton from WomanInRed)
./psi/active/neural_voice.sh "I see the frontend. I will build the Core."
echo "🕶️ Neo: 'Initializing Backend Structure...'"
mkdir -p backend/public
echo "<?php echo 'Laravel Core Active'; ?>" > backend/public/index.php
echo "   [NEO] -> backend/public/index.php Created."
sleep 1

# 2. HANDOFF (Neo -> Smith)
# In a real system, this would be a webhook or file trigger.
echo "🕶️ Neo: 'Smith, verify structural integrity.'"
sleep 1

# 3. SMITH (The Audit)
./psi/active/voice_module.sh "My turn. Scanning for vulnerability." "Smith"
echo "🕵️ Smith: 'Auditing backend/public...'"
if grep "mysql_connect" backend/public/index.php; then
    echo "   [SMITH] -> ALERT: Legacy Code Detected!"
    exit 1
else
    echo "   [SMITH] -> Clean. No legacy functions found."
fi
sleep 1

# 4. HANDOFF (Smith -> Scribe)
echo "🕵️ Smith: 'Scribe, log the build.'"
sleep 1

# 5. SCRIBE (The Memory)
./psi/active/voice_module.sh "It is written." "Scribe"
./psi/active/scribe_record.sh "chain_reaction_cis_init" > /dev/null
echo "📜 Scribe: 'Event recorded in psi/memory/retrospectives.'"
sleep 1

echo "---------------------------------------------------"
echo "✅ CHAIN COMPLETE. The System is Alive."
echo "---------------------------------------------------"
