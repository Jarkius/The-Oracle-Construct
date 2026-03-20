#!/usr/bin/env bun
/**
 * check-permission.ts — Permission check entrypoint for bash hooks
 *
 * Reads PreToolUse JSON from stdin, resolves agent permissions,
 * checks elevation grants, and exits with appropriate code.
 *
 * Exit codes:
 *   0 = Allow the operation (or audit-mode pass-through)
 *   2 = Block the operation (permission denied) — currently UNUSED, audit mode active
 *
 * MODE: AUDIT (log but don't block)
 * To switch to ENFORCE mode: change process.exit(0) back to process.exit(2) in denial path
 *
 * Usage (from bash hook):
 *   echo "$INPUT" | bun run scripts/security/check-permission.ts
 *
 * Environment:
 *   CLAUDE_AGENT_ID   — Agent identifier (empty = human session → always allow)
 *   CLAUDE_AGENT_TYPE — Agent type/name from frontmatter
 *   CLAUDE_PROJECT_DIR — Project directory (for finding agent definitions)
 */

import { getEnforcementEngine } from '../../lib/matrix-memory-agents/src/security/enforcement-engine';
import { appendFileSync, mkdirSync } from 'fs';
import { join } from 'path';

// Human sessions are NEVER blocked
const agentId = process.env.CLAUDE_AGENT_ID;
if (!agentId) {
  process.exit(0);
}

// Read JSON input from stdin
let input = '';
try {
  input = await Bun.stdin.text();
} catch {
  // No input — allow
  process.exit(0);
}

let toolName = '';
let toolInput: Record<string, unknown> = {};

try {
  const parsed = JSON.parse(input);
  toolName = parsed.tool_name || '';
  toolInput = parsed.tool_input || {};
} catch {
  // Malformed JSON — allow (fail open)
  process.exit(0);
}

if (!toolName) {
  process.exit(0);
}

// Resolve agent name: prefer CLAUDE_AGENT_TYPE, fallback to agent ID
const agentName = process.env.CLAUDE_AGENT_TYPE || agentId;

// Check permission
const projectDir = process.env.CLAUDE_PROJECT_DIR || process.cwd();
const engine = getEnforcementEngine(projectDir);
const result = engine.checkPermission(agentName, toolName, toolInput);

// Audit log
const logDir = join(process.env.HOME || process.env.USERPROFILE || '', '.matrix', 'coordination', 'logs');
try {
  mkdirSync(logDir, { recursive: true });
  const entry = JSON.stringify({
    ts: new Date().toISOString(),
    type: result.allowed ? 'permission:allowed' : 'permission:denied',
    agent: agentName,
    agentId,
    tool: toolName,
    allowed: result.allowed,
    reason: result.reason || undefined,
  }) + '\n';
  appendFileSync(join(logDir, 'permission-audit.jsonl'), entry);
} catch { /* non-blocking */ }

if (!result.allowed) {
  // AUDIT MODE: log what WOULD be blocked, but allow through
  // To switch to ENFORCE mode: change the final process.exit(0) to process.exit(2)
  try {
    const auditEntry = JSON.stringify({
      ts: new Date().toISOString(),
      type: 'permission:would-block',
      agent: agentName,
      agentId,
      tool: toolName,
      reason: result.reason,
      mode: 'audit',
    }) + '\n';
    appendFileSync(join(logDir, 'permission-audit.jsonl'), auditEntry);
  } catch { /* non-blocking */ }

  console.error(`[AUDIT] ${agentName} → ${toolName}: ${result.reason}`);
  process.exit(0); // AUDIT: allow through (change to exit(2) for ENFORCE mode)
}

process.exit(0);
