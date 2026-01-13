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

### Retain `context7` MCP (907 tokens)

**Rationale**: Context7 provides real-time library documentation lookup, which is valuable for development tasks and cannot be replicated by the model's training data alone.

### Future Consideration: AgentVibes Slim Profile

The AgentVibes MCP contributes 27 tools (~3.5k tokens). A future optimization could:
- Create a "slim" profile with 10 core tools (~1.4k tokens)
- Move audio effects (reverb, background music, etc.) to on-demand activation

## Consequences

### Positive
- ~1.1k token savings per session
- Reduced latency (one fewer MCP server to spawn)
- Cleaner tool namespace

### Negative
- Users who explicitly want structured thinking scaffolding lose that option
- Minimal: Opus 4.5 native reasoning is superior anyway

## Implementation

1. Remove `sequential-thinking` from project MCP config in `~/.claude.json`
2. Remove permission for `mcp__sequential-thinking__sequentialthinking` from `.claude/settings.local.json`

## References

- [Opus 4.5 Announcement](https://www.anthropic.com/news/opus-4.5) - Native reasoning capabilities
- ADR-003: Hierarchical Mind Architecture - Model tier decisions
