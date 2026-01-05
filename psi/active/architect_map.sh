#!/bin/bash
# The Architect's Map (Ability 1.0)
# Purpose: Visualize structure and critique the design.
# "Ergo, some of my answers will be understood, and some not."

TARGET_DIR="${1:-.}"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

echo "📐 The Architect is measuring the Matrix..."

# 1. Structural Visualization (Tree)
# Check if 'tree' exists, otherwise use find (Simple but Robust fallback)
if command -v tree &> /dev/null; then
    tree -L 2 -I 'node_modules|venv|__pycache__|.git' "$TARGET_DIR"
else
    find "$TARGET_DIR" -maxdepth 2 -not -path '*/.*' | sed -e 's;[^/]*/;|____;g;s;____|; |;g'
fi

# 2. Chaos Detection (Flat Structure)
# Count files in the immediate root (excluding directories)
ROOT_FILES=$(find "$TARGET_DIR" -maxdepth 1 -type f -not -name ".*" | wc -l | xargs)
CHAOS_LIMIT=8

if [ "$ROOT_FILES" -gt "$CHAOS_LIMIT" ]; then
    echo "⚠️  IMBALANCE DETECTED: $ROOT_FILES files in the root directory."
    echo "   "The equations are unbalanced. Categorize your variables.""
    echo "   (Recommendation: Move loose files into 'psi/' or 'src/')"
else
    echo "✅ Balance: Root structure is ordered."
fi

# 3. Memory Integrity
if [ -d "psi/memory" ]; then
    echo "✅ Persistence: Memory core (psi/memory) is online."
else
    echo "❌ CRITICAL: Memory core missing. The system cannot learn."
fi

echo "---------------------------------------------------"
echo "🏛️  Design Review Complete."
echo "---------------------------------------------------"
