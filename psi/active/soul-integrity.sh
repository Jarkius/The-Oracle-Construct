#!/bin/bash
# Soul Integrity Check - The Garden's Witness
# Uses BIBLE.md as the source of truth for what constitutes the Matrix Core
#
# Usage: ./soul-integrity.sh [--verbose]
#
# Checks:
# 1. BIBLE.md exists and records its last modification
# 2. All Matrix Core files exist (as defined in BIBLE.md Part VII)
# 3. Compares against SOUL_MANIFEST.sha256 if it exists (checksums)
# 4. Reports drift since last tagged soul version

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

VERBOSE="${1:-}"
ERRORS=0
WARNINGS=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}    Soul Integrity Check${NC}"
echo -e "${BLUE}    The Garden's Witness${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# ============================================
# TIER 0: THE BIBLE (Anchor of Truth)
# ============================================
echo -e "${BLUE}## The Bible (Anchor of Truth)${NC}"

BIBLE_PATH="psi/The_Source/BIBLE.md"
if [ -f "$BIBLE_PATH" ]; then
    BIBLE_MODIFIED=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$BIBLE_PATH" 2>/dev/null || stat -c "%y" "$BIBLE_PATH" 2>/dev/null | cut -d'.' -f1)
    BIBLE_HASH=$(shasum -a 256 "$BIBLE_PATH" | cut -d' ' -f1 | head -c 12)
    echo -e "${GREEN}   BIBLE.md${NC}"
    echo -e "   Last Modified: ${BIBLE_MODIFIED}"
    echo -e "   Hash: ${BIBLE_HASH}..."
else
    echo -e "${RED}   BIBLE.md - MISSING (CRITICAL)${NC}"
    ((ERRORS++))
fi
echo ""

# ============================================
# TIER 1: THE SOUL (Agent Identities)
# ============================================
echo -e "${BLUE}## Tier 1: The Soul (Agent Identities)${NC}"

SOUL_FILES=(
    ".claude/agents/oracle-keeper.md"
    ".claude/agents/neo.md"
    ".claude/agents/trinity.md"
    ".claude/agents/morpheus.md"
    ".claude/agents/architect.md"
    ".claude/agents/agent-smith.md"
    ".claude/agents/tank.md"
    ".claude/agents/scribe.md"
)

for file in "${SOUL_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}   $file${NC}"
    else
        echo -e "${RED}   $file - MISSING${NC}"
        ((ERRORS++))
    fi
done
echo ""

# ============================================
# TIER 2: THE VOICE (How We Speak)
# ============================================
echo -e "${BLUE}## Tier 2: The Voice (How We Speak)${NC}"

VOICE_FILES=(
    "psi/active/voice_module.sh"
    "psi/active/voice_server.py"
    ".claude/hooks/matrix-dispatch.sh"
    ".claude/hooks/play-tts.sh"
)

# Voice Identity (Config)
VOICE_CONFIG_FILES=(
    ".claude/config/voices.json"
)

for file in "${VOICE_CONFIG_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}   $file${NC}"
    else
        echo -e "${YELLOW}   $file - Not found${NC}"
        ((WARNINGS++))
    fi
done

# Music & Effects
echo -e "${BLUE}## Voice Identity: Music & Effects${NC}"
MUSIC_DIR=".claude/audio/tracks"
if [ -d "$MUSIC_DIR" ]; then
    MUSIC_COUNT=$(find "$MUSIC_DIR" -type f \( -name "*.mp3" -o -name "*.wav" \) 2>/dev/null | wc -l | tr -d ' ')
    echo -e "${GREEN}   $MUSIC_DIR: $MUSIC_COUNT audio files${NC}"
else
    echo -e "${YELLOW}   $MUSIC_DIR - Not found${NC}"
    ((WARNINGS++))
fi

SFX_DIR=".claude/audio/sfx"
if [ -d "$SFX_DIR" ]; then
    SFX_COUNT=$(find "$SFX_DIR" -type f \( -name "*.mp3" -o -name "*.wav" \) 2>/dev/null | wc -l | tr -d ' ')
    echo -e "${GREEN}   $SFX_DIR: $SFX_COUNT effect files${NC}"
else
    echo -e "${YELLOW}   $SFX_DIR - Not found (optional)${NC}"
fi
echo ""

# Voice Models (Piper .onnx files)
echo -e "${BLUE}## Voice Models (Agent Voices)${NC}"
PIPER_VOICE_DIR="$HOME/.claude/piper-voices"

# Required voice models for each agent (from voice_module.sh)
# Format: "Agent:voice_file"
AGENT_VOICE_LIST=(
    "Neo:en_US-ryan-high.onnx"
    "Trinity:jenny.onnx"
    "Morpheus:en_US-carlin-high.onnx"
    "Oracle:en_US-kristin-medium.onnx"
    "Smith:en_US-danny-low.onnx"
    "Architect:en_GB-alan-medium.onnx"
    "Tank:en_US-bryce-medium.onnx"
    "Scribe:en_US-lessac-medium.onnx"
    "Mainframe:en_US-norman-medium.onnx"
    "System:en_US-hfc_male-medium.onnx"
)

