---
name: skill-creator
description: Create new Claude Code skills from natural language descriptions. Use when user wants to create a new skill, add a new slash command, or build automation. Generates SKILL.md with proper frontmatter, instructions, and optional scripts.
---

# Skill Creator — Meta-Skill

Create new skills for The Oracle Construct from a natural language description.

## Usage

```
/skill-creator <description of what the skill should do>
```

## Process

### 1. Gather Requirements

From the user's description, determine:
- **Name**: lowercase, hyphenated (e.g., `finance-monitor`)
- **Trigger**: When should this skill activate? What phrases?
- **Dependencies**: Any CLI tools, APIs, or packages needed?
- **Agent**: Which Matrix agent personality fits? (Oracle, Neo, Smith, etc.)
- **Scope**: Project-only or personal (`~/.claude/skills/`)?

If anything is ambiguous, ask the user before generating.

### 2. Generate Skill Structure

Create the skill directory and SKILL.md:

```
.claude/skills/<skill-name>/
├── SKILL.md           # Core instructions (always created)
├── scripts/           # Helper scripts (if needed)
│   └── <script>.sh
└── references/        # Supporting docs (if needed)
    └── <docs>.md
```

### 3. SKILL.md Template

Use this template for all generated skills:

```yaml
---
name: <skill-name>
description: <1-2 sentences explaining when to use this skill. Keep under 100 words. This is what Claude sees at boot to decide whether to load the full skill.>
---

# <Skill Title>

<One-line summary of what this skill does.>

## Requirements

<List any CLI tools, packages, or APIs needed. Include install commands.>

## Instructions

<Step-by-step instructions for Claude to follow when this skill is invoked.>

## Usage Examples

<3-5 concrete examples of how the user would invoke this skill.>

## Notes

<Edge cases, limitations, or important caveats.>
```

### 4. Quality Checks

Before finalizing, verify:
- [ ] Description is under 100 words (progressive disclosure — only metadata loads at boot)
- [ ] Name uses only lowercase letters, numbers, hyphens
- [ ] Instructions are imperative ("Do X", "Run Y") not passive
- [ ] No secrets/credentials hardcoded (use environment variables)
- [ ] Dependencies listed with install commands for macOS and Linux
- [ ] At least 3 usage examples provided

### 5. Register

After creating, confirm to the user:
```
Skill created: .claude/skills/<name>/SKILL.md
Invoke with: /<name>
```

No restart needed — Claude Code discovers skills dynamically.

## Design Principles (from Agent Skills Standard)

1. **Progressive disclosure**: Frontmatter (~100 words) loads at boot. Full SKILL.md loads only when invoked. Keep descriptions concise.
2. **Scripts for determinism**: If a task needs exact steps (file moves, API calls), put it in `scripts/` as executable shell/Python. Claude runs the script rather than reimplementing.
3. **References for context**: If the skill needs domain knowledge (API docs, format specs), put it in `references/`. Claude reads on demand.
4. **Cross-agent compatibility**: Follow the SKILL.md standard for portability across Claude Code, Cursor, VS Code, and others.
5. **Matrix-native extensions**: Add `matrix:` block to frontmatter for agent personality, model tier, and permissions.

## Matrix Extensions (Optional)

For skills that should use a specific agent persona or model:

```yaml
---
name: my-skill
description: ...
# Matrix-specific (optional, backwards-compatible)
matrix:
  agent: Neo              # Which agent personality to adopt
  tier: intelligent       # Model tier: wise (Opus), intelligent (Sonnet), mechanical (Haiku)
  requires:
    bins: [tool1, tool2]  # Required CLI tools
    skills: [other-skill] # Skill dependencies (Phase 14+)
  permissions:
    shell: [git, npm]     # Allowed shell commands
    network: false        # External network access
---
```
