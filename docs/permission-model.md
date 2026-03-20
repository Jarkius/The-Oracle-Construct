# Permission Model

Runtime permission enforcement for Matrix agents (Phases 8-9).

## Agent Permission Map

| Agent | Mode | Restrictions |
|-------|------|-------------|
| Oracle | `plan` | No writes, no shell. Read/analyze only. |
| Architect | `plan` | No writes, no shell. Design/review only. |
| Scribe | `dontAsk` | Autonomous. Explicit disallowedTools respected. |
| Neo | `full` | No restrictions. Full tool access. |
| Trinity | `plan` | No writes, no shell. Design tokens only. |
| Morpheus | `dontAsk` | Autonomous. Web tools + read access. |
| Smith | `dontAsk` | Autonomous. Debug/analysis focus. |
| Tank | `read-only` | Read files only. No writes, shell, or spawning. |

## Permission Modes

| Mode | Allowed Tools | Blocked Tools |
|------|--------------|---------------|
| `full` | All | None |
| `plan` | Read, Grep, Glob | Write, Edit, NotebookEdit, Bash |
| `dontAsk` | All (minus explicit disallowedTools) | Per-agent disallowedTools |
| `read-only` | Read, Grep, Glob | Write, Edit, NotebookEdit, Bash, Agent |

## Enforcement Flow

```
Tool invocation
  |
  v
1. Check CLAUDE_AGENT_ID env var
   - Unset? -> ALLOW (human session, never blocked)
  |
  v
2. PermissionResolver: parse agent frontmatter
   - Read .claude/agents/{name}.md
   - Extract permissionMode + disallowedTools
   - Cache result
  |
  v
3. EnforcementEngine: check permission
   a. Explicit disallowedTools -> DENY
   b. Mode restrictions (plan -> no writes) -> DENY
   c. Check elevation grants -> ALLOW if valid grant
   d. Default -> ALLOW
  |
  v
4. Hook executes block or passthrough
```

## Elevation Protocol

Agents can request temporary elevated permissions when they need tools outside their normal scope.

```
1. Agent writes .request.json to ~/.matrix/coordination/elevation/
2. Orchestrator or human writes .grant.json (approves)
3. Enforcement engine checks for valid grants before denying
4. Grants auto-expire (default: 10 minutes)
5. Expired grants are cleaned up automatically
```

### Grant Structure

```json
{
  "agentId": "agent-5",
  "tool": "Bash",
  "scope": ["scripts/deploy/*"],
  "grantedBy": "orchestrator",
  "grantedAt": "2026-03-18T10:00:00Z",
  "expiresAt": "2026-03-18T10:10:00Z"
}
```

## Human Sessions

When `CLAUDE_AGENT_ID` is not set, the enforcement engine treats the session as human-operated. Human sessions are **never blocked** -- all tools are available unconditionally.

## Sacred Files

Certain files are always protected regardless of agent permissions. Even agents with `full` mode cannot modify them without explicit elevation:

- `CLAUDE.md` -- project instructions
- `SOUL.md` -- agent identity
- `USER.md` -- operator profile
- `.claude/settings.json` -- Claude Code configuration

## Tool Categories

| Category | Tools | Description |
|----------|-------|-------------|
| Write | Write, Edit, NotebookEdit | File modification |
| Exec | Bash | Command execution |
| Spawn | Agent | Sub-agent creation |
| Read | Read, Grep, Glob | Always safe, never blocked |

## Key Source Files

| File | Purpose |
|------|---------|
| `src/security/types.ts` | Permission modes, tool categories, type definitions |
| `src/security/permission-resolver.ts` | Parses agent frontmatter, caches declarations |
| `src/security/enforcement-engine.ts` | Runtime allow/deny decisions |
| `src/security/elevation.ts` | Sudo-style temporary permission grants |
| `src/security/heartbeat-watchdog.ts` | Config integrity validation |
| `scripts/security/check-permission.ts` | CLI permission check tool |
| `scripts/security/wep-audit.ts` | Permission audit utility |
