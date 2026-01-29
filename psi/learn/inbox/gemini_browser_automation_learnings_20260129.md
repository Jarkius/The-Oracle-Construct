# Learnings: Gemini Browser Automation via Playwright MCP

> **Date:** 2026-01-29
> **Session:** Testing YouTube research workflow

---

## What I Learned

### 1. Browser Setup

| Discovery | Details |
|-----------|---------|
| Playwright MCP can use Brave | Pass `--executable-path` to npx command |
| Config location | `~/.claude.json` under projects |
| Session restart needed | MCP config changes require session restart |
| Brave path on macOS | `/Applications/Brave Browser.app/Contents/MacOS/Brave Browser` |

### 2. Gemini Capabilities

| Feature | Works? | Notes |
|---------|--------|-------|
| YouTube video analysis | ✅ Yes | Extracts key insights with timestamps |
| Timestamped links | ✅ Yes | Clickable links to specific moments |
| Thinking process | ✅ Yes | "Show thinking" button reveals reasoning |
| Deep Research mode | ✅ Available | Can watch entire video for deeper analysis |
| Pro mode | ✅ Active | Better quality responses |

### 3. Automation Flow

```
1. Navigate to gemini.google.com
2. Wait for page load
3. Click textbox (ref=e286 or similar)
4. Type prompt with YouTube URL
5. Submit (press Enter)
6. Wait for response (10-15 seconds for video analysis)
7. Extract content from snapshot
8. Save to markdown
```

### 4. Key Selectors

| Element | Selector/Ref |
|---------|-------------|
| Prompt textbox | `textbox "Enter a prompt here"` |
| Mode picker | `button "Pro"` or `button "Fast"` |
| Send button | Auto-submit with Enter |
| Stop response | `button "Stop response"` |
| Copy response | `button "Copy"` |

### 5. Gotchas & Solutions

| Issue | Solution |
|-------|----------|
| Chat session lost | Gemini sometimes resets - retry prompt |
| Chrome instead of Brave | Add `--executable-path` to MCP config |
| MCP not loading | Restart Claude Code session |
| Response truncated | Wait longer, use `browser_snapshot` to get full content |

### 6. Ad Blocking Confirmation

Brave's shields block:
- `googleadservices.com`
- `google.co.th/pagead`
- Tracking images

This confirms Brave is running with ad-blocking active.

---

## Architecture Validated

```
Claude Code (Opus)
      │
      ▼
Playwright MCP ──► Brave Browser
      │                 │
      │                 ▼
      │           gemini.google.com
      │                 │
      │                 ▼
      └──────── Extract Response
                      │
                      ▼
              Save to psi/learn/
```

---

## Next Steps

1. **Create `/gemini-research` skill** - Automate the full flow
2. **Parallel tabs** - Open multiple Gemini instances for batch research
3. **Deep Research mode** - Click "Try now" for full video analysis
4. **Error handling** - Retry logic for lost sessions

---

## Tags

#gemini #browser-automation #playwright #brave #youtube #learnings
