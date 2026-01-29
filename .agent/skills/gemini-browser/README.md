# Gemini Browser Orchestration Skill

> *"I can only show you the door. You're the one that has to walk through it." - Morpheus*

## Purpose

Control multiple Gemini browser tabs for parallel research, YouTube transcription, and Deep Research mode - all orchestrated from Claude Code.

## Architecture

```
                    ┌─────────────────┐
                    │   Claude Code   │
                    │   (Orchestrator)│
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
              ▼              ▼              ▼
       ┌──────────┐   ┌──────────┐   ┌──────────┐
       │Playwright│   │Playwright│   │Playwright│
       │  Tab 1   │   │  Tab 2   │   │  Tab 3   │
       └────┬─────┘   └────┬─────┘   └────┬─────┘
            │              │              │
            ▼              ▼              ▼
       ┌──────────┐   ┌──────────┐   ┌──────────┐
       │  Gemini  │   │  Gemini  │   │  Gemini  │
       │ Deep Res │   │ YouTube  │   │ Research │
       └──────────┘   └──────────┘   └──────────┘
```

## Two Modes

### Mode 1: API (Fast, No Browser)
- Uses Gemini API directly via matrix-gemini-agent
- Best for: Quick research, YouTube with yt-dlp captions
- No browser needed, runs in terminal

### Mode 2: Browser (Deep Research)
- Uses Playwright MCP to control Gemini web interface
- Best for: Deep Research mode, complex multi-step analysis
- Requires browser window, can run multiple tabs in parallel

## Setup

```bash
# Playwright MCP (already installed)
claude mcp add playwright npx '@playwright/mcp@latest'

# Restart Claude Code to activate
claude
```

## Usage

```bash
# In Claude Code session:
"Use playwright to open gemini.google.com and start Deep Research on quantum computing"

# Or use the skill:
/gemini-research "topic" --mode=deep --tabs=3
```

## MCP Servers Installed

| Server | Purpose | Ad Block | Anti-Detect |
|--------|---------|----------|-------------|
| `playwright` | Chrome/Chromium automation | ❌ | ❌ |
| `brave-browser` | Brave with stealth mode | ✅ | ✅ |
| `context7` | Documentation search | - | - |

## Browser Choice

**Brave (Recommended)**
- Built-in ad blocking (no YouTube ads!)
- Anti-detection bypasses bot checks
- Same Chromium engine as Chrome

```bash
# Use Brave for Gemini
"Use brave-browser to open gemini.google.com"
```

**Playwright (Alternative)**
- More tools available
- Better for complex automation
- May hit bot detection

## Dependencies

- Brave Browser (`/Applications/Brave Browser.app`)
- Google account (for Gemini access)
- matrix-gemini-agent (for API mode fallback)

## Free Tier Compatible

This skill works **without Claude subscription**:
- Brave Real Browser MCP is free and open-source
- Playwright MCP is free and open-source
- Gemini web interface is free (with Google account)
- Only requires Claude Code API credits for orchestration

## Activation

**Restart Claude Code** to load the new MCP servers:
```bash
# Exit current session, then:
claude
```

Then verify with `/mcp` command.

## Verified Selectors (Gemini Web Interface)

| Element | Selector |
|---------|----------|
| Prompt textbox | `textbox "Enter a prompt here"` |
| Mode picker | `button "Pro"` or `button "Fast"` |
| Submit | Press `Enter` key |
| Stop response | `button "Stop response"` |
| Copy response | `button "Copy"` |
| New chat | `link "New chat"` |

## Parallel Execution

### Multi-Tab (Single Browser)
- Use `mcp__playwright__browser_tabs` to manage tabs
- Tabs share the same browser context (logged-in session)
- Good for: Related research, shared authentication

### Multi-Agent (True Isolation)
- Use **Task tool** with `run_in_background: true`
- Each agent spawns independent research
- Good for: Unrelated topics, maximum parallelism

```bash
# Example: Launch 2 parallel research agents
Task(subagent_type="general-purpose", run_in_background=true, prompt="Research topic A via Gemini")
Task(subagent_type="general-purpose", run_in_background=true, prompt="Research topic B via Gemini")
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Chrome opens instead of Brave | Add `--executable-path` to playwright MCP config |
| MCP not loading | Restart Claude Code session |
| Gemini session lost | Retry prompt - Gemini sometimes resets |
| Timeout errors | Wait longer, check network |
| "Chat doesn't exist" | Navigate to `/app` fresh |

## Example Output

Research results are saved as markdown:
```
psi/learn/inbox/gemini_[topic]_[timestamp].md
```

Contains:
- Video/topic summary
- Key insights with timestamps
- Clickable links to source material
- Tags for retrieval
