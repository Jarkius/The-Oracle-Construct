#!/bin/bash
# test_super_chaos.sh - "The Burly Brawl"
# Scenario:
# 1. Architect holds the lock (Blocker).
# 2. 20 Smiths try to enter the queue simultaneously (Load).
# 3. Neo, Trinity, Morpheus use --panic to break through (Override).

VIDEO_MODULE="./psi/active/voice_module.sh"
LOG_FILE="/tmp/super_chaos.log"
rm -f "$LOG_FILE"

echo "🔥 STARTING SUPER CHAOS (BURLY BRAWL)"
echo "----------------------"

# 1. The Blocker (Architect)
echo "1. 🏛️ Architect blocking the Source..."
(
    bash "$VIDEO_MODULE" "Ergo, some of my answers will be understood, and some of them will not. You are an anomaly." "Architect" >> "$LOG_FILE" 2>&1
) &
BLOCKER_PID=$!
sleep 2

# 2. The Swarm (20 Smiths - Queue)
echo "2. 🕶️ Spawning 20 Smiths (Queue)..."
for i in {1..20}; do
    (
        bash "$VIDEO_MODULE" "Me, me, me." "Smith" >> "$LOG_FILE" 2>&1
    ) &
done

# 3. The Heroes (Panic - Should mix with each other AND Architect)
echo "3. 🚨 HEROES INTERCEPTING (--panic)..."
sleep 1
( bash "$VIDEO_MODULE" "Trinity! Help!" "Neo" --panic >> "$LOG_FILE" 2>&1 ) &
( bash "$VIDEO_MODULE" "I'm on it!" "Trinity" --panic >> "$LOG_FILE" 2>&1 ) &
( bash "$VIDEO_MODULE" "We have to get out of here!" "Morpheus" --panic >> "$LOG_FILE" 2>&1 ) &

echo "4. Waiting for the dust to settle..."
wait
echo "----------------------"
echo "✅ BRAWL ENDED."

# Analysis
# Analysis (Checking Server Log for evidence)
panic_count=$(grep "PANIC" /tmp/voice_server.log | tail -n 20 | wc -l)
# Clean count is harder to judge from external log efficiently, just checking panic persistence.
clean_count=$(grep "Finished: Smith" /tmp/voice_server.log | tail -n 50 | wc -l)

echo "Total Messages Played: $clean_count / 24"
echo "Panic Overrides Triggered: $panic_count / 3"

if [ "$panic_count" -eq 3 ]; then
    echo "✅ PASSED: All heroes broke through the swarm."
else
    echo "❌ FAILED: Heroes got stuck in the queue."
fi
