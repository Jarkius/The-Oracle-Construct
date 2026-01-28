#!/bin/bash
# ============================================================
# matrix-doctor.sh - Self-Healing Health System
# ============================================================
#
# PURPOSE:
#   Detect issues AND attempt to fix them automatically.
#   Only escalate to human if auto-fix fails.
#
# USAGE:
#   ./matrix-doctor.sh           # Auto-heal mode (default)
#   ./matrix-doctor.sh --check   # Diagnose only, no fixes
#   ./matrix-doctor.sh --verbose # Show all details
#
# HEALS:
#   - Missing voice models → Downloads them
#   - Voice server down → Starts it
#   - Missing dependencies → Suggests install commands
#   - Stale lock files → Removes them
#
# COMPATIBLE: bash 3.2+ (macOS default)
# ============================================================

set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

# Parse arguments
CHECK_ONLY=false
VERBOSE=false
for arg in "$@"; do
    case $arg in
        --check) CHECK_ONLY=true ;;
        --verbose) VERBOSE=true ;;
    esac
done

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Counters
ISSUES_FOUND=0
ISSUES_FIXED=0
ISSUES_FAILED=0

log_check() { echo -e "${BLUE}[CHECK]${NC} $1"; }
log_issue() { echo -e "${YELLOW}[ISSUE]${NC} $1"; ISSUES_FOUND=$((ISSUES_FOUND + 1)); }
log_fix() { echo -e "${GREEN}[FIXED]${NC} $1"; ISSUES_FIXED=$((ISSUES_FIXED + 1)); }
log_fail() { echo -e "${RED}[FAILED]${NC} $1"; ISSUES_FAILED=$((ISSUES_FAILED + 1)); }
log_ok() { echo -e "${GREEN}[OK]${NC} $1"; }
log_skip() { echo -e "${CYAN}[SKIP]${NC} $1"; }

echo ""
echo -e "${MAGENTA}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║           MATRIX DOCTOR - Self-Healing System             ║${NC}"
echo -e "${MAGENTA}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

if $CHECK_ONLY; then
    echo -e "${YELLOW}Mode: Diagnose only (--check)${NC}"
else
    echo -e "${GREEN}Mode: Auto-heal enabled${NC}"
fi
echo ""

# ============================================================
# Helper: Download voice model
# ============================================================
download_voice() {
    local model="$1"
    local url_path="$2"
    local agent="$3"
    local voice_dir="$HOME/.claude/piper-voices"

    if [[ -f "$voice_dir/${model}.onnx" ]]; then
        $VERBOSE && log_ok "$agent ($model)"
        return 0
    fi

    log_issue "$agent voice missing: $model"

    if ! $CHECK_ONLY; then
        echo -n "       Downloading... "
        if curl -sL "https://huggingface.co/rhasspy/piper-voices/resolve/main/${url_path}/${model}.onnx" \
            -o "$voice_dir/${model}.onnx" 2>/dev/null && \
           curl -sL "https://huggingface.co/rhasspy/piper-voices/resolve/main/${url_path}/${model}.onnx.json" \
            -o "$voice_dir/${model}.onnx.json" 2>/dev/null; then
            log_fix "Downloaded $model"
            return 0
        else
            log_fail "Could not download $model"
            rm -f "$voice_dir/${model}.onnx" "$voice_dir/${model}.onnx.json" 2>/dev/null
            return 1
        fi
    fi
    return 1
}

# ============================================================
# 1. VOICE MODELS CHECK & HEAL
# ============================================================
echo -e "${BLUE}━━━ Voice Models ━━━${NC}"

VOICE_DIR="$HOME/.claude/piper-voices"
mkdir -p "$VOICE_DIR"

# Check each voice model (bash 3.2 compatible)
download_voice "en_US-kristin-medium" "en/en_US/kristin/medium" "Oracle"
download_voice "en_US-ryan-high" "en/en_US/ryan/high" "Neo"
download_voice "en_US-bryce-medium" "en/en_US/bryce/medium" "Tank"
download_voice "en_US-danny-low" "en/en_US/danny/low" "Smith"
download_voice "en_GB-alan-medium" "en/en_GB/alan/medium" "Architect"
download_voice "en_US-hfc_male-medium" "en/en_US/hfc_male/medium" "System"
download_voice "en_US-lessac-medium" "en/en_US/lessac/medium" "Scribe"
download_voice "en_US-norman-medium" "en/en_US/norman/medium" "Mainframe"

