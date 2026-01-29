# Claude Code Skills & MCP Server Integration

> Research compiled via Gemini YouTube search on 2026-01-29

---

## Overview

This document summarizes key lessons about creating custom skills (slash commands) and MCP server integration in Claude Code, gathered from top YouTube tutorials.

---

## Part 1: Custom Slash Commands & Skills

### Directory Structure

| Type | Scope | Directory Path |
|------|-------|----------------|
| Project Command | Current Repo | `.claude/commands/` |
| Personal Command | Global | `~/.claude/commands/` |
| Project Skill | Current Repo | `.claude/skills/[skill-name]/` |
| Personal Skill | Global | `~/.claude/skills/[skill-name]/` |

### Slash Command Format

Create a file at `.claude/commands/my-command.md`:

```markdown
---
description: Brief description for the /help menu
allowed-tools: [Bash, Read, Write]
model: claude-3-5-sonnet-20241022
argument-hint: [optional-arg]
---

# Task

Analyze the following code and suggest performance improvements.
Focus on $ARGUMENTS.
```

### Skill (SKILL.md) Format

Skills are stored in their own subdirectories with a `SKILL.md` entry point:

```markdown
---
name: db-expert
description: Use this skill when the user asks to optimize database queries or schema.
---

# Instructions

When this skill is active, always:
1. Check for missing indexes in `src/db/schema.ts`.
2. Ensure all queries use the repository pattern.
```

### Key Features & Syntax

- **Dynamic Context (`!`)**: Execute a terminal command and inject output
  - Example: `Current branch status: !git status`

- **File References (`@`)**: Automatically include file contents
  - Example: `Review the logic in @src/auth.ts`

- **Arguments (`$ARGUMENTS` or `$1`)**: Pass user input from terminal
  - Example: Running `/fix 123` replaces `$1` with `123`

- **Namespacing**: Organize commands into folders
  - `.claude/commands/git/commit.md` -> `/git:commit`

### Best Practices for Commands/Skills

1. **Be Specific**: Instead of "Check code," use "Identify TypeScript errors in the `src/` directory"
2. **Progressive Disclosure**: Keep `SKILL.md` under 500 lines; use directory for large reference files
3. **Tool Constraints**: Use `allowed-tools` frontmatter to limit capabilities
4. **Explain the 'Why'**: Tell Claude why a rule exists for better judgment calls

### Tutorial Timestamps - Slash Commands

From "Slash Commands - Claude Code Tutorial #6" (Net Ninja):
- **[02:55]** - Step-by-step walkthrough for building first custom AI command
- **[10:20]** - Live demonstration of command initializing a full project
- **[15:02]** - Pro-level automation strategies and gotchas to avoid

