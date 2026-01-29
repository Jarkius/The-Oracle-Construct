# ADR-007: Browser Automation Architecture

> *"I can only show you the door. You're the one that has to walk through it." - Morpheus*

**Status:** Accepted
**Date:** 2026-01-29
**Author:** Oracle + Morpheus

---

## Context

The Matrix needed external AI research capabilities beyond Claude's training data. Gemini Pro offers YouTube analysis, Deep Research mode, and web-connected responses. We needed a way to orchestrate Gemini from Claude Code.

## Decision

Implement browser automation using **Playwright MCP with Brave browser** as the primary approach, with Task agents for parallel execution.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Claude Code (Opus)                    │
│                      Orchestrator                        │
└─────────────────────────┬───────────────────────────────┘
                          │
          ┌───────────────┼───────────────┐
          │               │               │
          ▼               ▼               ▼
    ┌───────────┐   ┌───────────┐   ┌───────────┐
    │ Task Agent│   │ Task Agent│   │ Task Agent│
    │  (Sonnet) │   │  (Sonnet) │   │  (Sonnet) │
    └─────┬─────┘   └─────┬─────┘   └─────┬─────┘
          │               │               │
          ▼               ▼               ▼
    ┌───────────┐   ┌───────────┐   ┌───────────┐
    │ Playwright│   │ Playwright│   │ Playwright│
    │    MCP    │   │    MCP    │   │    MCP    │
    └─────┬─────┘   └─────┬─────┘   └─────┬─────┘
          │               │               │
          ▼               ▼               ▼
    ┌───────────┐   ┌───────────┐   ┌───────────┐
    │   Brave   │   │   Brave   │   │   Brave   │
    │  Browser  │   │  Browser  │   │  Browser  │
    └─────┬─────┘   └─────┬─────┘   └─────┬─────┘
          │               │               │
          └───────────────┼───────────────┘
                          │
                          ▼
                ┌─────────────────┐
                │ gemini.google.com│
                │   (Gemini Pro)   │
                └─────────────────┘
```

## Why Brave over Chrome?

| Factor | Chrome | Brave | Winner |
|--------|--------|-------|--------|
| Ad Blocking | ❌ None | ✅ Built-in Shields | Brave |
| Anti-Detection | ❌ Detected | ✅ Stealth mode | Brave |
| YouTube Ads | ❌ Shows ads | ✅ Blocked | Brave |
| Chromium Engine | ✅ Native | ✅ Same engine | Tie |
| Playwright Compat | ✅ Native | ✅ Via executable-path | Tie |

**Decision:** Use Brave for all browser automation.

## MCP Server Configuration

### Primary: Playwright with Brave
```bash
claude mcp add playwright -- npx '@playwright/mcp@latest' \
  --executable-path '/Applications/Brave Browser.app/Contents/MacOS/Brave Browser'
```

### Alternative: Brave Real Browser
```bash
claude mcp add brave-browser npx brave-real-browser-mcp-server@latest
```

## Parallel Execution Patterns

### Pattern 1: Multi-Tab (Shared Context)
- Single browser, multiple tabs
- Shared authentication session
- Lower resource usage
- Best for: Related queries

### Pattern 2: Task Agents (True Isolation)
- Multiple independent processes
- Complete isolation
- Higher resource usage
- Best for: Unrelated research, maximum parallelism

**Recommendation:** Use Task agents for production parallel research.

## Security Considerations

1. **Google Account** - User must sign in manually (no credential storage)
2. **Session Persistence** - Gemini sessions may timeout/reset
3. **Rate Limiting** - Keep parallel tabs under 4 to avoid throttling
4. **Data Flow** - Results saved locally to `psi/learn/inbox/`

## Fallback Strategy

```
Browser fails?
    ↓
Retry with fresh navigation
    ↓
Still failing?
    ↓
Fall back to Gemini API (matrix-gemini-agent)
    ↓
API also fails?
    ↓
Fall back to yt-dlp + local processing
```

## Consequences

### Positive
- Access to Gemini's Deep Research mode
- YouTube analysis with timestamps
- Parallel research capability
- Ad-free experience via Brave

### Negative
- Requires browser window (not headless for Gemini)
- Session management complexity
- Slower than pure API calls

### Neutral
- Google account required for Gemini access
- Research results need manual distillation

## Related

- ADR-003: Hierarchical Mind Architecture (agent tiers)
- ADR-005: Infinite Learning Loop (knowledge flow)
- `.agent/skills/gemini-browser/` - Implementation details
- `.agent/workflows/gemini-research.md` - Workflow definition

---

*"Welcome to the desert of the real."*
