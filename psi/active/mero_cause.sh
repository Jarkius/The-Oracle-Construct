#!/bin/bash
# The Merovingian's Causality (Ability 1.0)
# Purpose: Generate the 5 Whys analysis template for an issue.

ISSUE="$1"
if [ -z "$ISSUE" ]; then
    echo "🍷 Merovingian: 'You have come to me without a reason? How disappointing.'"
    echo "   Usage: $0 \"The bug description\""
    exit 1
fi

echo "🍷 Merovingian: 'Cause and effect. Let us trace \"$ISSUE\" to its source.'"

# Output the template
OUTPUT_FILE="psi/inbox/analysis_$(date +%s).md"
cat <<EOF > "$OUTPUT_FILE"
# 🍷 Cause Analysis: $ISSUE

**Symptom**: $ISSUE

**The Causality Chain (5 Whys)**:
1.  **Why?**: [Reason 1]
2.  **Why?**: [Reason 2]
3.  **Why?**: [Reason 3]
4.  **Why?**: [Reason 4]
5.  **ROOT CAUSE**: [The Origin]

**The Choice (Solution)**:
- [ ] Fix the root cause
- [ ] Ignore it (Peril)
EOF

echo "🍷 Merovingian: 'The map is drawn in $OUTPUT_FILE. Find the truth.'"
qm
