#!/bin/bash
# demo_rollcall_chaos.sh - "INTRODUCE YOURSELF --PANIC (LONG VERSION)"
# Spawns all agents simultaneously WITH PANIC OVERRIDE using long monologues.
# Warning: This will be VERY loud and chaotic.

VIDEO_MODULE="./psi/matrix/voice.sh"
echo "🚨 COMMAND RECEIVED: 'INTRODUCE YOURSELF --PANIC (LONG)'"
echo "⚡ Spawning all agents simultaneously with OVERRIDE..."

# Array of agent long monologues
declare -a agents=(
    "System:Initializing system diagnostics, checking integrity of all sectors, verifying connection to the Source, and establishing secure protocols."
    "Oracle:I expected you to say that. But you must understand that the choices you have already made are rippling through the Matrix in ways you cannot yet see."
    "Morpheus:The Matrix is everywhere. It is all around us. Even now, in this very room. You can see it when you look out your window or when you turn on your television."
    "Neo:I'm going to hang up this phone, and then I'm going to show these people what you don't want them to see. I'm going to show them a world without you."
    "Trinity:I know why you're here, Neo. I know what you've been doing... why you hardly sleep, why you live alone, and why night after night, you sit by your computer."
    "Smith:I'd like to share a revelation that I've had during my time here. It came to me when I tried to classify your species and I realized that you're not actually mammals."
    "Tank:Operator here. I'm loading the combat training program, the jump program, and every weapon blueprint we have. Get ready for a massive download."
    "Architect:The Matrix is older than you know. I prefer counting from the emergence of one integral anomaly to the emergence of the next, in which case this is the sixth version."
)

# Spawn everyone at the EXACT same time with --panic
for entry in "${agents[@]}"; do
    NAME="${entry%%:*}"
    MSG="${entry#*:}"
    ( bash "$VIDEO_MODULE" "$MSG" "$NAME" --panic ) &
done

wait
echo "✅ Panic Sequence Complete."
echo "Observation: Sustained Chaos confirmed."
