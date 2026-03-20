#!/bin/bash
#
# Matrix Memory System - Setup Script
#
# Wrapper around matrix-memory-agents that:
# 1. Installs dependencies in lib/matrix-memory-agents/
# 2. Initializes SQLite database
# 3. Starts ChromaDB (Docker) if available
# 4. Bootstraps from existing psi/ markdown archive
# 5. Verifies with bun memory status
#
# Usage: bash scripts/setup-memory.sh [--skip-docker] [--skip-bootstrap]
#

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
MMA_DIR="$PROJECT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SKIP_DOCKER=0
SKIP_BOOTSTRAP=0

for arg in "$@"; do
    case "$arg" in
        --skip-docker) SKIP_DOCKER=1 ;;
        --skip-bootstrap) SKIP_BOOTSTRAP=1 ;;
    esac
done

echo ""
echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        The Oracle Construct — Memory System Setup        ║${NC}"
echo -e "${BLUE}║              ADR-010: The REMEMBRANCE Shortcut           ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# ─── Prerequisites ───────────────────────────────────────────────

echo -e "${YELLOW}Checking prerequisites...${NC}"

if ! command -v bun &> /dev/null; then
    echo -e "${RED}✗ bun not found${NC}"
    echo "  Install with: curl -fsSL https://bun.sh/install | bash"
    exit 1
fi
echo -e "${GREEN}✓${NC} bun $(bun --version)"

if [ $SKIP_DOCKER -eq 0 ]; then
    if command -v docker &> /dev/null && docker info &> /dev/null; then
        echo -e "${GREEN}✓${NC} docker running"
        HAS_DOCKER=1
    else
        echo -e "${YELLOW}⚠${NC} docker not available — ChromaDB (semantic search) will be skipped"
        echo "  SQLite FTS will still work for text search"
        HAS_DOCKER=0
    fi
else
    echo -e "${YELLOW}⚠${NC} docker skipped (--skip-docker)"
    HAS_DOCKER=0
fi

echo ""

# ─── Install Dependencies ───────────────────────────────────────

echo -e "${YELLOW}Installing dependencies...${NC}"
cd "$MMA_DIR"
bun install 2>&1 | tail -3
echo -e "${GREEN}✓${NC} Dependencies installed"
echo ""

# ─── ChromaDB ────────────────────────────────────────────────────

if [ $HAS_DOCKER -eq 1 ]; then
    CHROMA_PORT="${CHROMADB_PORT:-8100}"
    CHROMA_DATA="$HOME/.chromadb_data"

    echo -e "${YELLOW}Setting up ChromaDB...${NC}"

    if docker ps --format '{{.Names}}' | grep -q "^chromadb$"; then
        echo -e "${GREEN}✓${NC} ChromaDB already running on port $CHROMA_PORT"
    elif docker ps -a --format '{{.Names}}' | grep -q "^chromadb$"; then
        docker start chromadb
        echo -e "${GREEN}✓${NC} ChromaDB started"
    else
        mkdir -p "$CHROMA_DATA"
        docker run -d --name chromadb --restart unless-stopped \
            -p "$CHROMA_PORT:8000" \
            -v "$CHROMA_DATA:/chroma/chroma" \
            chromadb/chroma
        echo -e "${GREEN}✓${NC} ChromaDB container created"
    fi

    # Wait for health
    for i in {1..20}; do
        if curl -s "http://localhost:$CHROMA_PORT/api/v2/heartbeat" &> /dev/null; then
            echo -e "${GREEN}✓${NC} ChromaDB healthy on port $CHROMA_PORT"
            break
        fi
        [ $i -eq 20 ] && echo -e "${YELLOW}⚠${NC} ChromaDB slow to start — continuing"
        sleep 1
    done
    echo ""
else
    export SKIP_VECTORDB=true
fi

# ─── SQLite Database ────────────────────────────────────────────

echo -e "${YELLOW}Initializing SQLite database...${NC}"
cd "$MMA_DIR"
bun memory init 2>&1 | tail -3 || bun memory stats > /dev/null 2>&1 || true
echo -e "${GREEN}✓${NC} SQLite initialized"
echo ""

# ─── Bootstrap from psi/ ────────────────────────────────────────

if [ $SKIP_BOOTSTRAP -eq 0 ]; then
    echo -e "${YELLOW}Bootstrapping from existing psi/ archive...${NC}"
    cd "$MMA_DIR"
    bash "$PROJECT_DIR/scripts/bootstrap-memory.sh"
    echo ""
else
    echo -e "${YELLOW}⚠${NC} Bootstrap skipped (--skip-bootstrap)"
    echo ""
fi

# ─── Verification ───────────────────────────────────────────────

echo -e "${YELLOW}Verifying...${NC}"
cd "$MMA_DIR"
bun memory status 2>&1 | head -20 || echo -e "${YELLOW}⚠${NC} Status check had issues"
echo ""

# ─── Summary ────────────────────────────────────────────────────

echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           ✓ Memory System Ready                         ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Usage from project root:${NC}"
echo ""
echo "  bun memory recall \"query\"     # Semantic search"
echo "  bun memory save \"summary\"     # Save session"
echo "  bun memory learn ./file.md    # Ingest knowledge"
echo "  bun memory distill            # Extract patterns"
echo "  bun memory status             # Health check"
echo "  bun memory graph              # Entity relationships"
echo ""
echo -e "${YELLOW}Hooks will call these automatically via Pulse pipeline.${NC}"
echo ""
