# ADR-004: Context Token Optimization

**Status**: Accepted
**Date**: 2026-01-13
**Author**: Architect

## Context

At session start, The Matrix consumes ~31k/200k tokens (15%) before any user interaction. Analysis revealed several high-cost MCP tools with questionable value for Opus 4.5.

### Token Breakdown (Pre-Optimization)

| Category | Tokens | % of Total |
|----------|--------|------------|
| System tools | 17.0k | 8.5% |
| **MCP tools** | **8.1k** | 4.1% |
| System prompt | 3.0k | 1.5% |
| Compact buffer | 3.0k | 1.5% |
| Memory files | 1.4k | 0.7% |
| Skills | 1.0k | 0.5% |

## Decision

### Remove `sequential-thinking` MCP (1.1k tokens saved)

**Rationale**: The `@modelcontextprotocol/server-sequential-thinking` MCP was designed to scaffold step-by-step reasoning for earlier language models. Opus 4.5 has native chain-of-thought reasoning built into its architecture, making this external scaffolding redundant.

**Evidence**:
- Opus 4.5 naturally produces structured reasoning without prompting
- The MCP adds 1.1k tokens for a single tool that duplicates native capability
- No active workflows in The Matrix depend on this MCP

### Remove AgentVibes MCP (3.5k tokens saved)

**Rationale**: Analysis revealed that the Matrix voice system (`psi/matrix/voice.sh`) calls Piper TTS directly via shell commands - it does NOT use the AgentVibes MCP at all. AgentVibes is a completely independent TTS system.

**Architecture Discovery**:
```
Matrix Voice:    voice.sh → voice_server.py → Piper TTS (direct)
AgentVibes MCP:  MCP tools → separate TTS system (unused)
```

**Evidence**:
- `voice.sh` dependencies: Piper binary, voice models, afplay, ffmpeg
- No MCP tool calls anywhere in Matrix voice workflows
- AgentVibes MCP adds 27 tools consuming ~3.5k tokens for zero benefit

**Wisdom Extracted**: Before removal, key patterns documented in `psi/learn/active/agentvibes-patterns.md`:
- SessionStart hook injection pattern
- Provider abstraction architecture
- Shell script security best practices
- Language learning mode concept

### Retain `context7` MCP (907 tokens)

**Rationale**: Context7 provides real-time library documentation lookup, which is valuable for development tasks and cannot be replicated by the model's training data alone.

## Consequences

### Positive
- **~4.6k total token savings per session** (1.1k + 3.5k)
- Reduced latency (two fewer MCP servers to spawn)
- Cleaner tool namespace
- Baseline reduced from ~31k to ~26k tokens (13% of context)

### Negative
- Users who explicitly want structured thinking scaffolding lose that option
- Minimal: Opus 4.5 native reasoning is superior anyway
- AgentVibes MCP tools no longer available (but were never used)

## Implementation

### Phase 1 (Completed)
1. Remove `sequential-thinking` from project MCP config in `~/.claude.json`
2. Remove permission from `.claude/settings.local.json`

### Phase 2 (Completed)
1. Extract wisdom from AgentVibes to `psi/learn/active/agentvibes-patterns.md`
2. Remove `agentvibes` from `.mcp.json` project config
3. Research folder preserved at `psi/lab/research/AgentVibes_Research/`

## References

- [Opus 4.5 Announcement](https://www.anthropic.com/news/opus-4.5) - Native reasoning capabilities
- ADR-003: Hierarchical Mind Architecture - Model tier decisions
