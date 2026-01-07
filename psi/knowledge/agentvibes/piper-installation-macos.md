# Piper TTS Installation on macOS

> Lesson learned: 2026-01-07

## Summary

On macOS Apple Silicon (M1/M2/M3), the **pipx installation** of Piper TTS is superior to precompiled native binaries.

## Key Findings

### 1. Package Name Confusion

| Name | Source | Status |
|------|--------|--------|
| `agentvibes` | npm | ✅ Correct - MCP server |
| `agent-vibes` | npm | ❌ Does not exist |
| `piper-tts` | pipx/PyPI | ✅ Correct - TTS engine |

**Fix**: Update slash commands that reference `agent-vibes` to use `agentvibes`.

### 2. Piper Installation Methods

| Method | Platform | Pros | Cons |
|--------|----------|------|------|
| **pipx** | All | Native ARM, auto-deps, easy update | Slightly slower startup |
| **Native binary** | Linux/Intel Mac | Fastest | Library issues on ARM Mac |
| **Homebrew** | macOS | Easy install | Not available for piper |

### 3. Native Binary Issues on Apple Silicon

The precompiled binary from `rhasspy/piper` releases:
- URL: `piper_macos_aarch64.tar.gz`
- Actual arch: **x86_64** (mislabeled!)
- Required libs: `libespeak-ng.1.dylib`, `libpiper_phonemize.1.dylib`, `libonnxruntime.1.14.1.dylib`
- Result: Hangs when run via Rosetta, library path issues

### 4. Current Working Setup

```
Installation: pipx install piper-tts
Binary: ~/.local/bin/piper → symlink to pipx venv
Version: piper-tts 1.3.0
Voices: ~/.claude/piper-voices/
```

## Architecture Diagram

```
AgentVibes Stack (macOS Apple Silicon)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

┌─────────────────────────────────────┐
│  Claude Code                        │
│  └── MCP Server (agentvibes)        │
│      └── npx agentvibes-mcp-server  │
└─────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│  .claude/hooks/play-tts.sh          │
│  └── play-tts-piper.sh              │
└─────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│  Piper TTS (via pipx)               │
│  ~/.local/bin/piper                 │
│  └── ~/.local/pipx/venvs/piper-tts/ │
└─────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│  Voice Models                       │
│  ~/.claude/piper-voices/*.onnx      │
└─────────────────────────────────────┘
```

## Recommendations

1. **Keep pipx installation** - Best for Apple Silicon
2. **Don't use native binary** - x86_64 only, library issues
3. **Update with**: `pipx upgrade piper-tts`
4. **Check MCP config**: `.mcp.json` defines agentvibes server

## Related Files

- `.mcp.json` - MCP server configuration
- `.claude/settings.local.json` - Permissions and enabled servers
- `.claude/hooks/piper-installer.sh` - Installation script (needs ARM fix)
- `~/.claude/piper-voices/` - Voice model storage

## Future Improvements

1. Fix `piper-installer.sh` to recommend pipx on macOS ARM
2. Update `/agent-vibes:update` command to use correct package name
3. Consider adding ARM64 native binary support when available from rhasspy
