# 🏛️ Claude Browser Proxy - Chrome Extension Architecture

> **Category**: architecture
> **Confidence**: low
> **Created**: 2026-01-29
> **Source**: Agent Orchestra (matrix-memory-agents)

## Content

Claude Browser Proxy - Chrome Extension Architecture

**What happened:** ## Overview
claude-browser-proxy is a Chrome extension that bridges Claude Code CLI and browser via MQTT. It enables browser automation and Gemini AI interaction from the command line.

GitHub: https://github.com/Soul-Brews-Studio/claude-browser-proxy

## Architecture
```
Claude Code CLI  ──MQTT (1883)──►  Mosquitto Broker  ──WebSocket (9001)──►  Chrome Extension  ──►  Browser/Gemini
```

## Tech Stack
- **Framework**: None - vanilla JavaScript
- **Extension API**: Chrome Manifest V3
- **MQTT Client**: mqtt.min.js (MQTT.js library)
- **Build Tools**: None - no bundler needed

## Key Files
- `manifest.json` - Chrome extension config (Manifest V3)
- `background.js` - Service worker, MQTT connection & command routing
- `content.js` - Injected into Gemini pages for DOM manipulation
- `mqtt.min.js` - MQTT.js library for WebSocket communication

## How It Works
1. **background.js** connects to Mosquitto broker via WebSocket (port 9001)
2. Subscribes to `claude/browser/command` topic
3. Routes commands to content script or Chrome APIs
4. **content.js** is injected into Gemini pages, manipulates DOM
5. Responses sent back via `claude/browser/response` topic

## Browser Control Commands
- `get_html`, `get_text`, `get_url` - Page content extraction
- `click`, `clickText`, `type` - DOM interaction
- `execute` - Run arbitrary JavaScript
- `screenshot` - Capture visible tab

## Gemini AI Commands
- `chat` - Send message to Gemini
- `get_response`, `wait_response` - Get Gemini's response
- `select_model` - Switch: fast/thinking/pro
- `select_mode` - Switch to Deep Research
- `transcribe` - YouTube transcription via Gemini

## Key Insight
Uses your existing Gemini session (no API keys needed). MQTT as bridge is lightweight and works over WebSocket which Chrome extensions support natively.

## Comparison
| Tool | Approach |
|------|----------|
| claude-browser-proxy | Chrome extension + MQTT |
| Playwright | Headless browser (Node.js) |
| Claude-in-Chrome MCP | MCP server + extension |
| Puppeteer | Chrome DevTools Protocol |

## Context

## Overview
claude-browser-proxy is a Chrome extension that bridges Claude Code CLI and browser via MQTT. It enables browser automation and Gemini AI interaction from the command line.

GitHub: https://github.com/Soul-Brews-Studio/claude-browser-proxy

## Architecture
```
Claude Code CLI  ──MQTT (1883)──►  Mosquitto Broker  ──WebSocket (9001)──►  Chrome Extension  ──►  Browser/Gemini
```

## Tech Stack
- **Framework**: None - vanilla JavaScript
- **Extension API**: Chrome Manifest V3
- **MQTT Client**: mqtt.min.js (MQTT.js library)
- **Build Tools**: None - no bundler needed

## Key Files
- `manifest.json` - Chrome extension config (Manifest V3)
- `background.js` - Service worker, MQTT connection & command routing
- `content.js` - Injected into Gemini pages for DOM manipulation
- `mqtt.min.js` - MQTT.js library for WebSocket communication

## How It Works
1. **background.js** connects to Mosquitto broker via WebSocket (port 9001)
2. Subscribes to `claude/browser/command` topic
3. Routes commands to content script or Chrome APIs
4. **content.js** is injected into Gemini pages, manipulates DOM
5. Responses sent back via `claude/browser/response` topic

## Browser Control Commands
- `get_html`, `get_text`, `get_url` - Page content extraction
- `click`, `clickText`, `type` - DOM interaction
- `execute` - Run arbitrary JavaScript
- `screenshot` - Capture visible tab

## Gemini AI Commands
- `chat` - Send message to Gemini
- `get_response`, `wait_response` - Get Gemini's response
- `select_model` - Switch: fast/thinking/pro
- `select_mode` - Switch to Deep Research
- `transcribe` - YouTube transcription via Gemini

## Key Insight
Uses your existing Gemini session (no API keys needed). MQTT as bridge is lightweight and works over WebSocket which Chrome extensions support natively.

## Comparison
| Tool | Approach |
|------|----------|
| claude-browser-proxy | Chrome extension + MQTT |
| Playwright | Headless browser (Node.js) |
| Claude-in-Chrome MCP | MCP server + extension |
| Puppeteer | Chrome DevTools Protocol |



---

*Synced from Agent Orchestra SQLite on 2026-01-29T18:07:43.083Z*
*Learning ID: 388*