# Jenny (Trinity) - special case with different naming
if [[ -f "$VOICE_DIR/jenny.onnx" ]]; then
    $VERBOSE && log_ok "Trinity (jenny)"
else
    log_issue "Trinity voice missing: jenny"

    if ! $CHECK_ONLY; then
        echo -n "       Downloading... "
        if curl -sL "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_GB/jenny_dioco/medium/en_GB-jenny_dioco-medium.onnx" \
            -o "$VOICE_DIR/jenny.onnx" 2>/dev/null && \
           curl -sL "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_GB/jenny_dioco/medium/en_GB-jenny_dioco-medium.onnx.json" \
            -o "$VOICE_DIR/jenny.onnx.json" 2>/dev/null; then
            log_fix "Downloaded jenny"
        else
            log_fail "Could not download jenny"
        fi
    fi
fi

# Custom voices (info only)
if [[ ! -f "$VOICE_DIR/en_US-carlin-high.onnx" ]]; then
    $VERBOSE && log_skip "Morpheus (carlin-high) - custom voice, manual install"
fi
if [[ ! -f "$VOICE_DIR/en_US-trump-high.onnx" ]]; then
    $VERBOSE && log_skip "Trump - custom voice, manual install"
fi

echo ""

# ============================================================
# 2. PIPER BINARY CHECK
# ============================================================
echo -e "${BLUE}━━━ Piper TTS ━━━${NC}"

PIPER_WORKS=false
if command -v piper &>/dev/null; then
    # Test if piper actually works
    if echo "test" | piper --model /dev/null 2>&1 | grep -q "Unable to find voice"; then
        PIPER_WORKS=true
        log_ok "Piper TTS operational"
    elif piper --help 2>&1 | grep -q "Library not loaded"; then
        log_issue "Piper has library errors"
        if ! $CHECK_ONLY; then
            echo "       Suggestion: Run .claude/hooks/bootstrap-voice.sh --force"
            ISSUES_FAILED=$((ISSUES_FAILED + 1))
        fi
    else
        # Piper exists but unclear state
        log_ok "Piper TTS found ($(which piper))"
    fi
else
    log_issue "Piper TTS not found"
    if ! $CHECK_ONLY; then
        echo "       Suggestion: Run ./teleport.sh or .claude/hooks/bootstrap-voice.sh"
        ISSUES_FAILED=$((ISSUES_FAILED + 1))
    fi
fi

echo ""

# ============================================================
# 3. VOICE SERVER CHECK & HEAL
# ============================================================
echo -e "${BLUE}━━━ Voice Server ━━━${NC}"

SERVER_PID=$(pgrep -f "voice_server.py" 2>/dev/null | head -1)
LOCK_FILE="/tmp/matrix_voice_server.lock"

# Check for stale lock
if [[ -f "$LOCK_FILE" ]]; then
    LOCK_PID=$(cat "$LOCK_FILE" 2>/dev/null)
    if ! kill -0 "$LOCK_PID" 2>/dev/null; then
        log_issue "Stale lock file found"
        if ! $CHECK_ONLY; then
            rm -f "$LOCK_FILE"
            log_fix "Removed stale lock"
        fi
    fi
fi

if [[ -n "$SERVER_PID" ]]; then
    log_ok "Voice server running (PID: $SERVER_PID)"
else
    log_issue "Voice server not running"

    if ! $CHECK_ONLY; then
        if [[ -f "$PROJECT_ROOT/psi/matrix/voice_server.py" ]]; then
            echo -n "       Starting server... "
            cd "$PROJECT_ROOT"
            nohup python3 psi/matrix/voice_server.py > /tmp/voice_server.log 2>&1 &
            sleep 1
            NEW_PID=$(pgrep -f "voice_server.py" 2>/dev/null | head -1)
            if [[ -n "$NEW_PID" ]]; then
                log_fix "Started (PID: $NEW_PID)"
            else
                log_fail "Could not start server"
                echo "       Check: cat /tmp/voice_server.log"
            fi
        else
            log_fail "voice_server.py not found"
        fi
    fi
fi

echo ""

# ============================================================
# 4. CORE FILES CHECK
# ============================================================
echo -e "${BLUE}━━━ Core Files ━━━${NC}"

