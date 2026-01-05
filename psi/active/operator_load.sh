#!/bin/bash
# The Operator's Load (Ability 1.0)
# Purpose: Find context, source code, and knowledge to feed the field agents.
# "Tank, load the jump program."

QUERY="$1"
CONTEXT_DEPTH="${2:-2}" # Lines of context

if [ -z "$QUERY" ]; then
    echo "📞 Operator: 'I need a target. What are you looking for?'"
    echo "   Usage: ./operator_load.sh [search_term] [context_lines]"
    exit 1
fi

echo "💾 Operator: Scanning Matrix for '$QUERY'..."

# 1. Search File Names (The Structure)
FOUND_FILES=$(find . -not -path '*/.*' -not -path '*/node_modules/*' -name "*$QUERY*")

if [ ! -z "$FOUND_FILES" ]; then
    echo "📂 Artifacts Found (Files):"
    echo "$FOUND_FILES" | sed 's/^/   - /'
fi

# 2. Search Content (The Code - excluding large dirs)
echo "📝 Code Patterns (Content):"
grep -r -n -I -C "$CONTEXT_DEPTH" "$QUERY" . \
    --exclude-dir=".git" \
    --exclude-dir="node_modules" \
    --exclude-dir="venv" \
    --exclude-dir="__pycache__" \
    | head -n 20 \
    | sed 's/^/   /'

# 3. Knowledge Base Check (.claude/knowledge)
echo "🧠 Knowledge Base (Philosophy):"
grep -r -l "$QUERY" .claude/knowledge 2>/dev/null | xargs -I {} echo "   - Referenced in {}"

echo "---------------------------------------------------"
echo "📞 Operator: 'Upload complete. Context is ready.'"
echo "---------------------------------------------------"
