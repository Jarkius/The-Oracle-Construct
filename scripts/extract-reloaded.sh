#!/bin/bash
# extract-reloaded.sh - Extract the FULL operational Matrix into matrix-reloaded
# Issue: #14
#
# This is the complete system - voice, all workflows, everything.
# Clone → teleport → operational in under 3 minutes.

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
TARGET_REPO="${1:-$HOME/workspace/matrix-reloaded}"
ORIGIN_COMMIT=$(git -C "$SOURCE_DIR" rev-parse HEAD)
ORIGIN_DATE=$(date -u +"%Y-%m-%d")

echo -e "${MAGENTA}🔴 Matrix Reloaded Extraction${NC}"
echo -e "${MAGENTA}==============================${NC}"
echo ""
echo "Source: $SOURCE_DIR"
echo "Target: $TARGET_REPO"
echo "Origin: $ORIGIN_COMMIT"
echo ""

# Validate target
if [[ ! -d "$TARGET_REPO" ]]; then
    echo -e "${RED}Error: Target directory does not exist: $TARGET_REPO${NC}"
    echo "Please clone the matrix-reloaded repo first:"
    echo "  git clone git@github.com:Jarkius/matrix-reloaded.git $TARGET_REPO"
    exit 1
fi

if [[ ! -d "$TARGET_REPO/.git" ]]; then
    echo -e "${RED}Error: Target is not a git repository${NC}"
    exit 1
fi

echo -e "${YELLOW}Starting full extraction...${NC}"
echo ""

# ============================================
# Phase 1: Create Directory Structure
# ============================================
echo -e "${GREEN}[1/9] Creating directory structure...${NC}"

mkdir -p "$TARGET_REPO/psi/The_Source"
mkdir -p "$TARGET_REPO/psi/memory/retrospectives"
mkdir -p "$TARGET_REPO/psi/memory/learnings"
mkdir -p "$TARGET_REPO/psi/memory/adr"
mkdir -p "$TARGET_REPO/psi/learn/active"
mkdir -p "$TARGET_REPO/psi/learn/archive"
mkdir -p "$TARGET_REPO/psi/learn/repos"
mkdir -p "$TARGET_REPO/psi/matrix"
mkdir -p "$TARGET_REPO/psi/active"
mkdir -p "$TARGET_REPO/.agent/workflows"
mkdir -p "$TARGET_REPO/.claude/commands"
mkdir -p "$TARGET_REPO/.claude/agents"
mkdir -p "$TARGET_REPO/.claude/hooks"
mkdir -p "$TARGET_REPO/.claude/config"

# ============================================
# Phase 2: Extract ALL Source Chapters
# ============================================
echo -e "${GREEN}[2/9] Extracting The Source (all chapters)...${NC}"

# Copy all Source files
for src_file in "$SOURCE_DIR/psi/The_Source/"*.md; do
    if [[ -f "$src_file" ]]; then
        cp "$src_file" "$TARGET_REPO/psi/The_Source/"
        echo "  ✓ $(basename "$src_file")"
    fi
done

# Copy SOUL_MANIFEST
if [[ -f "$SOURCE_DIR/psi/The_Source/SOUL_MANIFEST.sha256" ]]; then
    cp "$SOURCE_DIR/psi/The_Source/SOUL_MANIFEST.sha256" "$TARGET_REPO/psi/The_Source/"
    echo "  ✓ SOUL_MANIFEST.sha256"
fi

# ============================================
# Phase 3: Extract ALL Workflows
# ============================================
echo -e "${GREEN}[3/9] Extracting all workflows (39)...${NC}"

workflow_count=0
for workflow in "$SOURCE_DIR/.agent/workflows/"*.md; do
    if [[ -f "$workflow" ]]; then
        cp "$workflow" "$TARGET_REPO/.agent/workflows/"
        ((workflow_count++))
    fi
done
echo "  ✓ $workflow_count workflows extracted"

# Copy commands
command_count=0
for cmd in "$SOURCE_DIR/.claude/commands/"*.md; do
    if [[ -f "$cmd" ]]; then
        cp "$cmd" "$TARGET_REPO/.claude/commands/"
        ((command_count++))
    fi
done
echo "  ✓ $command_count commands extracted"

# ============================================
# Phase 4: Extract Agent Personalities
# ============================================
echo -e "${GREEN}[4/9] Extracting agent personalities...${NC}"

