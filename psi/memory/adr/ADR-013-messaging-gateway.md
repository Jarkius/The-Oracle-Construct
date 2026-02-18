# ADR-013: GATEWAY — Messaging as UI (Phase 11)

**Status**: Proposed
**Date**: 2026-02-18
**Deciders**: Oracle, Architect
**Context**: Enabling remote access to The Oracle Construct via messaging platforms
**Depends on**: ADR-012 (Heartbeat), ADR-011 (Daemon Architecture)

## Context

The Oracle Construct currently requires terminal access — the Operator must sit at the machine to interact. Between sessions, alerts go to log files. The Heartbeat daemon (ADR-012) detects problems but can only log them locally.

The missing piece: **a persistent gateway that bridges messaging platforms to the Construct**, enabling the Operator to:
- Receive alerts on their phone (heartbeat notifications)
- Check status from anywhere ("What's the status?")
- Dispatch agents remotely ("Neo, start the auth migration")
- Approve or reject proposals ("Approve that PR")

ZeroClaw's security model (pairing codes, HMAC webhook verification, tunnel-aware binding) provides a solid blueprint for the security layer.

## Decision

Build a **Messaging Gateway** as a Bun TypeScript service in `lib/matrix-memory-agents/`, managed by `matrix-services.sh`. Start with Telegram (grammY), design for multi-channel.

### Architecture

```
┌─────────────────────────────────────────────────┐
│                 matrix-gateway.ts                │
│          (managed by matrix-services.sh)         │
├──────────┬──────────┬───────────────────────────┤
│ Telegram │ Discord  │ Web UI (future)           │
│ (grammY) │(phase 2) │                           │
├──────────┴──────────┴───────────────────────────┤
│              Message Router                      │
│   Parse intent → Select agent → Build prompt     │
├─────────────────────────────────────────────────┤
│            Claude API Bridge                     │
│   Anthropic SDK · tool_use · agentic loop        │
├─────────────────────────────────────────────────┤
│          Oracle Construct Runtime                 │
│   Memory · PULSE · Tasks · Git · Files           │
└─────────────────────────────────────────────────┘
```

### Message Flow

```
Operator (Telegram) → "What's the status?"
    ↓
Gateway receives message
    ↓
Security: verify user in allowlist
    ↓
Agent Router: no agent prefix → default to Oracle
    ↓
Build system prompt:
  - Agent soul from .claude/agents/oracle-keeper.md
  - Current focus from psi/inbox/focus.md
  - Active tasks from psi/memory/tasks/active.json
    ↓
Claude API call (Sonnet tier for routine, Opus for complex):
  - System prompt: agent soul + context
  - User message: "What's the status?"
  - Tools: shell_exec, file_read, memory_recall, git_ops, pulse_events
    ↓
Agentic loop: Claude calls tools → executes → responds
    ↓
Response → format for Telegram MarkdownV2 → send
```

### Agent Routing

| Message Pattern | Agent | Model Tier |
|----------------|-------|-----------|
| `Neo, ...` or `/neo ...` | Neo | Opus |
| `@smith ...` or `/smith ...` | Smith | Opus |
| `/oracle ...` or no prefix | Oracle | Opus |
| `@tank ...` or `/tank ...` | Tank | Haiku |
| `/status` or "what's happening" | Oracle | Sonnet |
| `/tasks` | Oracle | Haiku |
| `/approve PR #N` | Oracle | Sonnet |

### Tool Definitions (Claude API)

The Gateway exposes a sandboxed subset of Oracle Construct capabilities:

```typescript
const GATEWAY_TOOLS = [
  {
    name: "shell_exec",
    description: "Execute a shell command (sandboxed)",
    // Allowlist: git, bun memory, cat, ls, grep
    // Blocklist: rm, mv, chmod, curl, wget, sudo
  },
  {
    name: "file_read",
    description: "Read a file from the workspace",
    // Scoped to workspace directory only
  },
  {
    name: "memory_recall",
    description: "Search semantic memory",
    // Wraps: bun memory recall "query"
  },
  {
    name: "task_list",
    description: "Read or update active tasks",
    // Reads/writes psi/memory/tasks/active.json
  },
  {
    name: "git_status",
    description: "Get repository status, log, diff",
    // Read-only git operations
  },
  {
    name: "pulse_events",
    description: "Read recent system events",
    // Reads psi/pulse/events.jsonl (last N)
  }
];
```

### Security Model

**Authentication**:
- Telegram user ID allowlist (configured in `.matrix.json`)
- First-time pairing: bot generates a 6-digit code, Operator enters it at terminal
- Session tokens: after pairing, no re-auth needed for 30 days

**Authorization**:
- Shell commands: strict allowlist (git, bun memory, ls, cat, grep)
- No destructive operations via gateway (no rm, no force push, no file write by default)
- File read: scoped to workspace directory (no `/etc/`, no `~/.ssh/`)
- Elevated mode: Operator sends `/sudo` → unlocks file_write and broader shell for 5 minutes

**Rate Limiting**:
- 10 messages per minute per user
- 4096 max tokens per Claude API call
- Daily token budget: configurable (default 100k tokens/day)