check_file() {
    local filepath="$1"
    local desc="$2"

    if [[ -f "$PROJECT_ROOT/$filepath" ]]; then
        $VERBOSE && log_ok "$desc ($filepath)"
        return 0
    fi

    log_issue "$desc missing: $filepath"

    if ! $CHECK_ONLY; then
        # Attempt restore from git
        if git show HEAD:"$filepath" &>/dev/null; then
            echo -n "       Restoring from git... "
            mkdir -p "$(dirname "$PROJECT_ROOT/$filepath")"
            git show HEAD:"$filepath" > "$PROJECT_ROOT/$filepath"
            log_fix "Restored from HEAD"
            return 0
        else
            log_fail "Not in git, manual restore needed"
            return 1
        fi
    fi
    return 1
}

check_file "psi/matrix/voice.sh" "Voice client"
check_file "psi/matrix/voice_server.py" "Voice server"
check_file "CLAUDE.md" "AI DNA"
check_file ".claude/config/voices.json" "Voice config"

echo ""

# ============================================================
# 5. DEPENDENCIES CHECK
# ============================================================
echo -e "${BLUE}━━━ Dependencies ━━━${NC}"

check_dep() {
    local dep="$1"
    local install_cmd="$2"
    local purpose="$3"

    if command -v "$dep" &>/dev/null; then
        $VERBOSE && log_ok "$dep ($purpose)"
        return 0
    fi

    if [[ "$install_cmd" == "builtin" ]]; then
        log_issue "$dep missing (system builtin)"
        ISSUES_FAILED=$((ISSUES_FAILED + 1))
    else
        log_issue "$dep missing ($purpose)"
        if ! $CHECK_ONLY; then
            echo "       Install with: $install_cmd"
        fi
    fi
    return 1
}

check_dep "sox" "brew install sox" "Bass boost for Smith"
check_dep "ffmpeg" "brew install ffmpeg" "Audio mixing"
if [[ "$(uname)" == "Darwin" ]]; then
    check_dep "afplay" "builtin" "macOS audio player"
fi

echo ""

# ============================================================
# 6. SOUL INTEGRITY (Quick Check)
# ============================================================
echo -e "${BLUE}━━━ Soul Integrity ━━━${NC}"

BIBLE_PATH="psi/The_Source/BIBLE.md"
if [[ -f "$PROJECT_ROOT/$BIBLE_PATH" ]]; then
    log_ok "BIBLE.md present"
else
    log_issue "BIBLE.md missing (CRITICAL)"
    ISSUES_FAILED=$((ISSUES_FAILED + 1))
fi

# Count agents
AGENT_COUNT=$(ls -1 "$PROJECT_ROOT/.claude/agents/"*.md 2>/dev/null | wc -l | tr -d ' ')
if [[ "$AGENT_COUNT" -ge 8 ]]; then
    log_ok "Agent personalities: $AGENT_COUNT"
else
    log_issue "Only $AGENT_COUNT agents found (expected 8+)"
fi

# Check Source chapters
SOURCE_COUNT=$(ls -1 "$PROJECT_ROOT/psi/The_Source/"*.md 2>/dev/null | wc -l | tr -d ' ')
log_ok "Source chapters: $SOURCE_COUNT"

echo ""

# ============================================================
# SUMMARY
# ============================================================
echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [[ $ISSUES_FOUND -eq 0 ]]; then
    echo -e "${GREEN}✅ MATRIX HEALTHY - No issues found${NC}"
elif [[ $ISSUES_FAILED -eq 0 ]] && [[ $ISSUES_FIXED -gt 0 ]]; then
    echo -e "${GREEN}✅ MATRIX HEALED - All $ISSUES_FIXED issue(s) auto-fixed${NC}"
elif [[ $ISSUES_FAILED -gt 0 ]] && [[ $ISSUES_FIXED -gt 0 ]]; then
    echo -e "${YELLOW}⚠️  PARTIALLY HEALED - Fixed: $ISSUES_FIXED, Need attention: $ISSUES_FAILED${NC}"
elif $CHECK_ONLY && [[ $ISSUES_FOUND -gt 0 ]]; then
    echo -e "${YELLOW}⚠️  $ISSUES_FOUND issue(s) found (check-only mode)${NC}"
    echo "    Run without --check to attempt auto-heal"
else
    echo -e "${RED}❌ NEEDS ATTENTION - $ISSUES_FAILED issue(s) require manual fix${NC}"
fi

echo ""
echo "Issues found: $ISSUES_FOUND | Fixed: $ISSUES_FIXED | Need attention: $ISSUES_FAILED"
echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Return appropriate exit code
if [[ $ISSUES_FAILED -gt 0 ]]; then
    exit 1
elif [[ $ISSUES_FOUND -gt 0 ]] && $CHECK_ONLY; then
    exit 2
else
    exit 0
fi