**Source**: [Slash Commands - Claude Code Tutorial #6](https://www.youtube.com/watch?v=52KBhQqqHuc)

---

## Part 2: MCP Server Integration

### Core Configuration Commands

Manage MCP servers directly from Claude Code terminal:

- **List Servers**: `claude mcp list` or `/mcp` inside the Claude shell
- **Add Server**: `claude mcp add [name] [command] [args]`
- **Remove Server**: `claude mcp remove [name]`

### Integration Examples

#### 1. Playwright MCP (Web Automation & Vision)

Allows Claude to "see" your application by taking screenshots, navigating pages, and interacting with UI elements.

**Setup Command**:
```bash
claude mcp add playwright npx -y @modelcontextprotocol/server-playwright
```

**Usage**: Ask Claude to "Open localhost:3000 and check if the login button is visible"

#### 2. Filesystem MCP (Local File Access)

Provides standardized protocol for multi-directory access.

**Setup Logic**: Uses `standard-io` transport to run locally. Specify allowed directories as arguments during the `add` command.

#### 3. Custom MCP Servers & Environment Variables

For servers requiring API keys (like GitHub or Bright Data), pass environment variables using the `-e` flag.

**Example (Bright Data Scraper)**:
```bash
claude mcp add bright-data -e API_KEY=your_key_here npx @brightdata/mcp-server
```

#### 4. Context7 (Documentation)

Provides up-to-date technical documentation for frameworks like Next.js or Tailwind.

**Setup**:
```bash
claude mcp add context7 npx -y @context7/mcp-server
```

### Configuration Details

#### Windows Compatibility

On Windows (not using WSL), prefix npx commands with `cmd /c`:
```bash
claude mcp add [name] cmd /c npx ...
```

#### Understanding Scopes

Use `-s` or `--scope` flag to define availability:

- **User (`-s user`)**: Global access across all projects
- **Project (`-s project`)**: Config saved in `mcp.json` in repo (team-shared)
- **Local (`-s local`)**: Specific to current local environment only

#### Transport Types

- **Standard IO**: Server runs as local process (most common)
- **HTTP/SSE**: Connects to remotely hosted MCP server via URL

### MCP Tutorial Sources

- [Claude Code MCP: How to Add MCP Servers (Complete Guide)](https://www.youtube.com/watch?v=DfWHX7kszQI) - Leon van Zyl
- [Claude Code Tutorial #7 - MCP Servers](https://www.youtube.com/watch?v=X7lgIa6guKg) - Net Ninja
- [Claude Code Now Has Eyes | Playwright MCP Integration](https://www.youtube.com/watch?v=NjOqPbUecC4) - Eric Tech

---

## Part 3: Workflow Best Practices

### Initial Setup

1. **Install via npm**: `npm install -g @anthropic-ai/claude-code`
2. **Initial Setup**: Run `claude` to start setup wizard
3. **Trust Directories**: Press 1 to allow file access when prompted

### Essential Commands & Modes

| Mode/Command | Description | Timestamp |
|--------------|-------------|-----------|
| Plan Mode | Hold `Shift + Tab` - Claude reasons without writing code | [03:15] |
| YOLO Mode | `claude --dangerously-skip-permissions` - Skip approval prompts | [12:14] |
| Clear History | `/clear` - Wipe conversation to free context | [08:15] |
| Initialize Config | `/init` - Set up basic configuration | [09:21] |

### Key Strategies

1. **Use a `CLAUDE.md` File**: The "onboarding" file defining tech stack, structure, and standards [08:34]
2. **Progressive Disclosure**: Use `CLAUDE.md` as index pointing to specialized files like `architecture.md` [09:46]
3. **Commit Early and Often**: Always commit before major refactors for easy revert [07:33]
4. **The "Three Options" Prompt**: Ask Claude to "provide three options to move forward" for architectural changes [12:55]

### Visual Hierarchy & Workflow

1. **Explore**: Let Claude look at the files first
2. **Plan**: Enter Plan Mode to discuss implementation
3. **Execute**: Switch to normal or YOLO mode to write code
4. **Review**: Manually check diffs and run test suite [12:40]

### Workflow Tutorial Sources

- [The Complete Claude Code Workflow (to Build Anything)](https://www.youtube.com/watch?v=dk97zcYaq_o) - Riley Brown
  - [00:44] Installation and initial setup
  - [16:12] Creating predictable agents
  - [21:47] Bypassing permissions for faster workflows
  - [25:19] Integrating with GitHub and saving progress

- [Claude Code Setup That Actually Works | Full Tutorial 2025](https://www.youtube.com/watch?v=P-5bWpUbO60) - Eric Tech
  - [01:08] Initializing projects with `CLAUDE.md`
  - [04:47] Creating custom command for Unit Tests
  - [08:40] Advanced multi-agent AI workflows
  - [11:18] Using Git for session checkpoints

- [How the Creator of Claude Code Sets Up His Workflow](https://www.youtube.com/watch?v=aqtseECSdtY) - Snapper AI
  - [Setup] The "3 Modes": Standard, Accept Edits, and Plan Mode
  - [Tip] Start in Plan Mode, then switch to Accept Edits for "one-shot" builds

---

## Crucial Warnings

1. **Context Management**: Do not let `CLAUDE.md` exceed 10k tokens. Ruthlessly prune rules Claude already follows naturally.

2. **Permissions**: The `--dangerously-skip-permissions` flag allows Claude to execute any command. Use only in trusted environments or sandboxed containers.

---

## Summary

Creating effective Claude Code skills and MCP integrations involves:

1. **Skills/Commands**: Place markdown files in `.claude/commands/` or `.claude/skills/` with proper frontmatter
2. **MCP Servers**: Use `claude mcp add` to integrate tools like Playwright, filesystem access, and documentation providers
3. **Workflow**: Combine Plan Mode for thinking, YOLO mode for execution, and regular commits for safety
4. **Context**: Keep instructions focused and use progressive disclosure for complex setups

---

*Generated from Gemini YouTube research*