**Audit**:
- Every gateway interaction logged to `events.jsonl` as `gateway:message`
- Response logged as `gateway:response` with token count and duration
- Errors logged as `gateway:error`

### Heartbeat Integration

The Heartbeat daemon (ADR-012) currently logs alerts locally. With Gateway:

```
Heartbeat detects CI failure
    ↓
Writes heartbeat:alert event
    ↓
Gateway watches events.jsonl (or receives via WebSocket)
    ↓
Formats alert: "CI failed on PR #42: tests/auth.test.ts"
    ↓
Sends to Operator's Telegram
    ↓
Operator responds: "/smith investigate PR #42"
    ↓
Gateway routes to Smith agent → Claude API → investigation → response
```

### Configuration

Extend `.matrix.json`:

```json
{
  "gateway": {
    "enabled": true,
    "port": 8082,
    "channels": {
      "telegram": {
        "enabled": true,
        "bot_token_env": "TELEGRAM_BOT_TOKEN",
        "allowed_users": ["telegram_user_id"]
      }
    },
    "security": {
      "allowed_users_only": true,
      "sandbox_shell": true,
      "max_tokens_per_message": 4096,
      "daily_token_budget": 100000,
      "rate_limit_per_minute": 10,
      "pairing_required": true,
      "elevated_timeout_minutes": 5
    },
    "claude": {
      "api_key_env": "ANTHROPIC_API_KEY",
      "default_model": "claude-sonnet-4-5-20250929",
      "opus_model": "claude-opus-4-6",
      "haiku_model": "claude-haiku-4-5-20251001"
    }
  }
}
```

### Dependencies

```bash
bun add grammy                # Telegram Bot API (lightweight, TypeScript-native)
bun add @anthropic-ai/sdk     # Claude API for tool_use
```

**Why grammY over telegraf?** TypeScript-first, better Bun compatibility, active maintenance, simpler API. No dependency on Node.js-specific features.

**Why not discord.js yet?** Telegram is simpler (1 user, no channel management), lower latency, better mobile experience. Discord support is Phase 2.

### Event Types

```
gateway:start      — gateway service started
gateway:stop       — gateway service stopped
gateway:connect    — channel connected (telegram online)
gateway:disconnect — channel disconnected
gateway:message    — incoming user message
gateway:response   — outgoing response (tokens, duration, agent)
gateway:error      — processing failure
gateway:pair       — new device paired
gateway:elevate    — sudo mode activated
```

## Alternatives Considered

1. **WhatsApp** — Unofficial API, ban risk. Rejected.
2. **Slack** — Enterprise-focused, overkill for personal construct. Deferred.
3. **SMS via Twilio** — Costs per message, no rich formatting. Rejected.
4. **Email** — Too slow, no real-time interaction. Rejected.
5. **Custom mobile app** — Development overhead too high. Telegram is the app.
6. **Web dashboard only** — No push notifications, requires browser. Gateway can add web later.

## Consequences

### Positive
- Operator can reach the Construct from anywhere (phone, tablet, any device)
- Heartbeat alerts become actionable (not just logged)
- Agent dispatch from mobile enables truly autonomous operation
- Foundation for multi-channel (Discord, web UI) in Phase 2
- Daily token budget prevents runaway costs

### Negative
- Requires Telegram Bot Token (BotFather setup)
- Requires Anthropic API key (costs per message)
- New attack surface (mitigated by allowlist + pairing + rate limiting)
- Gateway must be running for notifications (managed by matrix-services.sh)

### Risks
- **Token budget exhaustion**: Mitigated by daily cap + per-message cap
- **Unauthorized access**: Mitigated by allowlist + pairing code + Telegram user ID verification
- **Prompt injection via Telegram**: Mitigated by sandboxed tools + shell allowlist
- **Gateway crash loops**: Mitigated by matrix-services.sh restart logic

## Implementation Plan

| Step | What | Effort |
|------|------|--------|
| B1 | Dependencies (grammy, @anthropic-ai/sdk) | ~15m |
| B2 | Gateway config in .matrix.json | ~30m |
| B3 | Agent Router (intent parsing, soul loading) | ~1.5h |
| B4 | Claude API Bridge (tool definitions, agentic loop) | ~2h |
| B5 | Telegram Adapter (grammY bot, formatting) | ~1.5h |
| B6 | Security Layer (allowlist, pairing, rate limiting) | ~1.5h |
| B7 | Register in matrix-services.sh | ~30m |
| B8 | Heartbeat → Gateway bridge | ~1h |
| B9 | End-to-end testing | ~1h |

**Total: ~2-3 sessions**

## Prerequisites

- [ ] Create Telegram bot via @BotFather → get `TELEGRAM_BOT_TOKEN`
- [ ] Set `ANTHROPIC_API_KEY` environment variable
- [ ] Decide on gateway port (proposed: 8082)
- [ ] Get Operator's Telegram user ID for allowlist

## Related

- ADR-012: Heartbeat Daemon (notification source)
- ADR-011: Modular Daemon Architecture (service lifecycle)
- ADR-015: True Self-Evolution (Tier 2 uses Claude API from Gateway infra)
- ADR-003: Hierarchical Mind Architecture (model tier routing)
