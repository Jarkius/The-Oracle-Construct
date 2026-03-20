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

mkdir -p "$TARGET_REPO/psi/source"
mkdir -p "$TARGET_REPO/psi/memory/retrospectives"
mkdir -p "$TARGET_REPO/psi/memory/learnings"
mkdir -p "$TARGET_REPO/psi/memory/logs"
mkdir -p "$TARGET_REPO/psi/memory/adr"
mkdir -p "$TARGET_REPO/psi/state/pulse"
mkdir -p "$TARGET_REPO/psi/knowledge/active"
mkdir -p "$TARGET_REPO/psi/knowledge/archive"
mkdir -p "$TARGET_REPO/psi/knowledge/repos"
mkdir -p "$TARGET_REPO/psi/swarm/handoffs"
mkdir -p "$TARGET_REPO/psi/swarm/messages"
mkdir -p "$TARGET_REPO/psi/archive"

# Create ψ symlink (Greek psi alias)
cd "$TARGET_REPO" && ln -sf psi ψ && cd - > /dev/null
mkdir -p "$TARGET_REPO/.agent/workflows"
mkdir -p "$TARGET_REPO/.claude/commands"
mkdir -p "$TARGET_REPO/.claude/agents"
mkdir -p "$TARGET_REPO/.claude/hooks/core"
mkdir -p "$TARGET_REPO/.claude/hooks/pulse"
mkdir -p "$TARGET_REPO/.claude/hooks/voice"
mkdir -p "$TARGET_REPO/.claude/hooks/util"
mkdir -p "$TARGET_REPO/.claude/config"

# ============================================
# Phase 2: Extract ALL Source Chapters
# ============================================
echo -e "${GREEN}[2/9] Extracting The Source (all chapters)...${NC}"

# Copy all Source files
for src_file in "$SOURCE_DIR/psi/source/"*.md; do
    if [[ -f "$src_file" ]]; then
        cp "$src_file" "$TARGET_REPO/psi/source/"
        echo "  ✓ $(basename "$src_file")"
    fi
done

# Copy SOUL_MANIFEST
if [[ -f "$SOURCE_DIR/psi/source/SOUL_MANIFEST.sha256" ]]; then
    cp "$SOURCE_DIR/psi/source/SOUL_MANIFEST.sha256" "$TARGET_REPO/psi/source/"
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
mkdir -p "$TARGET_REPO/scripts/voice"
if [[ -f "$SOURCE_DIR/scripts/voice/voice.sh" ]]; then
    cp "$SOURCE_DIR/scripts/voice/voice.sh" "$TARGET_REPO/scripts/voice/"
    echo "  ✓ voice.sh"
fi

if [[ -f "$SOURCE_DIR/scripts/voice/voice_server.py" ]]; then
    cp "$SOURCE_DIR/scripts/voice/voice_server.py" "$TARGET_REPO/scripts/voice/"
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
# Phase 6: Extract Audio Assets (Music + SFX)
# ============================================
echo -e "${GREEN}[6/10] Extracting audio assets...${NC}"

# Create audio directories
mkdir -p "$TARGET_REPO/.claude/audio/tracks"
mkdir -p "$TARGET_REPO/.claude/audio/sfx"

# Copy background music tracks
track_count=0
if [[ -d "$SOURCE_DIR/.claude/audio/tracks" ]]; then
    for track in "$SOURCE_DIR/.claude/audio/tracks/"*.mp3; do
        if [[ -f "$track" ]]; then
            cp "$track" "$TARGET_REPO/.claude/audio/tracks/"
            ((track_count++))
        fi
    done
fi
echo "  ✓ $track_count music tracks"

# Copy sound effects
sfx_count=0
if [[ -d "$SOURCE_DIR/.claude/audio/sfx" ]]; then
    for sfx in "$SOURCE_DIR/.claude/audio/sfx/"*.wav; do
        if [[ -f "$sfx" ]]; then
            cp "$sfx" "$TARGET_REPO/.claude/audio/sfx/"
            ((sfx_count++))
        fi
    done
fi
echo "  ✓ $sfx_count sound effects"

# ============================================
# Phase 7: Extract Hooks
# ============================================
echo -e "${GREEN}[7/10] Extracting hooks...${NC}"

