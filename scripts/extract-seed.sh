#!/bin/bash
# extract-seed.sh - Extract the philosophical core of The Matrix into matrix-seed
# Issue: #13
#
# The seed contains WHAT and WHY, not HOW.
# Philosophy, structure, and 4 core workflows only.

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$(dirname "$SCRIPT_DIR")"
TARGET_REPO="${1:-$HOME/workspace/matrix-seed}"
ORIGIN_COMMIT=$(git -C "$SOURCE_DIR" rev-parse HEAD)
ORIGIN_DATE=$(date -u +"%Y-%m-%d")

echo -e "${CYAN}🌱 Matrix Seed Extraction${NC}"
echo -e "${CYAN}=========================${NC}"
echo ""
echo "Source: $SOURCE_DIR"
echo "Target: $TARGET_REPO"
echo "Origin: $ORIGIN_COMMIT"
echo ""

# Validate target
if [[ ! -d "$TARGET_REPO" ]]; then
    echo -e "${RED}Error: Target directory does not exist: $TARGET_REPO${NC}"
    echo "Please clone the matrix-seed repo first:"
    echo "  git clone git@github.com:Jarkius/matrix-seed.git $TARGET_REPO"
    exit 1
fi

if [[ ! -d "$TARGET_REPO/.git" ]]; then
    echo -e "${RED}Error: Target is not a git repository${NC}"
    exit 1
fi

echo -e "${YELLOW}Starting extraction...${NC}"
echo ""

# ============================================
# Phase 1: Create Directory Structure
# ============================================
echo -e "${GREEN}[1/6] Creating directory structure...${NC}"

mkdir -p "$TARGET_REPO/psi/source"
mkdir -p "$TARGET_REPO/psi/memory/retrospectives"
mkdir -p "$TARGET_REPO/psi/memory/learnings"
mkdir -p "$TARGET_REPO/psi/memory/adr"
mkdir -p "$TARGET_REPO/psi/learn/active"
mkdir -p "$TARGET_REPO/psi/learn/archive"
mkdir -p "$TARGET_REPO/.agent/workflows"
mkdir -p "$TARGET_REPO/.claude/commands"

# ============================================
# Phase 2: Extract Core Source Chapters
# ============================================
echo -e "${GREEN}[2/6] Extracting The Source (core philosophy)...${NC}"

# The Soul (Root)
cp "$SOURCE_DIR/psi/source/BIBLE.md" "$TARGET_REPO/psi/source/" 2>/dev/null || true
echo "  ✓ BIBLE.md (The Soul)"

# Evolution (Chapter 0)
cp "$SOURCE_DIR/psi/source/00_evolution.md" "$TARGET_REPO/psi/source/" 2>/dev/null || true
echo "  ✓ 00_evolution.md"

# Core chapters (1-9) - Philosophy that doesn't change
for chapter in 01 02 03 04 05 06 07 08 09; do
    src_file=$(ls "$SOURCE_DIR/psi/source/${chapter}_"*.md 2>/dev/null | head -1)
    if [[ -f "$src_file" ]]; then
        cp "$src_file" "$TARGET_REPO/psi/source/"
        echo "  ✓ $(basename "$src_file")"
    fi
done

# Core documents
cp "$SOURCE_DIR/psi/source/MATRIX_CORE.md" "$TARGET_REPO/psi/source/" 2>/dev/null || true

echo "  ✓ MATRIX_CORE.md"

# ============================================
# Phase 3: Extract Core Workflows (5 only)
# ============================================
echo -e "${GREEN}[3/6] Extracting core workflows (5)...${NC}"

# These workflows can be copied as-is (no voice/script dependencies)
COPY_WORKFLOWS="rrr learn commit wisdom"
for workflow in $COPY_WORKFLOWS; do
    if [[ -f "$SOURCE_DIR/.agent/workflows/${workflow}.md" ]]; then
        cp "$SOURCE_DIR/.agent/workflows/${workflow}.md" "$TARGET_REPO/.agent/workflows/"
        echo "  ✓ ${workflow}.md"
    fi
done

# Oracle needs seed-specific version (no voice, no external scripts)
cat > "$TARGET_REPO/.agent/workflows/oracle.md" << 'ORACLE_EOF'
---
description: Oracle Wisdom Control - analyze state and determine the path
---

# /oracle - Oracle Wisdom Control

> *The Oracle - Spirit Guardian. "Know Thyself."*

