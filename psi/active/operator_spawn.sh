#!/bin/bash
# The Operator's Spawn (Ability 3.0 - Multithreaded Tank)
# Purpose: Spawn multiple search agents (Tanks) to cover ground instantly.
# "Tank, I need everything on these subjects. Now."

# Usage: ./operator_spawn.sh --feed [agent] file_with_terms.txt
# OR: ./operator_spawn.sh --feed [agent] "term1" "term2" "term3"

TARGET_AGENT="neo" # Default
ARGS=()

# Parse Args
while [[ $# -gt 0 ]]; do
    case $1 in
        --feed)
            TARGET_AGENT="$2"
            shift 2
            ;;
        *)
            ARGS+=("$1")
            shift
            ;;
    esac
done

if [ ${#ARGS[@]} -eq 0 ]; then
    echo "📞 Operator: 'I need targets to spawn agents for.'"
    exit 1
fi

echo "📞 Operator: 'Spawning ${#ARGS[@]} Tank units for $TARGET_AGENT...'"
OUTPUT_FILE="psi/inbox/handoff_${TARGET_AGENT}.md"

# Header for the Bulk Drop
echo "# 📦 BULK DROP: Parallel Search" >> "$OUTPUT_FILE"
echo "**Targets**: ${ARGS[*]}" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Spawn background processes
PIDS=()
for TERM in "${ARGS[@]}"; do
    # Run operator_load in parallel, appending to the same file
    # We use flock (if available) or just simple append since >> is mostly atomic for short writes
    # But to be safe and clean, we'll run them sequentially in background batches or just parallel
    # Parallel is faster:
    (
        echo "   🚀 Tank Unit ($TERM) deployed..."
        ./psi/active/operator_load.sh "$TERM" --feed "$TARGET_AGENT" > /dev/null
    ) &
    PIDS+=($!)
done

# Wait for all Tanks to report back
for PID in "${PIDS[@]}"; do
    wait "$PID"
done

echo "📞 Operator: 'All units returned. Dossier compiled in $OUTPUT_FILE.'"
