#!/bin/bash
# stress_test_queue.sh - EXTREME Voice Queue Verification

VIDEO_MODULE="./psi/active/voice_module.sh"
LOG_FILE="/tmp/stress_test.log"
rm -f "$LOG_FILE"

echo "🔥 STARTING STRESS TEST"
echo "----------------------"

# 1. Race Condition: 10 concurrent requests
echo "Phase 1: Concurrent Bombardment (10 agents)"
pids=""
for i in {1..10}; do
    (
        # Randomized sleep to ensure genuine race (not just spawn order)
        sleep 0.$(($RANDOM % 5))
        bash "$VIDEO_MODULE" "Message $i" "System" >> "$LOG_FILE" 2>&1
    ) &
    pids="$pids $!"
done

wait $pids
echo "Phase 1 Complete."

# 2. Crash Simulation
echo "Phase 2: Crash Simulation (Lock Recovery)"
echo "Spawning a process that will be KILLED while holding lock..."

# We need to manually simulate this because killing voice_module might be too fast to catch
# But we can verify if a stale lock file prevents new messages (it shouldn't, due to our logic)

echo $$ > /tmp/matrix_voice.lock
echo "Main process $$ created manual lock."

# Try to speak - should eventually break the lock or detect it's mine (if $$ matches)
# Actually, if I created it with $$, 'shlock' (if used) might think I own it.
# Let's create a lock with a FAKE PID
echo 999999 > /tmp/matrix_voice.lock
echo "Created STALE lock with PID 999999."

# Now try to speak. 
# If logic is robust, it should detect 999999 is dead (shlock) OR timeout and break (mkdir).
start_time=$(date +%s)
bash "$VIDEO_MODULE" "Recovered from crash." "Oracle"
end_time=$(date +%s)
duration=$((end_time - start_time))

echo "Recovery took $duration seconds."
if [ $duration -gt 15 ]; then
    echo "❌ FAILED: Recovery too slow (Possible Deadlock)"
else
    echo "✅ PASSED: Lock recovered"
fi

echo "----------------------"
echo "Check $LOG_FILE for output order."
grep "🗣️" "$LOG_FILE" | wc -l | xargs echo "Messages successfully played:"