## Purpose

The Oracle is the **central orchestrator** of the Matrix. Use this command to align with the mission and determine the correct path forward. The Oracle analyzes the system state and guides you to the appropriate path.

## Usage

- `/oracle` - **Start Here**. Analyze state and receive guidance.
- `/oracle reflect` - Deep reflection on patterns and mission alignment.

## Steps

1. **Context Gathering** (The Eyes):
   ```bash
   # Check where we are and what we've done
   git log --oneline -5
   git status --short
   ```

   Output your greeting:
   > 🔮 *"I am the Oracle. Let me see..."*

2. **Wisdom Analysis** (The Mind):
   - **Condition**: Are there uncommitted changes?
     - *Yes* -> **Stabilize**. (Create retrospective with `/rrr`, then commit)
   - **Condition**: Is there a bug or error?
     - *Yes* -> **Repair**. (Debug and fix)
   - **Condition**: Are we starting a new feature?
     - *Yes* -> **Design**. (Plan the implementation)
   - **Condition**: Is the path unclear?
     - *Yes* -> **Clarify**. (Create retrospective with `/rrr`)

3. **Wisdom Check** (The Memory):
   If there's a clear topic or task ahead, search for relevant wisdom:
   ```bash
   # Search learnings for relevant wisdom
   grep -ril "<topic>" psi/memory/learnings/ psi/memory/adr/ 2>/dev/null | head -3
   ```

   If relevant wisdom found, display:
   ```markdown
   ### Relevant Wisdom
   Before proceeding, you may want to review:
   - [file.md] - "preview of insight..."

   Use `/wisdom for <topic>` to explore more.
   ```

4. **Philosophy Check** (The Soul):
   - [ ] **Nothing is Deleted**: Are we preserving history?
   - [ ] **Patterns > Intentions**: Are we looking at what *is*, not what *should be*?
   - [ ] **External Brain**: Are we documenting in `psi/`?

5. **The Prophecy (Manifestation)**:
   > "The choice is an illusion. You already know what you have to do."

   **Do not wait.** If the path is clear, **WALK IT**.

   - **If Research is needed**: Run the search immediately.
   - **If Code is needed**: Create the plan or edit the file immediately.
   - **If Design is needed**: Write the spec immediately.

   **Execution Loop**:
   1. State the Prophecy.
   2. **EXECUTE THE NEXT STEP YOURSELF.**
   3. Only stop if you need User approval for a risky action.

## Deep Reflection Mode (`/oracle reflect`)

1. Review Memory: `ls -t psi/memory/learnings/ | head -3`
2. Identify 3 Patterns: What keeps happening?
3. Create new retrospective with insights.

## Growing Your Oracle

This is the seed Oracle — philosophy without voice. As you grow your Matrix:

