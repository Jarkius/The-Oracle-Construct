#!/usr/bin/env bash
#
# File: .claude/hooks/bootstrap-voice.sh
#
# Matrix Voice System Bootstrap - Auto-configures Piper TTS
# Handles Apple Silicon's x86_64 Homebrew requirement
#
# Usage: ./bootstrap-voice.sh [--force]
#   --force: Re-run bootstrap even if already completed
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$CLAUDE_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
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

# Check if piper works (not just exists)
piper_works() {
  if ! has_command piper; then
    return 1
  fi
  # Test if piper can run without library errors
  if echo "test" | piper --model /dev/null 2>&1 | grep -q "Unable to find voice"; then
    return 0  # This error is expected - piper is working
  fi
  # Check for library loading errors
  if piper --help 2>&1 | grep -q "Library not loaded"; then
    return 1
  fi
  return 0
}

# Download a single voice model
download_voice() {
  local name="$1"
  local url_path="$2"
  local display_name="$3"
  local voice_dir="$HOME/.claude/piper-voices"

  if [[ ! -f "$voice_dir/${name}.onnx" ]]; then
    log_info "Downloading ${display_name}..."
    curl -sL "https://huggingface.co/rhasspy/piper-voices/resolve/main/${url_path}/${name}.onnx" \
      -o "$voice_dir/${name}.onnx"
    curl -sL "https://huggingface.co/rhasspy/piper-voices/resolve/main/${url_path}/${name}.onnx.json" \
      -o "$voice_dir/${name}.onnx.json"
  fi
  log_success "${display_name}"
}

# Download all agent voice models (~400MB total)
download_all_voices() {
  local voice_dir="$HOME/.claude/piper-voices"
  mkdir -p "$voice_dir"

  log_info "Downloading agent voice models (~400MB total)..."

  # Core Agent Voices
  download_voice "en_US-kristin-medium" "en/en_US/kristin/medium" "Oracle (kristin)"
  download_voice "en_US-ryan-high" "en/en_US/ryan/high" "Neo (ryan-high)"
  download_voice "en_US-bryce-medium" "en/en_US/bryce/medium" "Tank (bryce)"
  download_voice "en_US-danny-low" "en/en_US/danny/low" "Smith (danny-low)"
  download_voice "en_GB-alan-medium" "en/en_GB/alan/medium" "Architect (alan)"
  download_voice "en_US-hfc_male-medium" "en/en_US/hfc_male/medium" "System (hfc_male)"
  download_voice "en_US-lessac-medium" "en/en_US/lessac/medium" "Scribe (lessac)"
  download_voice "en_US-norman-medium" "en/en_US/norman/medium" "Mainframe (norman)"

  # Jenny voice (Trinity, Woman in Red) - different naming
  if [[ ! -f "$voice_dir/jenny.onnx" ]]; then
    log_info "Downloading Trinity (jenny)..."
    curl -sL "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_GB/jenny_dioco/medium/en_GB-jenny_dioco-medium.onnx" \
      -o "$voice_dir/jenny.onnx"
    curl -sL "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_GB/jenny_dioco/medium/en_GB-jenny_dioco-medium.onnx.json" \
      -o "$voice_dir/jenny.onnx.json"
  fi
  log_success "Trinity (jenny)"

  # Note about custom voices
  if [[ ! -f "$voice_dir/en_US-carlin-high.onnx" ]]; then
    log_warn "Morpheus voice (carlin-high) - custom model, not auto-downloaded"
  fi

  log_success "Voice models stored in: $voice_dir"
}

