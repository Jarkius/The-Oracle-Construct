# ADR-018: Messaging Gateway (Phase C)

**Status**: Accepted
**Date**: 2026-02-18
**Deciders**: Oracle, Architect

## Context

The Oracle Construct operates within Claude Code sessions — no persistent UI, no way to receive messages between sessions. The Operator has no visibility into system state unless actively in a session.

Heartbeat (ADR-012) checks health. Event Dispatcher (ADR-016) routes events to agents. But neither can reach the Operator when they're away from the terminal.

The Operator has Gemini and GPT API keys but only a Claude subscription (no Claude API key). The gateway must support multiple LLM providers.

## Decision

Build a **Telegram Gateway** that bridges messaging to the Oracle Construct's agent system with multi-provider LLM support.

### Architecture

```
Telegram (grammY)
    │
    ├── /neo fix the tests       → Agent Router → LLM Provider (Gemini/GPT/Claude)
    ├── @smith investigate CI     → Agent Router → Tool Use Loop → Response
    ├── /status                   → Direct system query
    │
    ├── Heartbeat Alerts ←──── HTTP /notify endpoint
    │
    └── Security Layer
        ├── Allowlist
        ├── Rate limiting
        ├── Token budget
        ├── Shell sandbox
        └── Pairing codes
```

### Multi-Provider Design

```
Provider Abstraction (providers.ts)
    ├── GeminiProvider  ← GOOGLE_API_KEY / GEMINI_API_KEY
    ├── OpenAIProvider  ← OPENAI_API_KEY
    └── AnthropicProvider ← ANTHROPIC_API_KEY (optional)

Auto-detection: whichever env var is set, that provider is used.
Priority: Gemini > OpenAI > Anthropic (configurable in .matrix.json)
```

### Agent Tier → Model Mapping

| Tier | Gemini | OpenAI | Anthropic |
|------|--------|--------|-----------|
| Opus | gemini-2.0-flash | gpt-4o | claude-opus-4-6 |
| Sonnet | gemini-2.0-flash | gpt-4o-mini | claude-sonnet-4-5 |
| Haiku | gemini-2.0-flash-lite | gpt-4o-mini | claude-haiku-4-5 |

### Security Layers

1. **User allowlist** — only pre-approved Telegram user IDs
2. **Pairing codes** — verify device ownership
3. **Rate limiting** — per-user, per-minute
4. **Token budget** — daily cap per user
5. **Shell sandbox** — allowlisted commands only
6. **Path sandbox** — blocks .env, .ssh, credentials
7. **Elevated mode** — time-limited expanded access via /sudo

### Tool Use

All three providers support function calling. The gateway normalizes this into a unified loop:

1. Send message with tool definitions
2. If provider returns tool calls → execute sandboxed tools
3. Feed results back → continue until text response
4. Max 10 iterations per message

### Tools Available via Gateway

| Tool | Description |
|------|-------------|
| shell_exec | Sandboxed shell commands |
| file_read | Read workspace files |
| memory_recall | Semantic memory search |
| task_list | Active task registry |
| git_status | Repository state |
| pulse_events | System event queue |
| dispatch | Event dispatcher |

## Consequences

### Positive
- Operator can interact with agents from phone/tablet
- Heartbeat alerts reach Operator between sessions
- No Claude API key required — works with Gemini or GPT
- Provider-agnostic design future-proofs against API changes
- Security-first: multiple defense layers

### Negative
- Telegram dependency for messaging channel
- LLM API costs for each message (mitigated by token budget)
- Agent personality may differ slightly across providers
- Tool calling behavior varies between providers

### Configuration

```json
// .matrix.json → gateway section
{
  "gateway": {
    "enabled": true,
    "llm": {
      "provider": "auto",
      "gemini": { "opus": "gemini-2.0-flash", "sonnet": "gemini-2.0-flash", "haiku": "gemini-2.0-flash-lite" }
    },
    "channels": {
      "telegram": {
        "allowed_users": ["YOUR_TELEGRAM_USER_ID"]
      }
    },
    "security": {
      "daily_token_budget": 100000,
      "rate_limit_per_minute": 10
    }
  }
}
```

### Setup

1. Create bot via @BotFather → get token
2. `export TELEGRAM_BOT_TOKEN="your-token"`
3. `export GOOGLE_API_KEY="your-key"` (or OPENAI_API_KEY)
4. `bash .claude/hooks/matrix-services.sh start gateway`
5. Send `/start` to your bot

## Files

- `lib/matrix-memory-agents/src/gateway/matrix-gateway.ts` — Main bot + LLM bridge
- `lib/matrix-memory-agents/src/gateway/providers.ts` — Multi-provider abstraction
- `lib/matrix-memory-agents/src/gateway/agent-router.ts` — Intent parsing + routing
- `lib/matrix-memory-agents/src/gateway/security.ts` — All security layers
- `lib/matrix-memory-agents/src/gateway/tools.ts` — Sandboxed tool definitions
- `lib/matrix-memory-agents/src/gateway/types.ts` — Type definitions
- `.claude/hooks/matrix-services.sh` — Service lifecycle (gateway_start/stop/status)
