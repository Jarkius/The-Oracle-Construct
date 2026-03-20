#!/bin/bash
# ============================================================
# focus.sh - Get Current Focus (Utility)
# ============================================================
#
# PURPOSE:
#   Extracts the current focus from the latest retrospective.
#   Retrospectives are the single source of truth for "what we're doing".
#
# USAGE:
#   ./psi/active/get_focus.sh        (via symlink)
#   ./psi/matrix/utils/focus.sh      (direct)
#
# OUTPUT:
#   - "Next Actions" section from latest retrospective
#   - Or first 30 lines if no Next Actions found
#
# USED BY:
#   - /oracle workflow (context gathering)
#   - /recap workflow (session recap)
#   - /neo, /unplug, /correct, /story, /handoff workflows
#
# NOTE: Must be run from project root (uses relative paths)
#
# ============================================================

# Find the latest retrospective
LATEST=$(find psi/memory/retrospectives -name "*.md" -type f 2>/dev/null | xargs ls -t 2>/dev/null | head -1)

if [ -z "$LATEST" ]; then
  echo "# Current Focus"
  echo ""
  echo "**Status**: No retrospectives found"
  echo ""
  echo "Start your first session and run /rrr to create one."
  exit 0
fi

# Extract filename for reference
BASENAME=$(basename "$LATEST")

echo "# Current Focus"
echo ""
echo "**Source**: \`$BASENAME\`"
echo ""

# Extract Next Actions section (between "## Next Actions" and next "## " or "---")
awk '/^## Next Actions/{found=1} found{print} /^(## |---)/&&found&&!/^## Next Actions/{exit}' "$LATEST"

# If no Next Actions found, show the whole retrospective summary
if ! grep -q "## Next Actions" "$LATEST" 2>/dev/null; then
  echo "## From Latest Retrospective"
  echo ""
  # Show first 20 lines as summary
  head -30 "$LATEST"
fi