# Bootstrap for macOS (Intel or Apple Silicon)
bootstrap_macos() {
  local arch=$(uname -m)

  log_info "Detected macOS ($arch)"

  # Check if Apple Silicon
  if [[ "$arch" == "arm64" ]]; then
    log_info "Apple Silicon detected - checking x86_64 requirements"

    # Check Rosetta
    if ! /usr/bin/pgrep -q oahd 2>/dev/null; then
      log_warn "Rosetta 2 not installed"
      log_info "Installing Rosetta 2..."
      softwareupdate --install-rosetta --agree-to-license 2>/dev/null || true
    fi

    # Check x86_64 Homebrew
    if [[ ! -f "/usr/local/bin/brew" ]]; then
      log_error "x86_64 Homebrew not found at /usr/local"
      echo ""
      echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo -e "${YELLOW}  MANUAL STEP REQUIRED: Install x86_64 Homebrew${NC}"
      echo ""
      echo "  Piper TTS requires x86_64 libraries on Apple Silicon."
      echo "  Run this command in a NEW terminal:"
      echo ""
      echo -e "  ${MAGENTA}arch -x86_64 /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"${NC}"
      echo ""
      echo "  Then re-run: ./teleport.sh"
      echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      return 1
    fi
    log_success "x86_64 Homebrew found"

    # Check espeak-ng x86_64
    if [[ ! -f "/usr/local/lib/libespeak-ng.dylib" ]]; then
      log_info "Installing espeak-ng (x86_64)..."
      arch -x86_64 /usr/local/bin/brew install espeak-ng
    fi
    log_success "espeak-ng (x86_64)"

    # Check Python 3.13 x86_64
    if [[ ! -f "/usr/local/bin/python3.13" ]]; then
      log_info "Installing Python 3.13 (x86_64)..."
      arch -x86_64 /usr/local/bin/brew install python@3.13
    fi
    log_success "Python 3.13 (x86_64)"

    # Check pipx x86_64
    if [[ ! -f "/usr/local/bin/pipx" ]]; then
      log_info "Installing pipx (x86_64)..."
      arch -x86_64 /usr/local/bin/brew install pipx
    fi
    log_success "pipx (x86_64)"

    # Check/install piper-tts
    if ! piper_works; then
      log_info "Installing piper-tts via x86_64 pipx..."
      arch -x86_64 /usr/local/bin/pipx uninstall piper-tts 2>/dev/null || true
      arch -x86_64 /usr/local/bin/pipx install piper-tts --python /usr/local/bin/python3.13
    fi

  else
    # Intel Mac
    log_info "Intel Mac detected"

    if ! has_command brew; then
      log_error "Homebrew not found. Install from https://brew.sh"
      return 1
    fi

    # Install piper-tts via pipx
    if ! has_command pipx; then
      log_info "Installing pipx..."
      brew install pipx
    fi

    if ! piper_works; then
      log_info "Installing piper-tts..."
      pipx install piper-tts
    fi
  fi

  # Verify piper works
  if piper_works; then
    log_success "Piper TTS operational"
  else
    log_error "Piper TTS installation failed"
    log_info "Try running: ./teleport.sh"
    return 1
  fi

  # Set provider to piper (not macos)
  echo "piper" > "$CLAUDE_DIR/tts-provider.txt"

  # Download all agent voice models
  download_all_voices

  # Check optional dependencies
  if ! has_command ffmpeg; then
    log_warn "ffmpeg not found - audio effects limited"
    log_info "Install with: brew install ffmpeg"
  fi

  if ! has_command sox; then
    log_warn "sox not found - bass boost unavailable"
    log_info "Install with: brew install sox"
  fi

  log_success "macOS voice system ready (Piper TTS)"
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

  # Download all agent voice models
  download_all_voices

  # Check optional dependencies
  if ! has_command sox; then
    log_warn "sox not found - audio effects limited"
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
  echo "🎙️  Matrix Voice System Bootstrap"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  local force=false
  [[ "${1:-}" == "--force" ]] && force=true

  local marker="$CLAUDE_DIR/.voice-bootstrapped"

  # Check if already bootstrapped
  if [[ -f "$marker" ]] && [[ "$force" == "false" ]]; then
    # Verify piper still works
    if piper_works; then
      log_success "Voice system already bootstrapped and working"
      log_info "Use --force to re-run"
      return 0
    else
      log_warn "Voice system bootstrapped but piper not working"
      log_info "Re-running bootstrap..."
    fi
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
  echo "  sh psi/matrix/voice.sh \"Hello from the Matrix\" \"Oracle\""
  echo ""

  # Architecture notes
  if [[ "$(uname -m)" == "arm64" ]]; then
    echo "Note: Using x86_64 Piper via Rosetta on Apple Silicon"
    echo "Voice models: ~/.claude/piper-voices/"
  fi
  echo ""
}

main "$@"
