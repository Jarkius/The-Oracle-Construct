#!/bin/bash
# The Operator's Load (Ability 2.0 - God Mode)
# Purpose: The absolute best method for finding signal in the noise.

QUERY="$1"
OPTION="$2"
TARGET_AGENT="$3"

if [ -z "$QUERY" ]; then
    echo "⚡ Tank: 'I need a target.'"
    echo "   Usage: $0 [term] [--feed agent]"
    exit 1
fi

# Detect Best Tools (Self-Awareness)
HAS_RG=$(command -v rg)
HAS_FD=$(command -v fd)

# Handoff Logic
if [ "$OPTION" == "--feed" ] && [ ! -z "$TARGET_AGENT" ]; then
    OUTPUT_FILE="psi/inbox/handoff_${TARGET_AGENT}.md"
    echo "⚡ Tank: 'Constructing dossier for $TARGET_AGENT in $OUTPUT_FILE...'"
    
    # APPEND (>>) to build a complete picture, don't overwrite
    exec >> "$OUTPUT_FILE"
    echo ""
    echo "---"
    echo "## 📥 Tank Drop: '$QUERY' ($(date '+%H:%M:%S'))"
fi

echo "⚡ Tank: Scanning Matrix for '$QUERY'..."

# 1. Structure Search (Best Method: fd -> find)
echo "## 📂 Artifacts (Files)"
if [ -n "$HAS_FD" ]; then
    # Fix: Use --full-path if query looks like a path (contains /)
    if [[ "$QUERY" == *"/"* ]]; then
        fd --full-path "$QUERY" --exclude .git --exclude node_modules | head -n 10 | sed 's/^/- /'
    else
        fd -t f "$QUERY" --exclude .git --exclude node_modules | head -n 10 | sed 's/^/- /'
    fi
else
    # Fallback
    find . -type f -not -path '*/.*' -name "*$QUERY*" | head -n 10 | sed 's/^/- /'
fi

echo ""
echo "## 📝 Code Context (Best Method: rg -> grep)"
# 2. Content Search (Best Method: rg -> grep)
if [ -n "$HAS_RG" ]; then
    # rg is vastly superior: respects gitignore, faster, better formatting
    rg -n -C 2 --heading --color never "$QUERY" \
        --glob '!node_modules' \
        --glob '!venv' \
        --glob '!.git' \
        | head -n 100 \
        | sed 's/^/   /'
else
    # Fallback optimized grep
    LC_ALL=C grep -r -n -I -C 2 "$QUERY" . \
        --exclude-dir=".git" \
        --exclude-dir="node_modules" \
        | head -n 50 \
        | sed 's/^/   /'
fi

echo ""
echo "## 🧠 The Source (Knowledge)"
# 3. Knowledge Check
if [ -n "$HAS_RG" ]; then
    rg -l "$QUERY" psi/The_Source .claude/knowledge | sed 's/^/- /'
else
    grep -r -l "$QUERY" psi/The_Source .claude/knowledge 2>/dev/null | sed 's/^/- /'
fi

if [ "$OPTION" == "--feed" ]; then
    echo ""
    echo "> End of Drop."
fi
