#!/bin/bash
# Soul Tag - Mark a stable milestone
# Creates a git tag and checksum manifest for the current soul state
#
# Usage: ./soul-tag.sh <version> [description]
# Example: ./soul-tag.sh v2.4 "Added Tank alias, refined dispatch"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
cd "$PROJECT_ROOT"

VERSION="${1:-}"
DESCRIPTION="${2:-Soul milestone}"

if [ -z "$VERSION" ]; then
    echo "Usage: ./soul-tag.sh <version> [description]"
    echo "Example: ./soul-tag.sh v2.4 \"Added Tank alias\""
    exit 1
fi

TAG_NAME="soul-$VERSION"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}    Soul Tag: $TAG_NAME${NC}"
echo -e "${BLUE}    \"$DESCRIPTION\"${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Check for uncommitted changes
UNCOMMITTED=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
if [ "$UNCOMMITTED" -gt 0 ]; then
    echo -e "${YELLOW}Warning: $UNCOMMITTED uncommitted changes.${NC}"
    echo "Commit changes before tagging? (y/n)"
    read -r RESPONSE
    if [ "$RESPONSE" = "y" ]; then
        git add -A
        git commit -m "chore(soul): Prepare for $TAG_NAME - $DESCRIPTION"
    fi
fi

# Define soul files to checksum (must match soul-integrity.sh)
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
    "psi/The_Source/01_self_knowledge.md"
    "psi/The_Source/02_bilateral_collaboration.md"
    "psi/The_Source/04_multi_agent.md"
)

# Create checksum manifest
MANIFEST_PATH="psi/The_Source/SOUL_MANIFEST.sha256"
echo "# Soul Manifest - $TAG_NAME" > "$MANIFEST_PATH"
echo "# Generated: $(date -u +"%Y-%m-%d %H:%M:%S UTC")" >> "$MANIFEST_PATH"
echo "# Description: $DESCRIPTION" >> "$MANIFEST_PATH"
echo "#" >> "$MANIFEST_PATH"

echo -e "${BLUE}Generating checksums...${NC}"
for file in "${SOUL_FILES[@]}"; do
    if [ -f "$file" ]; then
        HASH=$(shasum -a 256 "$file")
        echo "$HASH" >> "$MANIFEST_PATH"
        echo -e "${GREEN}   $file${NC}"
    else
        echo -e "${YELLOW}   $file - Skipped (not found)${NC}"
    fi
done

# Also checksum music files (track count as integrity)
MUSIC_DIR=".claude/audio/tracks"
if [ -d "$MUSIC_DIR" ]; then
    echo "#" >> "$MANIFEST_PATH"
    echo "# Music tracks (existence check)" >> "$MANIFEST_PATH"
    find "$MUSIC_DIR" -type f \( -name "*.mp3" -o -name "*.wav" \) -exec shasum -a 256 {} \; >> "$MANIFEST_PATH" 2>/dev/null || true
fi

# Commit the manifest
git add "$MANIFEST_PATH"
git commit -m "chore(soul): Update manifest for $TAG_NAME" 2>/dev/null || true

# Create the git tag
echo ""
echo -e "${BLUE}Creating git tag: $TAG_NAME${NC}"
git tag -a "$TAG_NAME" -m "$DESCRIPTION"

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}   Soul Tagged: $TAG_NAME${NC}"
echo -e "${GREEN}   Manifest: $MANIFEST_PATH${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo "To push this tag to remote:"
echo "   git push origin $TAG_NAME"
echo ""
echo "To restore to this state later:"
echo "   ./psi/matrix/soul/restore.sh $TAG_NAME"
echo ""
