#!/bin/bash
# Soul Restore - Recover from chaos
# Restores soul files from a tagged version
#
# Usage: ./soul-restore.sh <tag-name>
# Example: ./soul-restore.sh soul-v2.3

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
cd "$PROJECT_ROOT"

TAG_NAME="${1:-}"

if [ -z "$TAG_NAME" ]; then
    echo "Usage: ./soul-restore.sh <tag-name>"
    echo ""
    echo "Available soul tags:"
    git tag -l "soul-*" --sort=-version:refname | head -10
    exit 1
fi

# Verify tag exists
if ! git rev-parse "$TAG_NAME" >/dev/null 2>&1; then
    echo "Error: Tag '$TAG_NAME' not found."
    echo ""
    echo "Available soul tags:"
    git tag -l "soul-*" --sort=-version:refname | head -10
    exit 1
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}    Soul Restore: $TAG_NAME${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Show what will be restored
echo -e "${YELLOW}This will restore the following files from $TAG_NAME:${NC}"
echo ""

# Soul files to restore
SOUL_FILES=(
    # The Bible
    "psi/The_Source/BIBLE.md"
    # Agent Identities
    ".claude/agents/oracle-keeper.md"
    ".claude/agents/neo.md"
    ".claude/agents/trinity.md"
    ".claude/agents/morpheus.md"
    ".claude/agents/architect.md"
    ".claude/agents/agent-smith.md"
    ".claude/agents/tank.md"
    ".claude/agents/scribe.md"
    # Voice System
    "psi/matrix/voice.sh"
    "psi/matrix/voice_server.py"
    ".claude/hooks/matrix-dispatch.sh"
    ".claude/hooks/play-tts.sh"
    # Config
    ".claude/config/voices.json"
    # Philosophy
    "CLAUDE.md"
)

for file in "${SOUL_FILES[@]}"; do
    # Check if file exists in the tag
    if git show "$TAG_NAME:$file" >/dev/null 2>&1; then
        echo "   $file"
    fi
done

echo ""
echo -e "${RED}WARNING: Current versions of these files will be OVERWRITTEN.${NC}"
echo -e "${YELLOW}Current state will be backed up to branch: backup-before-restore-$(date +%Y%m%d-%H%M%S)${NC}"
echo ""
read -p "Proceed with restore? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Restore cancelled."
    exit 0
fi

# Create backup branch
BACKUP_BRANCH="backup-before-restore-$(date +%Y%m%d-%H%M%S)"
echo ""
echo -e "${BLUE}Creating backup branch: $BACKUP_BRANCH${NC}"
git branch "$BACKUP_BRANCH"

# Restore each file
echo ""
echo -e "${BLUE}Restoring files...${NC}"

RESTORED=0
FAILED=0

for file in "${SOUL_FILES[@]}"; do
    if git show "$TAG_NAME:$file" >/dev/null 2>&1; then
        # Ensure directory exists
        mkdir -p "$(dirname "$file")"
        # Restore file from tag
        git show "$TAG_NAME:$file" > "$file"
        echo -e "${GREEN}   Restored: $file${NC}"
        ((RESTORED++))
    else
        echo -e "${YELLOW}   Skipped (not in tag): $file${NC}"
    fi
done

# Also restore music files if they exist in the tag
MUSIC_DIR=".claude/audio/tracks"
if git ls-tree -r "$TAG_NAME" --name-only | grep -q "^$MUSIC_DIR/"; then
    echo ""
    echo -e "${BLUE}Restoring music files...${NC}"
    mkdir -p "$MUSIC_DIR"
    for music_file in $(git ls-tree -r "$TAG_NAME" --name-only | grep "^$MUSIC_DIR/"); do
        git show "$TAG_NAME:$music_file" > "$music_file" 2>/dev/null || true
        echo -e "${GREEN}   Restored: $music_file${NC}"
    done
fi

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}   Soul Restored from: $TAG_NAME${NC}"
echo -e "${GREEN}   Files restored: $RESTORED${NC}"
echo -e "${GREEN}   Backup branch: $BACKUP_BRANCH${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo "Next steps:"
echo "   1. Run ./psi/matrix/soul/integrity.sh to verify"
echo "   2. If satisfied, commit: git add -A && git commit -m 'chore(soul): Restored from $TAG_NAME'"
echo "   3. If not satisfied, restore backup: git checkout $BACKUP_BRANCH -- ."
echo ""

# Voice model reminder
echo -e "${YELLOW}Note: Voice models (.onnx) are not in git.${NC}"
echo "If voices are missing, re-download them with piper or AgentVibes."
echo ""