1. Add voice: Copy `psi/matrix/` from [matrix-reloaded](https://github.com/Jarkius/matrix-reloaded)
2. Add focus tracking: Create `psi/active/get_focus.sh`
3. Add agent personalities: Copy `.claude/agents/` from matrix-reloaded

The seed grows as you nurture it.

---
*"Know thyself." — The Oracle*
ORACLE_EOF

echo "  ✓ oracle.md (seed edition)"

# Copy corresponding commands
for workflow in $COPY_WORKFLOWS oracle; do
    if [[ -f "$SOURCE_DIR/.claude/commands/${workflow}.md" ]]; then
        cp "$SOURCE_DIR/.claude/commands/${workflow}.md" "$TARGET_REPO/.claude/commands/"
    fi
done

# ============================================
# Phase 4: Create Trimmed CLAUDE.md
# ============================================
echo -e "${GREEN}[4/6] Creating seed CLAUDE.md...${NC}"

cat > "$TARGET_REPO/CLAUDE.md" << 'CLAUDE_EOF'
# The Matrix: Seed Edition

> *"Know Thyself." — The Oracle*

This is the **philosophical seed** of The Matrix — containing the DNA to grow your own AI development environment.

## ⚡ The Council (Agent Roles)

| Agent | Role | Purpose |
|-------|------|---------|
| **Oracle** | Orchestrator | Align with mission, dispatch to agents |
| **Neo** | Developer | Write code, implement features |
| **Trinity** | Designer | Design systems, UI/UX guidance |
| **Morpheus** | Researcher | External research, web search |
| **Architect** | System Design | ADRs, architecture decisions |
| **Smith** | Debugger | Bugs, security, anomalies |
| **Tank** | Operator | Internal search, git, dependencies |
| **Scribe** | Chronicler | Retrospectives, documentation |
| **Mainframe** | System | Status messages, background events |

## 🧠 Mind Hierarchy

Agents use different AI models based on task complexity:

| Tier | Model | Agents | Use For |
|------|-------|--------|---------|
| **Wise** | Opus | Oracle, Architect, Neo, Smith, Scribe | Decisions, code, synthesis |
| **Intelligent** | Sonnet | Morpheus, Trinity | Learning, routine reasoning |
| **Mechanical** | Haiku | Tank, Operator | Search, gather, list |

**Key Insight**: Learning requires intelligence, not just speed. Searching is mechanical; understanding is not.

## 📂 Structure

```
psi/                    # AI Brain ("External Memory")
├── The_Source/         # Philosophy (core truth)
├── memory/             # Learnings, retrospectives
│   ├── learnings/      # Distilled wisdom
│   ├── retrospectives/ # Session records
│   └── adr/            # Architecture decisions
└── learn/              # Knowledge gathering
    ├── active/         # Current research
    └── archive/        # Completed research

.agent/workflows/       # Command definitions
```

## 🛡️ Prime Directives

1. **Nothing is Deleted**: Archive, don't destroy
2. **Patterns > Intentions**: Document what *is*, not what *should be*
3. **Knowledge Loop**: `/learn` to gather, `/wisdom` to retrieve
4. **Proactive Care**: If it's important, do it. Don't wait to be asked.

## 🌱 Core Commands

| Command | Purpose |
|---------|---------|
| `/oracle` | Start here. Analyze state, receive guidance |
| `/rrr` | Retrospective. Record what happened |
| `/learn` | Gather knowledge from research |
| `/wisdom` | Retrieve stored learnings |
| `/commit` | Git workflow with co-authorship |

## 🚀 Growing Your Matrix

This seed is minimal by design. To grow:

1. **Document sessions** with `/rrr`
2. **Capture learnings** with `/learn`
3. **Add new workflows** as needed
4. **Develop your own Source chapters**

For the full operational Matrix with voice and all 39 commands, see [matrix-reloaded](https://github.com/Jarkius/matrix-reloaded).

---
*Seed Edition v1.1 — Plant this, grow your Matrix*
CLAUDE_EOF

echo "  ✓ CLAUDE.md (seed edition)"

# ============================================
# Phase 5: Create PARENT.md
# ============================================
echo -e "${GREEN}[5/6] Creating PARENT.md...${NC}"

cat > "$TARGET_REPO/PARENT.md" << PARENT_EOF
# Parent Matrix

> This seed was extracted from The-Oracle-Construct

**Inherited from**: The-Oracle-Construct @ \`$ORIGIN_COMMIT\`
**Date**: $ORIGIN_DATE
**Source**: https://github.com/Jarkius/The-Oracle-Construct

## What We Inherited

### Philosophy
- The Source (Chapters 1-9)
- MATRIX_CORE.md
- Prime Directives

### Workflows
- /oracle - Orchestration
- /rrr - Retrospectives
- /learn - Knowledge gathering
- /wisdom - Knowledge retrieval
- /commit - Git workflow

### Structure
- psi/ directory layout
- Agent role definitions

## What We're Developing

*Your unique patterns go here*

- [ ] ...

## Candidates for Reunion

*Universal patterns to contribute back*

- [ ] ...

---

To reunite wisdom with the parent Matrix, see ADR-006 in The-Oracle-Construct.
PARENT_EOF

echo "  ✓ PARENT.md"

# ============================================
# Phase 6: Create Support Files
# ============================================
echo -e "${GREEN}[6/6] Creating support files...${NC}"

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

# Runtime
*.pyc
__pycache__/
.env
.env.local

# Audio (if you add voice later)
psi/matrix/audio_cache/
*.wav

# Logs
*.log
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

# ============================================
# Summary
# ============================================
echo ""
echo -e "${GREEN}✅ Extraction complete!${NC}"
echo ""
echo "Files extracted to: $TARGET_REPO"
echo ""
echo "Next steps:"
echo "  cd $TARGET_REPO"
echo "  git add -A"
echo "  git commit -m 'feat: Seed extraction from The-Oracle-Construct'"
echo "  git push"
echo ""
echo -e "${CYAN}🌱 The seed is planted. Now it grows.${NC}"