for subdir in core pulse voice util; do
    if [[ -d "$SOURCE_DIR/.claude/hooks/$subdir" ]]; then
        for hook in "$SOURCE_DIR/.claude/hooks/$subdir/"*.sh; do
            if [[ -f "$hook" ]]; then
                cp "$hook" "$TARGET_REPO/.claude/hooks/$subdir/"
                chmod +x "$TARGET_REPO/.claude/hooks/$subdir/$(basename "$hook")"
                echo "  ✓ $subdir/$(basename "$hook")"
            fi
        done
    fi
done

# ============================================
# Phase 8: Extract ADRs and Memory Structure
# ============================================
echo -e "${GREEN}[8/10] Extracting ADRs and memory...${NC}"

# Copy ADRs
for adr in "$SOURCE_DIR/psi/memory/adr/"*.md; do
    if [[ -f "$adr" ]]; then
        cp "$adr" "$TARGET_REPO/psi/memory/adr/"
        echo "  ✓ $(basename "$adr")"
    fi
done

echo "  (active scripts archived — now in psi/archive/)"

# Copy knowledge index if exists
if [[ -f "$SOURCE_DIR/psi/memory/knowledge-index.md" ]]; then
    cp "$SOURCE_DIR/psi/memory/knowledge-index.md" "$TARGET_REPO/psi/memory/"
    echo "  ✓ knowledge-index.md"
fi

# Copy templates
if [[ -d "$SOURCE_DIR/templates" ]]; then
    mkdir -p "$TARGET_REPO/templates"
    cp "$SOURCE_DIR/templates/"*.md "$TARGET_REPO/templates/" 2>/dev/null || true
    echo "  ✓ templates/"
fi

# Copy focus state and handoffs
if [[ -f "$SOURCE_DIR/psi/state/focus.md" ]]; then
    cp "$SOURCE_DIR/psi/state/focus.md" "$TARGET_REPO/psi/state/"
    echo "  ✓ psi/state/focus.md"
fi
if [[ -d "$SOURCE_DIR/psi/swarm/handoffs" ]]; then
    cp "$SOURCE_DIR/psi/swarm/handoffs/"*.md "$TARGET_REPO/psi/swarm/handoffs/" 2>/dev/null || true
    echo "  ✓ psi/swarm/handoffs/"
fi

# Create logs gitkeep
echo "# Logs - captured moments" > "$TARGET_REPO/psi/memory/logs/.gitkeep"
echo "  ✓ psi/memory/logs/"

# ============================================
# Phase 9: Create Configuration Files
# ============================================
echo -e "${GREEN}[9/10] Creating configuration files...${NC}"

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

# Audio cache (regenerated at runtime)
psi/matrix/audio_cache/*.wav
.claude/audio/tts-*.wav

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
# Phase 10: Preserve Teleport Script
# ============================================
echo -e "${GREEN}[10/10] Checking teleport.sh...${NC}"

# teleport.sh is maintained directly in matrix-reloaded with Apple Silicon support.
# We do NOT overwrite it during extraction to preserve any improvements made there.
# The canonical teleport.sh lives in matrix-reloaded, not The-matrix.

if [[ -f "$TARGET_REPO/teleport.sh" ]]; then
    echo "  ✓ teleport.sh exists (preserved, not overwritten)"
    echo "    Note: teleport.sh is maintained in matrix-reloaded directly"
else
    echo -e "${YELLOW}  ⚠ teleport.sh not found - please restore from git or create manually${NC}"
    echo "    See: https://github.com/Jarkius/matrix-reloaded"
fi

chmod +x "$TARGET_REPO/teleport.sh" 2>/dev/null || true

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
echo "  - $track_count music tracks"
echo "  - $sfx_count sound effects"
echo "  - Hooks"
echo "  - Templates"
echo "  - Inbox (focus.md, handoff/)"
echo "  - ψ symlink (psi alias)"
echo "  - teleport.sh"
echo ""
echo "Next steps:"
echo "  cd $TARGET_REPO"
echo "  git add -A"
echo "  git commit -m 'feat: Full Matrix extraction from The-Oracle-Construct'"
echo "  git push"
echo ""
echo -e "${MAGENTA}🔴 Enter the Matrix.${NC}"