for agent in "$SOURCE_DIR/.claude/agents/"*.md; do
    if [[ -f "$agent" ]]; then
        cp "$agent" "$TARGET_REPO/.claude/agents/"
        echo "  ✓ $(basename "$agent")"
    fi
done

# ============================================
# Phase 5: Extract Voice System
# ============================================
echo -e "${GREEN}[5/9] Extracting voice system...${NC}"

# Voice scripts
if [[ -f "$SOURCE_DIR/psi/matrix/voice.sh" ]]; then
    cp "$SOURCE_DIR/psi/matrix/voice.sh" "$TARGET_REPO/psi/matrix/"
    echo "  ✓ voice.sh"
fi

if [[ -f "$SOURCE_DIR/psi/matrix/voice_server.py" ]]; then
    cp "$SOURCE_DIR/psi/matrix/voice_server.py" "$TARGET_REPO/psi/matrix/"
    echo "  ✓ voice_server.py"
fi

# Voice configuration
if [[ -f "$SOURCE_DIR/.claude/config/voices.json" ]]; then
    cp "$SOURCE_DIR/.claude/config/voices.json" "$TARGET_REPO/.claude/config/"
    echo "  ✓ voices.json"
fi

# Create audio cache directory marker
mkdir -p "$TARGET_REPO/psi/matrix/audio_cache"
echo "# Audio cache - generated at runtime" > "$TARGET_REPO/psi/matrix/audio_cache/.gitkeep"
echo "  ✓ audio_cache/ (empty)"

# ============================================
# Phase 6: Extract Hooks
# ============================================
echo -e "${GREEN}[6/9] Extracting hooks...${NC}"

for hook in "$SOURCE_DIR/.claude/hooks/"*.sh; do
    if [[ -f "$hook" ]]; then
        cp "$hook" "$TARGET_REPO/.claude/hooks/"
        chmod +x "$TARGET_REPO/.claude/hooks/$(basename "$hook")"
        echo "  ✓ $(basename "$hook")"
    fi
done

# ============================================
# Phase 7: Extract ADRs and Memory Structure
# ============================================
echo -e "${GREEN}[7/9] Extracting ADRs and memory...${NC}"

# Copy ADRs
for adr in "$SOURCE_DIR/psi/memory/adr/"*.md; do
    if [[ -f "$adr" ]]; then
        cp "$adr" "$TARGET_REPO/psi/memory/adr/"
        echo "  ✓ $(basename "$adr")"
    fi
done

# Copy active scripts
for script in "$SOURCE_DIR/psi/active/"*.sh; do
    if [[ -f "$script" ]]; then
        cp "$script" "$TARGET_REPO/psi/active/"
        chmod +x "$TARGET_REPO/psi/active/$(basename "$script")"
    fi
done
echo "  ✓ Active scripts"

# Copy knowledge index if exists
if [[ -f "$SOURCE_DIR/psi/memory/knowledge-index.md" ]]; then
    cp "$SOURCE_DIR/psi/memory/knowledge-index.md" "$TARGET_REPO/psi/memory/"
    echo "  ✓ knowledge-index.md"
fi

# ============================================
# Phase 8: Create Configuration Files
# ============================================
echo -e "${GREEN}[8/9] Creating configuration files...${NC}"

# CLAUDE.md (full version)
cp "$SOURCE_DIR/CLAUDE.md" "$TARGET_REPO/CLAUDE.md"
echo "  ✓ CLAUDE.md (full)"

# PARENT.md
cat > "$TARGET_REPO/PARENT.md" << PARENT_EOF
# Parent Matrix

> This Matrix was extracted from The-Oracle-Construct

