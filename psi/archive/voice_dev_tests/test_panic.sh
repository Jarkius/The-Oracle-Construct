#!/bin/bash
# test_panic.sh - Verification of Emergency Override

VIDEO_MODULE="./psi/active/voice_module.sh"

echo "🚨 STARTING PANIC TEST"
echo "----------------------"

# 1. Spawn a 'Blocker' - a slow message that holds the lock
echo "1. Spawning Blocking Agent (Oracle)..."
(
    bash "$VIDEO_MODULE" "I am speaking very slowly to block the queue for the standard duration of this long sentence." "Oracle"
) &
BLOCKER_PID=$!

# Give it a split second to grab the lock
sleep 0.5

# 2. Spawn a 'Panic' agent - should play IMMEDIATELY, not wait
# Use System (Lightweight) instead of Smith (Heavy processing) to prove lock bypass
echo "2. Spawning Panic Agent (System) with --panic..."
start_time=$(date +%s)
bash "$VIDEO_MODULE" "SYSTEM OVERRIDE!" "System" --panic
end_time=$(date +%s)

duration=$((end_time - start_time))

echo "----------------------"
echo "Panic Message Duration: $duration seconds"

# Oracle speaks for ~8-10s.
# If Panic plays in < 5s, it definitely Bypassed.
# (If it waited, it would be > 8s).

wait $BLOCKER_PID

if [ $duration -lt 6 ]; then
    echo "✅ PASSED: Panic message bypassed the queue."
else
    echo "❌ FAILED: Panic message waited for the queue."
fi
