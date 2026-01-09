#!/bin/bash
# test_queue.sh - Verify Voice Queue Logic

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
VOICE_MODULE="$PROJECT_ROOT/psi/active/voice_module.sh"

echo "🧪 Starting Voice Queue Saturation Test..."
echo "timestamp=$(date +%s)"

# Spawn 3 concurrent voices
# We use System, Oracle, and Neo as they have distinct paths
echo "🗣️  Spawning 3 concurrent agents..."

# 1. System (Piper)
bash "$VOICE_MODULE" "System check initiated." "System" &
PID1=$!

# 2. Oracle (Piper)
sleep 0.1
bash "$VOICE_MODULE" "The timeline is converging." "Oracle" &
PID2=$!

# 3. Neo (macOS/Say)
sleep 0.2
bash "$VOICE_MODULE" "I know kung fu." "Neo" &
PID3=$!

# Wait for all
wait $PID1
wait $PID2
wait $PID3

echo "✅ Test Complete."
echo "If voices played sequentially (not overlapping), the test PASSED."
