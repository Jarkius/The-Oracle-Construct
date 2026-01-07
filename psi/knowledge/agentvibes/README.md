# AgentVibes Knowledge Base

> Last updated: 2026-01-07

## Documents

| Document | Description |
|----------|-------------|
| [Integration Architecture](./integration-architecture.md) | How AgentVibes integrates with Claude Code |
| [Piper Installation macOS](./piper-installation-macos.md) | Lessons on Piper TTS setup for Apple Silicon |
| [Matrix Council Voices](./matrix-council-voices.md) | Agent voice assignments and character design |

## Quick Reference

### Current Setup
- **Provider**: Piper TTS via pipx
- **Version**: agentvibes 2.17.8
- **Voices**: ~/.claude/piper-voices/

### Key Commands
```bash
/agent-vibes:whoami      # Current voice
/agent-vibes:list        # Available voices
/agent-vibes:switch X    # Change voice
/agent-vibes:verbosity   # Speech frequency
```

### Important Files
```
.mcp.json                        # MCP server config
.claude/hooks/play-tts.sh        # Main TTS entry point
.claude/config/tts-voice.txt     # Current voice
~/.local/bin/piper               # Piper binary (pipx)
~/.claude/piper-voices/          # Voice models
```

## See Also
- [CLAUDE.md](/CLAUDE.md) - Matrix system overview
- [Agent Workflows](/.agent/workflows/) - Council agent definitions
