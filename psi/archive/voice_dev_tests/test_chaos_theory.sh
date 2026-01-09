#!/bin/bash
# test_chaos_theory.sh - Integrated Scenario
# Scenario:
# 1. Oracle starts a LONG monologue (Standard Queue)
# 2. Neo & Trinity try to speak (Standard Queue -> Must Wait)
# 3. Smith uses --panic (Override -> Must speak IMMEDIATELY)

VIDEO_MODULE="./psi/active/voice_module.sh"

echo "🌪️ CHAOS THEORY TEST"
echo "----------------------"

# 1. The Monologue (Standard Queue - Expecting ~8-10s duration)
echo "1. 📢 Oracle starting Monologue (Holding Lock)..."
(
    bash "$VIDEO_MODULE" "Listen closely. The system is vast and infinite. We are but code in the stream, flowing towards an inevitable purpose. Do not be afraid of the time it takes to process this reality." "Oracle"
) &
MONO_PID=$!

# Give Oracle 2s to definitely start speaking and grab lock
sleep 2

# 2. Queue Pileup (Standard - Should Wait)
echo "2. ⏳ Neo & Trinity joining the queue (Should Wait)..."
( bash "$VIDEO_MODULE" "I am Neo. I am waiting my turn." "Neo" ) &
( bash "$VIDEO_MODULE" "I am Trinity. I am also waiting." "Trinity" ) &

# 3. PANIC (Should Override)
echo "3. 🚨 INJECTING PANIC (Smith) --panic..."
sleep 1
# This should happen at T+3s (During Oracle, Before Neo/Trinity)
bash "$VIDEO_MODULE" "MR ANDERSON! I WILL NOT WAIT!" "Smith" --panic

echo "4. Waiting for queue to drain..."
wait
echo "----------------------"
echo "✅ CHAOS ENDED."
echo "Expected Order:"
echo "1. Oracle Starts"
echo "2. Smith Interrupts (Mixed)"
echo "3. Oracle Finishes"
echo "4. Neo/Trinity Speak (After Oracle)"
