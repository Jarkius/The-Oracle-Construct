/**
 * Security Types — Permission Enforcement Layer
 *
 * Type definitions for the runtime permission enforcement engine.
 * Agent frontmatter declares permissions (permissionMode, disallowedTools),
 * but Claude Code does NOT enforce them. This module makes them real.
 *
 * See: docs/permission-model.md
 */

// ============================================================================
// Permission Modes
// ============================================================================

/**
 * Maps to agent frontmatter `permissionMode` field.
 *
 * - full:      Agent can use all tools (acceptEdits equivalent)
 * - plan:      Agent can only read/analyze. No writes, no shell.
 * - dontAsk:   Agent runs autonomously but may have tool restrictions.
 * - read-only: Agent can only read files. Strictest mode.
 */
export type PermissionMode = 'full' | 'plan' | 'dontAsk' | 'read-only';

/**
 * Mapping from Claude Code frontmatter permissionMode values to our canonical modes.
 */
export const PERMISSION_MODE_MAP: Record<string, PermissionMode> = {
  acceptEdits: 'full',
  plan: 'plan',
  dontAsk: 'dontAsk',
  'read-only': 'read-only',
  // Fallbacks
  full: 'full',
};

// ============================================================================
// Permission Declaration
// ============================================================================

/**
 * Parsed permission declaration from an agent's frontmatter.
 */
export interface PermissionDeclaration {
  agentName: string;
  permissionMode: PermissionMode;
  allowedTools: string[];
  disallowedTools: string[];
}

// ============================================================================
// Permission Check Result
// ============================================================================

export interface PermissionCheckResult {
  allowed: boolean;
  reason?: string;
  agent?: string;
  tool?: string;
  elevationAvailable?: boolean;
}

// ============================================================================
// Elevation (Sudo)
// ============================================================================

export interface ElevationRequest {
  agentId: string;
  agentName: string;
  tool: string;
  scope: string[];          // file patterns or tool names
  reason: string;
  requestedAt: string;      // ISO 8601
}

export interface ElevationGrant {
  agentId: string;
  tool: string;
  scope: string[];
  grantedBy: string;        // "orchestrator" or "human"
  grantedAt: string;        // ISO 8601
  expiresAt: string;        // ISO 8601
}

// ============================================================================
// Tool Categories
// ============================================================================

/**
 * Tools that modify files or system state.
 */
export const WRITE_TOOLS = ['Write', 'Edit', 'NotebookEdit'] as const;

/**
 * Tools that execute arbitrary commands.
 */
export const EXEC_TOOLS = ['Bash'] as const;

/**
 * Tools that spawn other agents.
 */
export const SPAWN_TOOLS = ['Agent'] as const;

/**
 * Tools that are always safe (read-only).
 */
export const READ_TOOLS = ['Read', 'Grep', 'Glob'] as const;

/**
 * Default tool restrictions per permission mode.
 * These apply even if the agent frontmatter doesn't explicitly list disallowedTools.
 */
export const MODE_RESTRICTIONS: Record<PermissionMode, string[]> = {
  full: [],                                    // No restrictions
  plan: ['Write', 'Edit', 'NotebookEdit', 'Bash'],  // Design-only: no writes, no shell
  dontAsk: [],                                 // Autonomous but respects explicit disallowedTools
  'read-only': ['Write', 'Edit', 'NotebookEdit', 'Bash', 'Agent'],  // Read-only: no writes, shell, or spawning
};