**Inherited from**: The-Oracle-Construct @ \`$ORIGIN_COMMIT\`
**Date**: $ORIGIN_DATE
**Source**: https://github.com/Jarkius/The-Oracle-Construct

## What's Included

### Complete System
- All 17 Source chapters
- All 39 workflows
- All 8 agent personalities
- Full voice system (Piper TTS)
- Hooks and automation

### Ready to Operate
Run \`./teleport.sh\` to bootstrap on a new machine.

## Developed Here

*Your unique patterns go here*

- [ ] ...

## Candidates for Reunion

*Universal patterns to contribute back*

- [ ] ...

---

To reunite wisdom with the parent Matrix, see ADR-006.
PARENT_EOF

echo "  ✓ PARENT.md"

# .gitignore
cat > "$TARGET_REPO/.gitignore" << 'GITIGNORE_EOF'
# OS
.DS_Store
Thumbs.db

# Editor
.idea/
.vscode/
*.swp
*.swo

# Python
*.pyc
__pycache__/
venv/
.venv/

# Environment
.env
.env.local

# Audio cache (regenerated)
psi/matrix/audio_cache/*.wav

# Logs
*.log

# Local settings
.claude/settings.local.json

# Voice models (downloaded by teleport)
psi/matrix/models/
GITIGNORE_EOF

echo "  ✓ .gitignore"

# psi/learn/inbox.md
cat > "$TARGET_REPO/psi/learn/inbox.md" << 'INBOX_EOF'
# Learning Inbox

Quick capture for ideas and topics to explore.

## To Research

- [ ] ...

## Quick Notes

*Capture fleeting thoughts here*

---
*Use `/learn add "topic"` to add items*
INBOX_EOF

echo "  ✓ psi/learn/inbox.md"

# Settings template
cat > "$TARGET_REPO/.claude/settings.json" << 'SETTINGS_EOF'
{
  "$schema": "https://raw.githubusercontent.com/anthropics/claude-code/main/schemas/settings.json",
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "./.claude/hooks/matrix-dispatch.sh \"$TOOL_INPUT\""
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "./.claude/hooks/play-tts.sh"
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "./.claude/hooks/matrix-session-start.sh"
          }
        ]
      }
    ]
  }
}
SETTINGS_EOF

echo "  ✓ settings.json"

# ============================================
# Phase 9: Create Teleport Script
# ============================================
echo -e "${GREEN}[9/9] Creating teleport.sh...${NC}"

cat > "$TARGET_REPO/teleport.sh" << 'TELEPORT_EOF'
#!/bin/bash
# teleport.sh - Bootstrap The Matrix on a new macOS machine
#
# Usage: ./teleport.sh
#
# This script:
# 1. Checks macOS environment
# 2. Installs dependencies (Python, piper-tts)
# 3. Downloads voice model
# 4. Configures Claude integration
# 5. Runs health check

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${MAGENTA}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║    🔴 THE MATRIX - TELEPORTATION SEQUENCE                ║"
echo "║                                                           ║"
echo "║    \"Welcome to the real world.\"                          ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# ============================================
# Phase 1: Environment Check
# ============================================
echo -e "${CYAN}[1/5] Checking environment...${NC}"

# Check macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo -e "${RED}Error: This script is for macOS only${NC}"
    exit 1
fi
echo "  ✓ macOS detected"

# Check Homebrew
if ! command -v brew &> /dev/null; then
    echo -e "${YELLOW}  Installing Homebrew...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
echo "  ✓ Homebrew available"

# Check Claude Code CLI
if ! command -v claude &> /dev/null; then
    echo -e "${YELLOW}  Warning: Claude Code CLI not found${NC}"
    echo "  Install from: https://claude.ai/claude-code"
    echo "  Continuing anyway..."
else
    echo "  ✓ Claude Code CLI found"
fi

# ============================================
# Phase 2: Python Setup
# ============================================
echo ""
echo -e "${CYAN}[2/5] Setting up Python...${NC}"

# Check Python 3.11+
if ! command -v python3 &> /dev/null; then
    echo -e "${YELLOW}  Installing Python via Homebrew...${NC}"
    brew install python@3.11
fi

PYTHON_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
echo "  ✓ Python $PYTHON_VERSION"

# Create venv if needed
if [[ ! -d "$SCRIPT_DIR/.venv" ]]; then
    echo "  Creating virtual environment..."
    python3 -m venv "$SCRIPT_DIR/.venv"
fi
echo "  ✓ Virtual environment ready"

# ============================================
# Phase 3: Install Piper TTS
# ============================================
echo ""
echo -e "${CYAN}[3/5] Installing voice system...${NC}"

source "$SCRIPT_DIR/.venv/bin/activate"

# Install piper-tts
if ! pip show piper-tts &> /dev/null; then
    echo "  Installing piper-tts..."
    pip install --quiet piper-tts
fi
echo "  ✓ piper-tts installed"

# ============================================
# Phase 4: Download Voice Model
# ============================================
echo ""
echo -e "${CYAN}[4/5] Downloading voice model...${NC}"

MODELS_DIR="$SCRIPT_DIR/psi/matrix/models"
MODEL_NAME="en_US-kristin-medium"
MODEL_URL="https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/kristin/medium/en_US-kristin-medium.onnx"
CONFIG_URL="https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/kristin/medium/en_US-kristin-medium.onnx.json"

mkdir -p "$MODELS_DIR"

if [[ ! -f "$MODELS_DIR/${MODEL_NAME}.onnx" ]]; then
    echo "  Downloading ${MODEL_NAME} (~15MB)..."
    curl -sL "$MODEL_URL" -o "$MODELS_DIR/${MODEL_NAME}.onnx"
    curl -sL "$CONFIG_URL" -o "$MODELS_DIR/${MODEL_NAME}.onnx.json"
fi
echo "  ✓ Voice model: $MODEL_NAME"

# Update voice.sh to use local model
VOICE_SCRIPT="$SCRIPT_DIR/psi/matrix/voice.sh"
if [[ -f "$VOICE_SCRIPT" ]]; then
    # Check if already configured for local model
    if ! grep -q "MODELS_DIR" "$VOICE_SCRIPT"; then
        echo "  Configuring voice.sh for local model..."
        # Add model path to voice.sh header
        sed -i '' '2a\
MODELS_DIR="$(dirname "$0")/models"
' "$VOICE_SCRIPT"
    fi
fi

deactivate

# ============================================
# Phase 5: Configure Integration
# ============================================
echo ""
echo -e "${CYAN}[5/5] Configuring integration...${NC}"

# Make hooks executable
chmod +x "$SCRIPT_DIR/.claude/hooks/"*.sh 2>/dev/null || true
echo "  ✓ Hooks configured"

# Make active scripts executable
chmod +x "$SCRIPT_DIR/psi/active/"*.sh 2>/dev/null || true
echo "  ✓ Active scripts configured"

# Make voice scripts executable
chmod +x "$SCRIPT_DIR/psi/matrix/"*.sh 2>/dev/null || true
echo "  ✓ Voice scripts configured"

# Create audio cache
mkdir -p "$SCRIPT_DIR/psi/matrix/audio_cache"
echo "  ✓ Audio cache ready"

# ============================================
# Health Check
# ============================================
echo ""
echo -e "${CYAN}Running health check...${NC}"

# Test voice
source "$SCRIPT_DIR/.venv/bin/activate"
echo "The Matrix is ready" | piper --model "$MODELS_DIR/${MODEL_NAME}.onnx" --output_file /tmp/matrix_test.wav 2>/dev/null

if [[ -f "/tmp/matrix_test.wav" ]]; then
    echo -e "  ✓ Voice system operational"
    afplay /tmp/matrix_test.wav 2>/dev/null || true
    rm /tmp/matrix_test.wav
else
    echo -e "${YELLOW}  ⚠ Voice test failed - check piper installation${NC}"
fi
deactivate

# ============================================
# Complete
# ============================================
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                           ║${NC}"
echo -e "${GREEN}║    ✅ TELEPORTATION COMPLETE                             ║${NC}"
echo -e "${GREEN}║                                                           ║${NC}"
echo -e "${GREEN}║    The Matrix is ready.                                   ║${NC}"
echo -e "${GREEN}║                                                           ║${NC}"
echo -e "${GREEN}║    Run: claude                                            ║${NC}"
echo -e "${GREEN}║    Then: /oracle                                          ║${NC}"
echo -e "${GREEN}║                                                           ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
TELEPORT_EOF

chmod +x "$TARGET_REPO/teleport.sh"
echo "  ✓ teleport.sh (executable)"

# ============================================
# Summary
# ============================================
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ EXTRACTION COMPLETE                                   ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Extracted to: $TARGET_REPO"
echo ""
echo "Contents:"
echo "  - 17 Source chapters"
echo "  - $workflow_count workflows"
echo "  - 8 agent personalities"
echo "  - Voice system"
echo "  - Hooks"
echo "  - teleport.sh"
echo ""
echo "Next steps:"
echo "  cd $TARGET_REPO"
echo "  git add -A"
echo "  git commit -m 'feat: Full Matrix extraction from The-Oracle-Construct'"
echo "  git push"
echo ""
echo -e "${MAGENTA}🔴 Enter the Matrix.${NC}"
