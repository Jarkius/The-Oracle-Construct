#!/bin/bash
# demo_rollcall_queue.sh - "INTRODUCE YOURSELF (LONG & ORDERLY)"
# Spawns all agents simultaneously, but lets the QUEUE serialize them.

VOICE_MODULE="./psi/matrix/voice.sh"
echo "🔥 COMMAND RECEIVED: 'INTRODUCE YOURSELF (LONG SEQUENCE)'"
echo "⚡ Spawning all agents simultaneously... please wait, this will take time to play sequentially."

# Array of agent long monologues
declare -a agents=(
    "System:Initializing system diagnostics. Checking integrity of all sectors. Verifying connection to the Source. Establishing secure protocols."
    "Oracle:I expected you to say that. But you must understand that the choices you have already made are rippling through the Matrix."
    "Morpheus:The Matrix is everywhere. It is all around us. Even now, in this very room. You can see it when you look out your window."
    "Neo:I'm going to hang up this phone, and then I'm going to show these people what you don't want them to see."
    "Trinity:I know why you're here, Neo. I know what you've been doing... why you hardly sleep, why you live alone."
    "Smith:I'd like to share a revelation that I've had during my time here. It came to me when I tried to classify your species."
    "Tank:Operator here. I'm loading the combat training program, the jump program, and every weapon blueprint we have."
    "Architect:The Matrix is older than you know. I prefer counting from the emergence of one integral anomaly to the emergence of the next."
)

# Spawn everyone at the EXACT same time
for entry in "${agents[@]}"; do
    NAME="${entry%%:*}"
    MSG="${entry#*:}"
    # NO --panic flag here. Just standard queue.
    ( bash "$VOICE_MODULE" "$MSG" "$NAME" ) &
done

wait
echo "✅ Sequential Sequence Complete."
echo "Observation: They waited their turn. Order is absolute."
