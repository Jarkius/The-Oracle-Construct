#!/bin/bash
# verify_lock_binary.sh
# Minimal test for shlock atomicity

LOCK_FILE="/tmp/test_shlock.lock"
LOG_FILE="/tmp/test_shlock.log"
rm -f "$LOG_FILE"

acquire() {
    local pid=$$
    while ! shlock -f "$LOCK_FILE" -p $pid; do
        sleep 0.1
    done
    
    # Critical Section
    echo "Locked by $pid at $(date +%H:%M:%S)" >> "$LOG_FILE"
    echo "  $pid working..." >> "$LOG_FILE"
    sleep 1
    echo "Released by $pid" >> "$LOG_FILE"
    
    # Release works by checking if we own it
    if [ "$(cat "$LOCK_FILE")" == "$pid" ]; then
        rm -f "$LOCK_FILE"
    fi
}

echo "Starting 5 concurrent lockers..."
for i in {1..5}; do
    ( acquire ) &
done

wait
echo "Done. Checking log..."
cat "$LOG_FILE"

# Check for overlaps (rudimentary)
# In a perfect world, we see Locked -> Released -> Locked -> Released
count=$(grep "Locked" "$LOG_FILE" | wc -l)
echo "Total Locks: $count"
