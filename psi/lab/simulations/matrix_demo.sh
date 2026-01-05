#!/bin/bash
# The Matrix Demo 2.0: The Cycle of the One
# Scenario: A request to change the physics of the Matrix.

# Load Helper Functions
source psi/active/voice_module.sh "System Ready" "System" > /dev/null

echo "---------------------------------------------------"
echo "🎬 SCENE START: The Source"
echo "---------------------------------------------------"
sleep 1

# 1. THE USER (Jarkius) INPUT
echo "👤 Jarkius: \"Oracle, I want Neo to fly. Is it possible?\""
sleep 1.5

# 2. THE ORACLE (Decision/Routing)
./psi/active/voice_module.sh "I see... you wish to rewrite the laws." "Oracle"
echo "   🔮 Oracle: 'Tank, consult The Source. Do we have precedent?'"
sleep 1

# 3. TANK (The Operator - Knowledge & Context)
echo "   ⚡ Tank: 'Scanning psi/The_Source...'"
# Tank explicitly checking the new knowledge base
./psi/active/operator_load.sh "evolution" --feed neo > /dev/null
sleep 1

echo "   ⚡ Tank: 'Precedent found in 00_evolution.md. Spawning agents...'"
./psi/active/operator_spawn.sh --feed neo "physics" "gravity" "velocity" &
PID=$!
wait $PID
sleep 0.5
./psi/active/voice_module.sh "Dossier compiled. Neo, the path is open." "Tank"
sleep 1

# 4. NEO (Action/Logic)
# Simulating Neo reading the inbox
echo "   🕶️ Neo: 'Reading psi/inbox/handoff_neo.md...'"
sleep 1
./psi/active/neural_voice.sh "I see the code. The gravity constant is exposed. I can rewrite it."
echo "   🕶️ Neo: 'Proposal: Override gravity in physics.py line 42.'"
sleep 1

# 5. AGENT SMITH (Audit/Constraint)
echo "   🕵️ Smith: 'Anomaly detected.'"
./psi/active/smith_audit.sh > /dev/null
./psi/active/voice_module.sh "Mr. Anderson... this change creates instability." "Smith"
sleep 1

# 6. THE SCRIBE (Memory/Retrospective)
echo "   📜 Scribe: 'Recording the conflict to The Source...'"
./psi/active/scribe_record.sh "demo_flight_protocol" > /dev/null
echo "   📜 Scribe: 'Session saved. Memory updated.'"
sleep 1

# 7. THE ARCHITECT (Map)
echo "   📐 Architect: 'The equation remains unbalanced. But necessary.'"

echo "---------------------------------------------------"
echo "🎬 SCENE END: The Cycle Continues"
echo "---------------------------------------------------"