MISSING_VOICES=0
for entry in "${AGENT_VOICE_LIST[@]}"; do
    agent="${entry%%:*}"
    voice_file="${entry##*:}"
    voice_path="$PIPER_VOICE_DIR/$voice_file"
    if [ -f "$voice_path" ]; then
        echo -e "${GREEN}   $agent: $voice_file${NC}"
    else
        echo -e "${RED}   $agent: $voice_file - MISSING${NC}"
        ((MISSING_VOICES++))
        ((ERRORS++))
    fi
done

if [ $MISSING_VOICES -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}   To download missing voices, run:${NC}"
    echo -e "${YELLOW}   piper --download-dir $PIPER_VOICE_DIR --model <model-name>${NC}"
fi
echo ""

echo -e "${BLUE}## Voice System Scripts${NC}"

for file in "${VOICE_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}   $file${NC}"
    else
        echo -e "${RED}   $file - MISSING${NC}"
        ((ERRORS++))
    fi
done

# Check voice server running
if pgrep -f "voice_server.py" > /dev/null 2>&1; then
    echo -e "${GREEN}   Voice Server: Running${NC}"
else
    echo -e "${YELLOW}   Voice Server: Not running${NC}"
    ((WARNINGS++))
fi
echo ""

# ============================================
# TIER 3: THE PHILOSOPHY (The Source)
# ============================================
echo -e "${BLUE}## Tier 3: The Philosophy (The Source)${NC}"

SOURCE_FILES=(
    "psi/The_Source/BIBLE.md"
    "psi/The_Source/01_self_knowledge.md"
    "psi/The_Source/02_bilateral_collaboration.md"
    "psi/The_Source/03_multi_agent.md"
    "CLAUDE.md"
)

for file in "${SOURCE_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}   $file${NC}"
    else
        echo -e "${YELLOW}   $file - Not found (optional)${NC}"
        ((WARNINGS++))
    fi
done
echo ""

# ============================================
# CHECKSUM VERIFICATION (If manifest exists)
# ============================================
MANIFEST_PATH="psi/The_Source/SOUL_MANIFEST.sha256"
if [ -f "$MANIFEST_PATH" ]; then
    echo -e "${BLUE}## Checksum Verification${NC}"

    DRIFT_COUNT=0
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^#.*$ ]] && continue
        [[ -z "$line" ]] && continue

        EXPECTED_HASH=$(echo "$line" | awk '{print $1}')
        FILE_PATH=$(echo "$line" | awk '{print $2}')

        if [ -f "$FILE_PATH" ]; then
            ACTUAL_HASH=$(shasum -a 256 "$FILE_PATH" | cut -d' ' -f1)
            if [ "$EXPECTED_HASH" = "$ACTUAL_HASH" ]; then
                [ -n "$VERBOSE" ] && echo -e "${GREEN}   $FILE_PATH - Unchanged${NC}"
            else
                echo -e "${YELLOW}   $FILE_PATH - DRIFTED${NC}"
                ((DRIFT_COUNT++))
            fi
        else
            echo -e "${RED}   $FILE_PATH - Missing${NC}"
            ((DRIFT_COUNT++))
        fi
    done < "$MANIFEST_PATH"

    if [ $DRIFT_COUNT -eq 0 ]; then
        echo -e "${GREEN}   All checksums match manifest${NC}"
    else
        echo -e "${YELLOW}   $DRIFT_COUNT file(s) changed since last soul-tag${NC}"
        ((WARNINGS++))
    fi
    echo ""
else
    echo -e "${YELLOW}## No SOUL_MANIFEST.sha256 found${NC}"
    echo -e "   Run: ./psi/active/soul-tag.sh <version> to create initial manifest"
    echo ""
fi

# ============================================
# GIT STATUS (Uncommitted changes)
# ============================================
echo -e "${BLUE}## Git Status${NC}"

UNCOMMITTED=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
if [ "$UNCOMMITTED" -gt 0 ]; then
    echo -e "${YELLOW}   $UNCOMMITTED uncommitted change(s)${NC}"
    ((WARNINGS++))
else
    echo -e "${GREEN}   Working tree clean${NC}"
fi

# Last soul tag
LAST_SOUL_TAG=$(git tag -l "soul-*" --sort=-version:refname 2>/dev/null | head -1)
if [ -n "$LAST_SOUL_TAG" ]; then
    TAG_DATE=$(git log -1 --format="%ai" "$LAST_SOUL_TAG" 2>/dev/null | cut -d' ' -f1)
    echo -e "   Last Soul Tag: ${LAST_SOUL_TAG} (${TAG_DATE})"
else
    echo -e "${YELLOW}   No soul tags found. Run soul-tag.sh to create one.${NC}"
fi
echo ""

# ============================================
# SUMMARY
# ============================================
echo -e "${BLUE}============================================${NC}"
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}   SOUL INTACT${NC}"
    echo -e "${GREEN}   The Garden is healthy.${NC}"
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}   SOUL STABLE (with $WARNINGS warning(s))${NC}"
    echo -e "${YELLOW}   Minor drift detected. Review if needed.${NC}"
else
    echo -e "${RED}   SOUL COMPROMISED${NC}"
    echo -e "${RED}   $ERRORS critical issue(s) found.${NC}"
fi
echo -e "${BLUE}============================================${NC}"
echo ""

exit $ERRORS
