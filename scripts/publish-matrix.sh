#!/bin/bash
# publish-matrix.sh - One command to publish updates to matrix-seed and matrix-reloaded
#
# Usage:
#   ./scripts/publish-matrix.sh              # Publish both
#   ./scripts/publish-matrix.sh seed         # Publish seed only
#   ./scripts/publish-matrix.sh reloaded     # Publish reloaded only
#   ./scripts/publish-matrix.sh --dry-run    # Show what would happen
#
# This script:
# 1. Extracts from The-Oracle-Construct to target repos
# 2. Commits changes with sync message
# 3. Pushes to GitHub

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$(dirname "$SCRIPT_DIR")"
SEED_REPO="${MATRIX_SEED_PATH:-$HOME/workspace/matrix-seed}"
RELOADED_REPO="${MATRIX_RELOADED_PATH:-$HOME/workspace/matrix-reloaded}"
ORIGIN_COMMIT=$(git -C "$SOURCE_DIR" rev-parse --short HEAD)
ORIGIN_DATE=$(date +"%Y-%m-%d")

# Parse arguments
DRY_RUN=false
PUBLISH_SEED=true
PUBLISH_RELOADED=true

for arg in "$@"; do
    case $arg in
        --dry-run)
            DRY_RUN=true
            ;;
        seed)
            PUBLISH_RELOADED=false
            ;;
        reloaded)
            PUBLISH_SEED=false
            ;;
        --help|-h)
            echo "Usage: publish-matrix.sh [seed|reloaded] [--dry-run]"
            echo ""
            echo "Options:"
            echo "  seed       Publish matrix-seed only"
            echo "  reloaded   Publish matrix-reloaded only"
            echo "  --dry-run  Show what would happen without executing"
            echo ""
            echo "Environment variables:"
            echo "  MATRIX_SEED_PATH     Path to matrix-seed repo (default: ~/workspace/matrix-seed)"
            echo "  MATRIX_RELOADED_PATH Path to matrix-reloaded repo (default: ~/workspace/matrix-reloaded)"
            exit 0
            ;;
    esac
done

echo -e "${MAGENTA}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║    📤 MATRIX PUBLISHING PIPELINE                         ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo "Source: $SOURCE_DIR @ $ORIGIN_COMMIT"
echo "Date: $ORIGIN_DATE"
echo ""

if $DRY_RUN; then
    echo -e "${YELLOW}[DRY RUN] No changes will be made${NC}"
    echo ""
fi

# Check for uncommitted changes in source
if [[ -n $(git -C "$SOURCE_DIR" status --porcelain) ]]; then
    echo -e "${YELLOW}Warning: The-Oracle-Construct has uncommitted changes${NC}"
    echo "Consider committing before publishing."
    echo ""
    read -p "Continue anyway? [y/N] " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
fi

# ============================================
# Publish Seed
# ============================================
if $PUBLISH_SEED; then
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}🌱 Publishing matrix-seed${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    if [[ ! -d "$SEED_REPO" ]]; then
        echo -e "${RED}Error: Seed repo not found at $SEED_REPO${NC}"
        echo "Clone it first: git clone https://github.com/Jarkius/matrix-seed.git $SEED_REPO"
        exit 1
    fi

    if $DRY_RUN; then
        echo "[DRY RUN] Would extract to $SEED_REPO"
        echo "[DRY RUN] Would commit and push"
    else
        # Extract
        echo "Extracting..."
        "$SCRIPT_DIR/extract-seed.sh" "$SEED_REPO"

        # Check if there are changes
        cd "$SEED_REPO"
        if [[ -z $(git status --porcelain) ]]; then
            echo -e "${YELLOW}No changes to publish for matrix-seed${NC}"
        else
            # Commit
            echo ""
            echo "Committing..."
            git add -A
            git commit -m "sync: Update from The-Oracle-Construct @ $ORIGIN_COMMIT

Synchronized on $ORIGIN_DATE

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"

            # Push
            echo "Pushing..."
            git push origin main

            echo -e "${GREEN}✓ matrix-seed published${NC}"
        fi
        cd "$SOURCE_DIR"
    fi
    echo ""
fi

# ============================================
# Publish Reloaded
# ============================================
if $PUBLISH_RELOADED; then
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}🔴 Publishing matrix-reloaded${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    if [[ ! -d "$RELOADED_REPO" ]]; then
        echo -e "${RED}Error: Reloaded repo not found at $RELOADED_REPO${NC}"
        echo "Clone it first: git clone https://github.com/Jarkius/matrix-reloaded.git $RELOADED_REPO"
        exit 1
    fi

    if $DRY_RUN; then
        echo "[DRY RUN] Would extract to $RELOADED_REPO"
        echo "[DRY RUN] Would commit and push"
    else
        # Extract
        echo "Extracting..."
        "$SCRIPT_DIR/extract-reloaded.sh" "$RELOADED_REPO"

        # Check if there are changes
        cd "$RELOADED_REPO"
        if [[ -z $(git status --porcelain) ]]; then
            echo -e "${YELLOW}No changes to publish for matrix-reloaded${NC}"
        else
            # Commit
            echo ""
            echo "Committing..."
            git add -A
            git commit -m "sync: Update from The-Oracle-Construct @ $ORIGIN_COMMIT

Synchronized on $ORIGIN_DATE

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"

            # Push
            echo "Pushing..."
            git push origin main

            echo -e "${GREEN}✓ matrix-reloaded published${NC}"
        fi
        cd "$SOURCE_DIR"
    fi
    echo ""
fi

# ============================================
# Summary
# ============================================
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ PUBLISHING COMPLETE                                   ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

if $PUBLISH_SEED; then
    echo "matrix-seed:    https://github.com/Jarkius/matrix-seed"
fi
if $PUBLISH_RELOADED; then
    echo "matrix-reloaded: https://github.com/Jarkius/matrix-reloaded"
fi
echo ""
echo "Origin: The-Oracle-Construct @ $ORIGIN_COMMIT"
