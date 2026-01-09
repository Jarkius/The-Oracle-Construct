#!/bin/bash
# test_all_agents.sh - The "Council Meeting" Test
# Spawns EVERY agent simultaneously to verify queue serialization.

VIDEO_MODULE="./psi/active/voice_module.sh"

echo "🔥 STARTING COUNCIL ROLLCALL TEST"
echo "Scenario: All agents speak at the exact same moment."
echo "----------------------"

# List of all agents from voices.json + behaviors
agents=(
    "System"
    "Oracle"
    "Smith"
    "Neo"
    "Trinity"
    "Morpheus"
    "Tank"
    "Architect"
    "Mainframe"
    "Scribe"
)

start_time=$(date +%s)

for agent in "${agents[@]}"; do
    # Spawn in background immediately
    (
        echo "⚡ $agent trying to speak..."
        bash "$VIDEO_MODULE" "This is $agent checking in." "$agent"
    ) &
done

# Wait for all background processes
wait

end_time=$(date +%s)
duration=$((end_time - start_time))

echo "----------------------"
echo "✅ ROLLCALL COMPLETE"
echo "Total Duration: $duration seconds"
echo "If you heard 10 distinct voices one after another, the test PASSED."
