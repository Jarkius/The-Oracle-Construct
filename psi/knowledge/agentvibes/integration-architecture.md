# AgentVibes Integration Architecture

> Lesson learned: 2026-01-07

## Overview

AgentVibes provides Text-to-Speech (TTS) capabilities for Claude Code, enabling AI agents to speak their responses aloud.

## Components

### 1. MCP Server (Model Context Protocol)

**Source**: npm package `agentvibes` (v2.17.8)

**Config**: `.mcp.json`
```json
{
  "mcpServers": {
    "agentvibes": {
      "command": "npx",
      "args": ["-y", "--package=agentvibes", "agentvibes-mcp-server"]
    }
  }
}
```

**Provides tools**:
- `mcp__agentvibes__text_to_speech` - Main TTS function
- `mcp__agentvibes__list_voices` - Available voices
- `mcp__agentvibes__set_voice` - Change voice
- `mcp__agentvibes__get_config` - Current settings
- `mcp__agentvibes__set_verbosity` - Control speech frequency
- `mcp__agentvibes__set_personality` - Voice personality
- And more...

### 2. Local Bash Hooks

**Location**: `.claude/hooks/`

| Script | Purpose |
|--------|---------|
| `play-tts.sh` | Main entry point, routes to provider |
| `play-tts-piper.sh` | Piper TTS implementation |
| `play-tts-macos.sh` | macOS `say` command fallback |
| `piper-voice-manager.sh` | Voice selection/management |
| `piper-installer.sh` | Piper installation |
| `piper-download-voices.sh` | Download voice models |
| `download-extra-voices.sh` | HuggingFace custom voices |
| `voice-manager.sh` | General voice operations |
| `bootstrap-voice.sh` | Session voice initialization |

### 3. Slash Commands

**Location**: `.agent/workflows/agent-vibes:*.md`

Commands available via `/agent-vibes:<command>`:
- `/agent-vibes:whoami` - Show current voice
- `/agent-vibes:list` - List voices
- `/agent-vibes:switch` - Change voice
- `/agent-vibes:sample` - Test a voice
- `/agent-vibes:verbosity` - Get/set verbosity
- `/agent-vibes:personality` - Set personality
- `/agent-vibes:provider` - Switch TTS provider
- `/agent-vibes:update` - Update AgentVibes
- `/agent-vibes:version` - Show version
- `/agent-vibes:mute` / `/agent-vibes:unmute` - Toggle audio

### 4. TTS Protocol (Startup Hook)

**Triggered by**: Session start hook in `.claude/hooks/`

**Verbosity Levels**:
- `LOW` - Acknowledgment + Completion only
- `MEDIUM` - + Major decisions and findings
- `HIGH` - All reasoning spoken

**Required TTS Points**:
1. **Acknowledgment** - Start of task
2. **Completion** - End of task with results

## Data Flow

```
User Request
     │
     ▼
┌─────────────────┐
│ Claude Code     │
│ (reads hook)    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐     ┌─────────────────┐
│ MCP Tools       │ OR  │ Bash Hook       │
│ (mcp__agentvibes)│     │ (play-tts.sh)   │
└────────┬────────┘     └────────┬────────┘
         │                       │
         └───────────┬───────────┘
                     │
                     ▼
          ┌─────────────────┐
          │ Piper TTS       │
          │ (pipx install)  │
          └────────┬────────┘
                   │
                   ▼
          ┌─────────────────┐
          │ Voice Model     │
          │ (.onnx file)    │
          └────────┬────────┘
                   │
                   ▼
          ┌─────────────────┐
          │ Audio Output    │
          │ (.wav → afplay) │
          └─────────────────┘
```

## Configuration Files

| File | Purpose |
|------|---------|
| `.mcp.json` | MCP server definition |
| `.claude/settings.local.json` | Permissions, enabled servers |
| `.claude/config/tts-voice.txt` | Current voice selection |
| `.claude/config/tts-personality.txt` | Personality setting |
| `.claude/config/tts-verbosity.txt` | Verbosity level |
| `.claude/config/piper-speech-rate.txt` | Speech speed |
| `~/.claude/piper-voices/` | Voice model storage |

## Voice Models

**Storage**: `~/.claude/piper-voices/`

**Format**: ONNX neural network models
- `<voice>.onnx` - Model file
- `<voice>.onnx.json` - Model config

**Sources**:
- HuggingFace: `rhasspy/piper-voices`
- Custom: `/agent-vibes:add`

## Providers

| Provider | Command | Pros | Cons |
|----------|---------|------|------|
| **Piper** | `piper` via pipx | Free, offline, many voices | Requires setup |
| **macOS** | `say` command | Built-in, no setup | Limited voices |

Switch with: `/agent-vibes:provider switch <piper|macos>`

## Integration with Matrix Agents

Each Matrix agent can have a unique voice:

| Agent | Voice | Personality |
|-------|-------|-------------|
| Oracle | en_US-kristin-medium | Calm, wise |
| Neo | en_US-ryan-high | Technical |
| Trinity | en_GB-alan-medium | Confident |
| Morpheus | Custom | Wise, measured |
| Smith | en_US-danny-low | Cold, precise |

Voice assignment via `/agent-vibes:bmad` or startup hooks.

## Troubleshooting

### TTS Not Working
1. Check provider: `/agent-vibes:provider info`
2. Check mute status: `/agent-vibes:unmute`
3. Verify Piper: `~/.local/bin/piper --help`

### Voice Not Found
1. List voices: `/agent-vibes:list`
2. Download: `.claude/hooks/piper-download-voices.sh`

### MCP Server Issues
1. Check `.mcp.json` exists
2. Verify `npx agentvibes-mcp-server` runs
3. Check npm cache: `npm cache ls agentvibes`

## Version Info

- **Package**: `agentvibes` on npm
- **Current**: 2.17.8 (as of 2026-01-07)
- **Author**: Paul Preibisch
- **Repo**: https://github.com/paulpreibisch/AgentVibes
