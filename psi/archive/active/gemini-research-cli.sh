#!/bin/bash

# ============================================================================
# Matrix Gemini Research CLI
# ============================================================================
#
# Unified entry point for Gemini browser research.
#
# Usage:
#   ./gemini-research-cli.sh [options] "query1" "query2" ...
#
# Options:
#   --mode=headless|visible    Browser visibility (default: visible)
#   --parallel=N               Max parallel instances (default: 4)
#   --youtube                  Optimize for YouTube analysis
#   --verbose                  Show detailed progress
#   --dry-run                  Show what would execute
#   --health                   Run health check only
#   --help                     Show this help
#
# Examples:
#   ./gemini-research-cli.sh "quantum computing" "AI safety"
#   ./gemini-research-cli.sh --mode=headless --parallel=4 "query1" "query2"
#   ./gemini-research-cli.sh --youtube "https://youtube.com/watch?v=..."
#
# ============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VOICE_SCRIPT="$SCRIPT_DIR/../matrix/voice.sh"
RESEARCH_SCRIPT="$SCRIPT_DIR/gemini-parallel-research.js"
HEALTH_SCRIPT="$SCRIPT_DIR/gemini-health-check.js"

# Defaults
MODE="visible"
PARALLEL=4
YOUTUBE=false
VERBOSE=false
DRY_RUN=false
QUERIES=()

# ============================================================================
# Functions
# ============================================================================

show_help() {
    cat << 'EOF'
🔮 Matrix Gemini Research CLI

Usage:
  ./gemini-research-cli.sh [options] "query1" "query2" ...

Options:
  --mode=headless|visible    Browser visibility (default: visible)
  --parallel=N               Max parallel instances (default: 4)
  --youtube                  Optimize for YouTube analysis (longer waits)
  --verbose                  Show detailed progress
  --dry-run                  Show what would execute without running
  --health                   Run health check only
  --help                     Show this help

Modes:
  visible   - Show browser windows (default, good for debugging)
  headless  - No visible windows (faster, good for batch processing)

Examples:
  # Basic research (visible mode)
  ./gemini-research-cli.sh "quantum computing" "AI safety"

  # Fast batch processing (headless)
  ./gemini-research-cli.sh --mode=headless "query1" "query2" "query3" "query4"

  # YouTube video analysis
  ./gemini-research-cli.sh --youtube "https://youtube.com/watch?v=abc123"

  # Check system health
  ./gemini-research-cli.sh --health

Output:
  Results saved to: ~/workspace/The-matrix/psi/learn/inbox/gemini_*.md
EOF
}

speak() {
    if [[ -f "$VOICE_SCRIPT" ]]; then
        sh "$VOICE_SCRIPT" "$1" "${2:-Morpheus}" 2>/dev/null || true
    fi
}

log_info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

log_ok() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

run_health_check() {
    if [[ -f "$HEALTH_SCRIPT" ]]; then
        node "$HEALTH_SCRIPT"
        return $?
    else
        log_warn "Health check script not found"
        return 0
    fi
}

# ============================================================================
# Parse Arguments
# ============================================================================

while [[ $# -gt 0 ]]; do
    case $1 in
        --mode=*)
            MODE="${1#*=}"
            shift
            ;;
        --parallel=*)
            PARALLEL="${1#*=}"
            shift
            ;;
        --youtube)
            YOUTUBE=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --health)
            run_health_check
            exit $?
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        --*)
            log_error "Unknown option: $1"
            exit 1
            ;;
        *)
            QUERIES+=("$1")
            shift
            ;;
    esac
done

# ============================================================================
# Validation
# ============================================================================

if [[ ${#QUERIES[@]} -eq 0 ]]; then
    log_error "No queries provided"
    echo ""
    show_help
    exit 1
fi

if [[ "$MODE" != "headless" && "$MODE" != "visible" ]]; then
    log_error "Invalid mode: $MODE (use 'headless' or 'visible')"
    exit 1
fi

if ! [[ "$PARALLEL" =~ ^[0-9]+$ ]] || [[ "$PARALLEL" -lt 1 ]] || [[ "$PARALLEL" -gt 8 ]]; then
    log_error "Invalid parallel count: $PARALLEL (use 1-8)"
    exit 1
fi

# ============================================================================
# Build Command
# ============================================================================

CMD_ARGS=()

# Mode
if [[ "$MODE" == "headless" ]]; then
    CMD_ARGS+=("--headless")
fi

# YouTube
if [[ "$YOUTUBE" == "true" ]]; then
    CMD_ARGS+=("--youtube")
fi

# Verbose
if [[ "$VERBOSE" == "true" ]]; then
    CMD_ARGS+=("--verbose")
fi

# Add queries
for query in "${QUERIES[@]}"; do
    CMD_ARGS+=("$query")
done

# Environment variables
export GEMINI_HEADLESS=$([[ "$MODE" == "headless" ]] && echo "true" || echo "false")
export GEMINI_MAX_CONCURRENCY="$PARALLEL"
export GEMINI_VERBOSE=$([[ "$VERBOSE" == "true" ]] && echo "true" || echo "false")

# ============================================================================
# Execute
# ============================================================================

echo ""
echo -e "${BLUE}━━━ Matrix Gemini Research ━━━${NC}"
echo ""
log_info "Mode: $MODE"
log_info "Parallel: $PARALLEL"
log_info "Queries: ${#QUERIES[@]}"
if [[ "$YOUTUBE" == "true" ]]; then
    log_info "YouTube mode: enabled"
fi
echo ""

if [[ "$DRY_RUN" == "true" ]]; then
    log_warn "Dry run mode - not executing"
    echo ""
    echo "Would execute:"
    echo "  GEMINI_HEADLESS=$GEMINI_HEADLESS \\"
    echo "  GEMINI_MAX_CONCURRENCY=$GEMINI_MAX_CONCURRENCY \\"
    echo "  node $RESEARCH_SCRIPT ${CMD_ARGS[*]}"
    exit 0
fi

# Quick health check
if ! node "$HEALTH_SCRIPT" --quiet 2>/dev/null; then
    log_warn "Health check failed - run './gemini-research-cli.sh --health' for details"
    echo ""
    read -p "Continue anyway? [y/N] " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Announce start
speak "Morpheus online. Opening ${#QUERIES[@]} Gemini portals in $MODE mode."

# Run research
log_ok "Starting research..."
echo ""

node "$RESEARCH_SCRIPT" "${CMD_ARGS[@]}"

# Done
echo ""
log_ok "Research complete!"
speak "Research complete. ${#QUERIES[@]} insights harvested."
