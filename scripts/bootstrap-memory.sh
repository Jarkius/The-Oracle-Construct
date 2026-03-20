#!/bin/bash
#
# Bootstrap Memory — Ingest existing psi/ markdown into matrix-memory-agents
#
# Feeds all existing sessions, retrospectives, learnings, and ADRs
# into the SQLite + ChromaDB index for instant semantic search.
#
# Called by: scripts/setup-memory.sh (or manually)
#

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
PSI_DIR="$PROJECT_DIR/psi"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

cd "$PROJECT_DIR"

TOTAL=0
INGESTED=0
FAILED=0

ingest_dir() {
    local dir="$1"
    local label="$2"
    local count=0

    if [ ! -d "$dir" ]; then
        return
    fi

    local files
    files=$(find "$dir" -name "*.md" -type f 2>/dev/null | sort)
    local file_count
    file_count=$(echo "$files" | grep -c . 2>/dev/null || echo 0)

    if [ "$file_count" -eq 0 ]; then
        return
    fi

    echo -e "  ${BLUE}$label${NC} ($file_count files)"

    while IFS= read -r f; do
        [ -z "$f" ] && continue
        TOTAL=$((TOTAL + 1))
        if bun memory learn "$f" > /dev/null 2>&1; then
            INGESTED=$((INGESTED + 1))
            count=$((count + 1))
        else
            FAILED=$((FAILED + 1))
        fi
    done <<< "$files"

    echo -e "  ${GREEN}✓${NC} $count files ingested"
}

echo -e "${YELLOW}Ingesting psi/ archive into memory system...${NC}"
echo ""

# Ingest in priority order: recent sessions first, then historical
ingest_dir "$PSI_DIR/memory/sessions"        "Sessions"
ingest_dir "$PSI_DIR/memory/retrospectives"  "Retrospectives"
ingest_dir "$PSI_DIR/memory/learnings"       "Learnings"
ingest_dir "$PSI_DIR/memory/adr"             "ADRs"
ingest_dir "$PSI_DIR/memory/decisions"       "Decisions"
ingest_dir "$PSI_DIR/memory/blueprints"      "Blueprints"
ingest_dir "$PSI_DIR/learn/active"           "Active Research"
ingest_dir "$PSI_DIR/learn/archive"          "Archived Research"

echo ""
echo -e "${GREEN}Bootstrap complete:${NC} $INGESTED/$TOTAL ingested ($FAILED failed)"

# Rebuild vector index if ChromaDB is available
if [ "${SKIP_VECTORDB}" != "true" ]; then
    echo ""
    echo -e "${YELLOW}Rebuilding vector index...${NC}"
    bun memory reindex 2>&1 | tail -3 || echo -e "${YELLOW}⚠${NC} Reindex skipped (ChromaDB may not be available)"
    echo -e "${GREEN}✓${NC} Vector index rebuilt"
fi
