#!/bin/bash
# Soul Integrity Check - The Garden's Witness
#
# DYNAMIC: Reads MATRIX_CORE.md to discover what to check
# No hardcoded file lists - the Bible is the source of truth
#
# Usage: ./soul-integrity.sh [--verbose]
#
# Checks:
# 1. BIBLE.md exists (the anchor)
# 2. MATRIX_CORE.md exists and is parsed for file lists
# 3. All files defined in MATRIX_CORE.md exist
# 4. Voice models exist (system-level check)
# 5. Compares against SOUL_MANIFEST.sha256 if it exists (checksums)
# 6. Reports drift since last tagged soul version

set -euo pipefail

# Resolve symlinks to get the actual script location
SCRIPT_PATH="${BASH_SOURCE[0]}"
while [ -L "$SCRIPT_PATH" ]; do
    SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
    SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"
    [[ "$SCRIPT_PATH" != /* ]] && SCRIPT_PATH="$SCRIPT_DIR/$SCRIPT_PATH"
done
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
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
echo -e "${BLUE}## Tier 0: The Bible (Anchor of Truth)${NC}"

BIBLE_PATH="psi/The_Source/BIBLE.md"
if [ -f "$BIBLE_PATH" ]; then
    BIBLE_MODIFIED=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$BIBLE_PATH" 2>/dev/null || stat -c "%y" "$BIBLE_PATH" 2>/dev/null | cut -d'.' -f1)
    BIBLE_HASH=$(shasum -a 256 "$BIBLE_PATH" | cut -d' ' -f1 | head -c 12)
    echo -e "${GREEN}   ✓ BIBLE.md${NC}"
    echo -e "   Last Modified: ${BIBLE_MODIFIED}"
    echo -e "   Hash: ${BIBLE_HASH}..."
else
    echo -e "${RED}   ✗ BIBLE.md - MISSING (CRITICAL)${NC}"
    ((ERRORS++))
fi
echo ""

# ============================================
# TIER 1: MATRIX_CORE.md (Dynamic Discovery)
# ============================================
echo -e "${BLUE}## Tier 1: Matrix Core (Dynamic Discovery)${NC}"

MATRIX_CORE_PATH="psi/The_Source/MATRIX_CORE.md"
if [ ! -f "$MATRIX_CORE_PATH" ]; then
    echo -e "${RED}   ✗ MATRIX_CORE.md - MISSING (CRITICAL)${NC}"
    echo -e "${RED}   Cannot discover what to check!${NC}"
    ((ERRORS++))
    echo ""
else
    echo -e "${GREEN}   ✓ MATRIX_CORE.md (source of truth)${NC}"
    echo ""

    # Parse MATRIX_CORE.md for file paths
    # Extract lines that start with | ` (table rows with file paths)
    echo -e "${BLUE}## Checking files defined in MATRIX_CORE.md${NC}"

    # Extract file paths from markdown tables
    # Pattern: | `path/to/file` | or | `path/*.md` |
    FILES_TO_CHECK=$(grep -oE '\| `[^`]+`' "$MATRIX_CORE_PATH" | sed 's/| `//g' | sed 's/`//g' | sort -u)

    CHECKED=0
    FOUND=0
    MISSING_LIST=""

    while IFS= read -r file_pattern; do
        # Skip empty lines
        [[ -z "$file_pattern" ]] && continue

        # Skip non-path entries (like "YES", "Optional", etc.)
        [[ ! "$file_pattern" =~ ^[./] ]] && [[ ! "$file_pattern" =~ ^[a-zA-Z] ]] && continue
        [[ "$file_pattern" =~ ^(YES|Yes|Optional|Recommended|Critical)$ ]] && continue

        # Handle glob patterns (e.g., .claude/agents/*.md)
        if [[ "$file_pattern" == *"*"* ]]; then
            # Count matching files
            MATCH_COUNT=$(find . -path "./$file_pattern" 2>/dev/null | wc -l | tr -d ' ')
            if [ "$MATCH_COUNT" -gt 0 ]; then
                [ -n "$VERBOSE" ] && echo -e "${GREEN}   ✓ $file_pattern ($MATCH_COUNT files)${NC}"
                ((FOUND++))
            else
                echo -e "${YELLOW}   ⚠ $file_pattern (no matches)${NC}"
                ((WARNINGS++))
            fi
        else
            # Direct file check
            if [ -f "$file_pattern" ] || [ -d "$file_pattern" ]; then
                [ -n "$VERBOSE" ] && echo -e "${GREEN}   ✓ $file_pattern${NC}"
                ((FOUND++))
            else
                # Check if it's a critical file (based on context)
                if [[ "$file_pattern" =~ BIBLE|MATRIX_CORE|CLAUDE\.md|voices\.json|oracle\.md ]]; then
                    echo -e "${RED}   ✗ $file_pattern - MISSING (CRITICAL)${NC}"
                    ((ERRORS++))
                else
                    echo -e "${YELLOW}   ⚠ $file_pattern - Not found${NC}"
                    ((WARNINGS++))
                fi
                MISSING_LIST="$MISSING_LIST\n   - $file_pattern"
            fi
        fi
        ((CHECKED++))
    done <<< "$FILES_TO_CHECK"

    echo ""
    echo -e "   Checked: $CHECKED paths, Found: $FOUND, Issues: $((ERRORS + WARNINGS))"
fi
echo ""

# ============================================
# TIER 2: VOICE MODELS (System-Level)
# ============================================
echo -e "${BLUE}## Tier 2: Voice Models (System-Level)${NC}"

PIPER_VOICE_DIR="$HOME/.claude/piper-voices"

# Read voice assignments from voices.json if it exists
VOICES_JSON=".claude/config/voices.json"
if [ -f "$VOICES_JSON" ]; then
    # Extract model names from voices.json
    VOICE_MODELS=$(grep -oE '"model":\s*"[^"]+"' "$VOICES_JSON" | sed 's/"model":\s*"//g' | sed 's/"//g' | sort -u)

    MISSING_VOICES=0
    while IFS= read -r model; do
        [[ -z "$model" ]] && continue

        # Add .onnx if not present
        [[ "$model" != *.onnx ]] && model="${model}.onnx"

        voice_path="$PIPER_VOICE_DIR/$model"
        if [ -f "$voice_path" ]; then
            [ -n "$VERBOSE" ] && echo -e "${GREEN}   ✓ $model${NC}"
        else
            echo -e "${RED}   ✗ $model - MISSING${NC}"
            ((MISSING_VOICES++))
            ((ERRORS++))
        fi
    done <<< "$VOICE_MODELS"

    if [ $MISSING_VOICES -eq 0 ]; then
        echo -e "${GREEN}   All voice models present${NC}"
    else
        echo ""
        echo -e "${YELLOW}   To download missing voices, run:${NC}"
        echo -e "${YELLOW}   piper --download-dir $PIPER_VOICE_DIR --model <model-name>${NC}"
    fi
else
    echo -e "${YELLOW}   ⚠ voices.json not found - cannot verify voice models${NC}"
    ((WARNINGS++))
fi
echo ""

# ============================================
# TIER 3: VOICE SERVER (Runtime Check)
# ============================================
echo -e "${BLUE}## Tier 3: Voice Server (Runtime)${NC}"

if lsof -i :6969 > /dev/null 2>&1; then
    echo -e "${GREEN}   ✓ Voice Server: Running (port 6969)${NC}"
else
    echo -e "${YELLOW}   ⚠ Voice Server: Not running${NC}"
    ((WARNINGS++))
fi
echo ""

# ============================================
# CHECKSUM VERIFICATION (If manifest exists)
# ============================================
MANIFEST_PATH="psi/The_Source/SOUL_MANIFEST.sha256"
if [ -f "$MANIFEST_PATH" ]; then
    echo -e "${BLUE}## Checksum Verification (Drift Detection)${NC}"

    MANIFEST_DATE=$(stat -f "%Sm" -t "%Y-%m-%d" "$MANIFEST_PATH" 2>/dev/null || stat -c "%y" "$MANIFEST_PATH" 2>/dev/null | cut -d' ' -f1)
    echo -e "   Manifest from: ${MANIFEST_DATE}"

    DRIFT_COUNT=0
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^#.*$ ]] && continue
        [[ -z "$line" ]] && continue

        EXPECTED_HASH=$(echo "$line" | awk '{print $1}')
        FILE_PATH=$(echo "$line" | awk '{print $2}')

        if [ -f "$FILE_PATH" ]; then
            # Skip checksum for large binary files (mp3, onnx) - just verify existence
            if [[ "$FILE_PATH" =~ \.(mp3|onnx|wav)$ ]]; then
                [ -n "$VERBOSE" ] && echo -e "${GREEN}   ✓ $FILE_PATH - Exists (skipped checksum)${NC}"
            else
                ACTUAL_HASH=$(shasum -a 256 "$FILE_PATH" | cut -d' ' -f1)
                if [ "$EXPECTED_HASH" = "$ACTUAL_HASH" ]; then
                    [ -n "$VERBOSE" ] && echo -e "${GREEN}   ✓ $FILE_PATH - Unchanged${NC}"
                else
                    echo -e "${YELLOW}   ⚠ $FILE_PATH - DRIFTED${NC}"
                    ((DRIFT_COUNT++))
                fi
            fi
        else
            echo -e "${RED}   ✗ $FILE_PATH - Missing${NC}"
            ((DRIFT_COUNT++))
        fi
    done < "$MANIFEST_PATH"

    if [ $DRIFT_COUNT -eq 0 ]; then
        echo -e "${GREEN}   All checksums match manifest${NC}"
    else
        echo -e "${YELLOW}   $DRIFT_COUNT file(s) changed since last soul-tag${NC}"
        echo -e "${YELLOW}   Consider: ./psi/active/soul-tag.sh <version> to update manifest${NC}"
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
    echo -e "${YELLOW}   ⚠ $UNCOMMITTED uncommitted change(s)${NC}"
    ((WARNINGS++))
else
    echo -e "${GREEN}   ✓ Working tree clean${NC}"
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
