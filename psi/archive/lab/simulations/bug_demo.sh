#!/bin/bash
# The Matrix Demo: Bug Protocol
# Scenario: A critical memory leak is detected.

# Load Helper Functions
source psi/active/voice_module.sh "Protocol Initiated" "System" > /dev/null

echo "---------------------------------------------------"
echo "🎬 SCENE START: The Anomaly"
echo "---------------------------------------------------"
sleep 1

# 1. THE USER DETECTS BUG
echo "👤 Jarkius: \"Oracle, the system is slowing down. Memory leak.\""
sleep 1.5

# 2. THE ORACLE (Routing)
./psi/active/voice_module.sh "An imbalance... Merovingian, find the cause." "Oracle"
echo "   🔮 Oracle: 'We must understand WHY before we act.'"
sleep 1

# 3. THE MEROVINGIAN (Root Cause)
# Simulating the tool usage
./psi/active/mero_cause.sh "Memory Leak in psi/active" > /dev/null
echo "   🍷 Merovingian: 'It is simple. The 'Array' is never cleared.'"
echo "   🍷 Merovingian: 'Chain: Leak -> Global Var -> cache_data -> Never Reset.'"
sleep 1.5

# 4. TANK (Locate)
echo "   ⚡ Tank: 'Locating variable definition...'"
./psi/active/operator_spawn.sh --feed smith "cache_data" "global" > /dev/null
echo "   ⚡ Tank: 'Found in cache.py line 204. Handing off to Smith.'"
sleep 1

# 5. AGENT SMITH (The Fixer)
echo "   🕵️ Smith: 'Mr. Anderson left a mess. Purging.'"
./psi/active/smith_audit.sh > /dev/null
./psi/active/voice_module.sh "Bug neutralized. Memory optimized." "Smith"
sleep 1

# 6. NEO (Verification)
./psi/active/neural_voice.sh "The code is clean. The leak is gone."
echo "   🕶️ Neo: 'Unit Test Passed.'"

echo "---------------------------------------------------"
echo "🎬 SCENE END"
echo "---------------------------------------------------"
