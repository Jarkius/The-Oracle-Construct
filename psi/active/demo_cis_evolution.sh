#!/bin/bash
# The Matrix Demo: CIS Evolution (2005 -> 2026)
# Usage: ./psi/active/demo_cis_evolution.sh

echo "---------------------------------------------------"
echo "🎬 SCENE START: The Resurrection"
echo "---------------------------------------------------"
sleep 1

# 1. ORACLE (The Mission)
./psi/active/voice_module.sh "The Prophecy is chosen. Resurrection." "Oracle"
echo "🔮 Oracle: 'We must migrate the Core to Laravel 11. Morpheus, guide us.'"
sleep 1.5

# 2. MORPHEUSINFORMATION (The Research)
# Simulating the external search
./psi/active/morpheus_signal.sh "Laravel Legacy Migration Strategy" > /dev/null
echo "🕶️ Morpheus: 'Protocol Found: The Strangler Fig.'"
echo "   -> Tool: Rector (Auto-Refactor)"
echo "   -> Tool: Eloquent (ORM)"
echo "   -> Strategy: Parallel Hosting"
sleep 1.5

# 3. TANK (The Context)
echo "⚡ Tank: 'Locating legacy artifacts in psi/lab/legacy_cis...'"
grep "mysql_" psi/lab/legacy_cis/index.php
sleep 1
echo "⚡ Tank: 'Artifacts acquired. Handing off to Neo.'"
sleep 1.5

# 4. NEO (The Builder)
./psi/active/neural_voice.sh "I see the matrix. The code is... old."
echo "🕶️ Neo: 'Applying Rector. Converting mysql_query to DB::select()...'"
sleep 0.5
echo "   [NEO] -> Refactoring Authentication..."
echo "   [NEO] -> Creating API Routes..."
sleep 1.5

# 5. WOMAN IN RED (The UI)
./psi/active/voice_module.sh "The interface is breathing now." "WomanInRed"
echo "💃 WomanInRed: 'Frameset Destroyed. Hydrating React Root.'"
echo "   -> CSS: Tailwind Grid"
echo "   -> State: TanStack Query"
sleep 1.5

# 6. SMITH (The Audit)
echo "🕵️ Smith: 'Checking for Anomalies (SQL Injection).'"
sleep 0.5
./psi/active/voice_module.sh "The injection point is closed. Prepared Statements active." "Smith"
sleep 1

# 7. CLOSING
./psi/active/voice_module.sh "The System is Reborn." "Oracle"
echo "---------------------------------------------------"
echo "🎬 SCENE END"
echo "---------------------------------------------------"
