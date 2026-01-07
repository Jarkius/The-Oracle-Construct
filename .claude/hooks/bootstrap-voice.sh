#!/usr/bin/env bash
#
# File: .claude/hooks/bootstrap-voice.sh
#
# AgentVibes Self-Bootstrap - Auto-configures voice system on new machines
# Part of The Matrix voice system evolution
#
# Usage: ./bootstrap-voice.sh [--force]
#   --force: Re-run bootstrap even if already completed
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

# Detect platform
detect_platform() {
  case "$(uname -s)" in
    Darwin) echo "macos" ;;
    Linux)
      if grep -qi microsoft /proc/version 2>/dev/null; then
        echo "wsl"
      else
        echo "linux"
      fi
      ;;
    *) echo "unknown" ;;
  esac
}

# Check if a command exists
has_command() {
  command -v "$1" &>/dev/null
}

# Bootstrap for macOS
bootstrap_macos() {
  log_info "Detected macOS - using built-in voices"
  
  # Set provider to macos
  echo "macos" > "$CLAUDE_DIR/tts-provider.txt"
  
  # Set default voice if not configured
  if [[ ! -f "$CLAUDE_DIR/tts-voice.txt" ]]; then
    echo "Samantha" > "$CLAUDE_DIR/tts-voice.txt"
    log_info "Default voice set to Samantha"
  fi
  
  # Check ffmpeg for audio effects (optional)
  if ! has_command ffmpeg; then
    log_warn "ffmpeg not found - audio effects will be limited"
    log_info "Install with: brew install ffmpeg"
  fi
  
  log_success "macOS voice system ready"
}

# Bootstrap for Linux/WSL
bootstrap_linux() {
  local platform="$1"
  log_info "Detected $platform - setting up Piper TTS"
  
  # Check for pipx or pip
  if ! has_command piper; then
    log_info "Installing Piper TTS..."
    
    if has_command pipx; then
      pipx install piper-tts
    elif has_command pip3; then
      pip3 install --user piper-tts
    elif has_command pip; then
      pip install --user piper-tts
    else
      log_error "No pip/pipx found. Install Python first."
      return 1
    fi
    
    # Verify installation
    if has_command piper; then
      log_success "Piper TTS installed"
    else
      log_error "Piper installation failed"
      return 1
    fi
  else
    log_success "Piper TTS already installed"
  fi
  
  # Set provider to piper
  echo "piper" > "$CLAUDE_DIR/tts-provider.txt"
  
  # Set default Piper voice if not configured
  if [[ ! -f "$CLAUDE_DIR/tts-voice.txt" ]]; then
    echo "en_US-lessac-medium" > "$CLAUDE_DIR/tts-voice.txt"
    log_info "Default voice set to en_US-lessac-medium"
  fi
  
  # Download default voice model
  if [[ -f "$SCRIPT_DIR/piper-download-voices.sh" ]]; then
    log_info "Downloading voice models..."
    "$SCRIPT_DIR/piper-download-voices.sh" --yes 2>/dev/null || log_warn "Voice download skipped"
  fi
  
  # Check optional dependencies
  if ! has_command sox; then
    log_warn "sox not found - audio effects will be limited"
    log_info "Install with: sudo apt install sox"
  fi
  
  if ! has_command ffmpeg; then
    log_warn "ffmpeg not found - some features limited"
    log_info "Install with: sudo apt install ffmpeg"
  fi
  
  log_success "Linux voice system ready"
}

# Main bootstrap logic
main() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🎙️  AgentVibes Voice System Bootstrap"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  local force=false
  [[ "${1:-}" == "--force" ]] && force=true
  
  local marker="$CLAUDE_DIR/.voice-bootstrapped"
  
  # Check if already bootstrapped
  if [[ -f "$marker" ]] && [[ "$force" == "false" ]]; then
    log_success "Voice system already bootstrapped"
    log_info "Use --force to re-run"
    return 0
  fi
  
  local platform
  platform=$(detect_platform)
  
  log_info "Platform: $platform"
  echo ""
  
  case "$platform" in
    macos)
      bootstrap_macos
      ;;
    linux|wsl)
      bootstrap_linux "$platform"
      ;;
    *)
      log_error "Unknown platform: $platform"
      return 1
      ;;
  esac
  
  # Create marker file
  echo "$(date -Iseconds)" > "$marker"
  
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  log_success "Bootstrap complete!"
  echo ""
  echo "Test with:"
  echo "  .claude/hooks/play-tts.sh \"Hello from the Matrix\""
  echo ""
}

main "$@"
