/**
 * Enforcement Engine — Runtime Permission Checking
 *
 * Core logic that determines whether an agent is allowed to use a specific tool.
 * Combines permission mode restrictions, explicit disallowedTools, and elevation grants.
 *
 * Decision flow:
 *   1. No agent ID / human session → ALLOW (humans are NEVER blocked)
 *   2. Resolve agent permissions from frontmatter
 *   3. Check explicit disallowedTools → DENY if listed
 *   4. Check mode restrictions (plan → no writes) → DENY if restricted
 *   5. Check elevation grants → ALLOW if valid grant exists
 *   6. ALLOW (default)
 *
 * See: docs/permission-model.md
 */

import { createLogger } from '../utils/logger';
import { PermissionResolver, getPermissionResolver } from './permission-resolver';
import { getElevationManager } from './elevation';
import type { PermissionCheckResult, PermissionDeclaration } from './types';
import { MODE_RESTRICTIONS } from './types';

const log = createLogger('EnforcementEngine');

// ============================================================================
// Enforcement Engine
// ============================================================================

export class EnforcementEngine {
  private projectDir?: string;
  private resolver: PermissionResolver;

  constructor(projectDir?: string) {
    this.projectDir = projectDir;
    // Create own resolver instance when projectDir is explicit (avoids stale singleton)
    this.resolver = projectDir ? new PermissionResolver(projectDir) : getPermissionResolver();
  }

  /**
   * Check if an agent is allowed to use a specific tool.
   *
   * @param agentName - The agent's name (from frontmatter) or agent ID
   * @param toolName  - The tool being invoked (e.g., "Write", "Edit", "Bash")
   * @param toolInput - Optional tool input for scope-aware checks
   * @returns PermissionCheckResult with allowed/denied and reason
   */
  checkPermission(agentName: string, toolName: string, toolInput?: Record<string, unknown>): PermissionCheckResult {
    // Resolve agent permissions
    const declaration = this.resolver.resolvePermissions(agentName)
      || this.resolver.resolveByAgentId(agentName);

    if (!declaration) {
      // Unknown agent — allow by default (fail open for backward compat)
      log.warn(`Unknown agent "${agentName}" — allowing by default`);
      return { allowed: true, agent: agentName, tool: toolName };
    }

    return this.checkAgentPermission(declaration, toolName, toolInput);
  }

  /**
   * Check permission against a resolved declaration.
   */
  private checkAgentPermission(
    declaration: PermissionDeclaration,
    toolName: string,
    toolInput?: Record<string, unknown>
  ): PermissionCheckResult {
    const { agentName, permissionMode, disallowedTools } = declaration;

    // Check 1: Explicitly disallowed tools (highest priority)
    if (disallowedTools.includes(toolName)) {
      return {
        allowed: false,
        reason: `Tool "${toolName}" is explicitly disallowed for agent "${agentName}" (disallowedTools)`,
        agent: agentName,
        tool: toolName,
        elevationAvailable: true,
      };
    }

    // Check 2: Mode-based restrictions
    const modeRestrictions = MODE_RESTRICTIONS[permissionMode] || [];
    if (modeRestrictions.includes(toolName)) {
      // Check for elevation grant before denying
      const elevation = getElevationManager();
      const grant = elevation.checkElevation(agentName, toolName);
      if (grant) {
        log.info(`Agent "${agentName}" using elevated permission for "${toolName}" (granted by ${grant.grantedBy})`);
        return { allowed: true, agent: agentName, tool: toolName };
      }

      return {
        allowed: false,
        reason: `Agent "${agentName}" has permissionMode="${permissionMode}" which restricts "${toolName}"`,
        agent: agentName,
        tool: toolName,
        elevationAvailable: true,
      };
    }

    // Check 3: Allowed tools list (if specified, tool must be in it)
    if (declaration.allowedTools.length > 0 && !declaration.allowedTools.includes(toolName)) {
      // Some tools (Skill, WebSearch, WebFetch) might not be in the allowed list
      // but aren't dangerous — only block if the tool is in a restricted category
      const isRestrictedCategory = [...disallowedTools, ...modeRestrictions].includes(toolName);
      if (isRestrictedCategory) {
        return {
          allowed: false,
          reason: `Tool "${toolName}" is not in agent "${agentName}" allowed tools list`,
          agent: agentName,
          tool: toolName,
          elevationAvailable: true,
        };
      }
    }

    // All checks passed
    return { allowed: true, agent: agentName, tool: toolName };
  }

  /**
   * Batch check: get all restricted tools for an agent.
   * Useful for reporting/auditing.
   */
  getRestrictedTools(agentName: string): string[] {
    const declaration = this.resolver.resolvePermissions(agentName);
    if (!declaration) return [];

    const restricted = new Set<string>();

    // From explicit disallowedTools
    for (const tool of declaration.disallowedTools) {
      restricted.add(tool);
    }

    // From mode restrictions
    const modeRestrictions = MODE_RESTRICTIONS[declaration.permissionMode] || [];
    for (const tool of modeRestrictions) {
      restricted.add(tool);
    }

    return Array.from(restricted);
  }
}

// ============================================================================
// Singleton
// ============================================================================

let instance: EnforcementEngine | null = null;

export function getEnforcementEngine(projectDir?: string): EnforcementEngine {
  if (!instance) {
    instance = new EnforcementEngine(projectDir);
  }
  return instance;
}
