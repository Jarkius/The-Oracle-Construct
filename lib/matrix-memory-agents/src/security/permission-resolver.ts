/**
 * Permission Resolver — Parse Agent Frontmatter
 *
 * Reads agent definition files from .claude/agents/{name}.md,
 * parses YAML frontmatter, and extracts permission declarations.
 * Caches parsed permissions for performance.
 *
 * See: docs/permission-model.md
 */

import { existsSync, readFileSync, readdirSync } from 'fs';
import { join } from 'path';
import { createLogger } from '../utils/logger';
import type { PermissionDeclaration, PermissionMode } from './types';
import { PERMISSION_MODE_MAP } from './types';

const log = createLogger('PermissionResolver');

// ============================================================================
// Permission Resolver
// ============================================================================

export class PermissionResolver {
  private cache: Map<string, PermissionDeclaration> = new Map();
  private agentsDir: string;

  constructor(projectDir?: string) {
    const base = projectDir || process.env.CLAUDE_PROJECT_DIR || process.cwd();
    this.agentsDir = join(base, '.claude', 'agents');
  }

  /**
   * Resolve permissions for a named agent.
   * Reads and caches the agent's frontmatter.
   */
  resolvePermissions(agentName: string): PermissionDeclaration | null {
    // Check cache
    const cached = this.cache.get(agentName);
    if (cached) return cached;

    // Find the agent file
    const agentFile = this.findAgentFile(agentName);
    if (!agentFile) {
      log.warn(`Agent definition not found: ${agentName}`);
      return null;
    }

    // Parse frontmatter
    const declaration = this.parseFrontmatter(agentFile, agentName);
    if (declaration) {
      this.cache.set(agentName, declaration);
    }

    return declaration;
  }

  /**
   * Resolve permissions by agent ID (looks up name from coordination status files).
   */
  resolveByAgentId(agentId: string): PermissionDeclaration | null {
    // Try agent ID as agent name first (common pattern)
    const direct = this.resolvePermissions(agentId);
    if (direct) return direct;

    // Try to find agent name from CLAUDE_AGENT_TYPE env var
    const agentType = process.env.CLAUDE_AGENT_TYPE;
    if (agentType) {
      return this.resolvePermissions(agentType);
    }

    // Try to look up from coordination status files
    const coordDir = `${process.env.HOME || process.env.USERPROFILE}/.matrix/coordination/agents`;
    try {
      if (existsSync(coordDir)) {
        const statusFile = join(coordDir, `${agentId}.status.json`);
        if (existsSync(statusFile)) {
          const status = JSON.parse(readFileSync(statusFile, 'utf8'));
          if (status.name) {
            return this.resolvePermissions(status.name);
          }
        }
      }
    } catch { /* ok */ }

    return null;
  }

  /**
   * Get all agent permission declarations.
   */
  resolveAll(): PermissionDeclaration[] {
    const declarations: PermissionDeclaration[] = [];

    try {
      if (!existsSync(this.agentsDir)) return declarations;

      for (const file of readdirSync(this.agentsDir)) {
        if (!file.endsWith('.md') || file === 'CLAUDE.md') continue;

        const name = file.replace('.md', '');
        const decl = this.resolvePermissions(name);
        if (decl) declarations.push(decl);
      }
    } catch { /* ok */ }

    return declarations;
  }

  /**
   * Clear the permission cache (e.g., after agent definitions change).
   */
  clearCache(): void {
    this.cache.clear();
  }

  // ============================================================================
  // Internal
  // ============================================================================

  private findAgentFile(agentName: string): string | null {
    if (!existsSync(this.agentsDir)) return null;

    // Direct match: {name}.md
    const directPath = join(this.agentsDir, `${agentName}.md`);
    if (existsSync(directPath)) return directPath;

    // Search by frontmatter `name` field
    try {
      for (const file of readdirSync(this.agentsDir)) {
        if (!file.endsWith('.md') || file === 'CLAUDE.md') continue;

        const filePath = join(this.agentsDir, file);
        const content = readFileSync(filePath, 'utf8');
        const frontmatter = this.extractFrontmatter(content);

        if (frontmatter && frontmatter.name === agentName) {
          return filePath;
        }
      }
    } catch { /* ok */ }

    return null;
  }

  private parseFrontmatter(filePath: string, fallbackName: string): PermissionDeclaration | null {
    try {
      const content = readFileSync(filePath, 'utf8');
      const fm = this.extractFrontmatter(content);
      if (!fm) return null;

      const agentName = fm.name || fallbackName;
      const rawMode = fm.permissionMode || 'full';
      const permissionMode: PermissionMode = PERMISSION_MODE_MAP[rawMode] || 'full';

      const allowedTools: string[] = Array.isArray(fm.tools) ? fm.tools : [];
      const disallowedTools: string[] = Array.isArray(fm.disallowedTools) ? fm.disallowedTools : [];

      return {
        agentName,
        permissionMode,
        allowedTools,
        disallowedTools,
      };
    } catch (err) {
      log.error(`Failed to parse frontmatter for ${filePath}: ${err}`);
      return null;
    }
  }

  private extractFrontmatter(content: string): Record<string, unknown> | null {
    const match = content.match(/^---\s*\n([\s\S]*?)\n---/);
    if (!match) return null;

    // Simple YAML parser — handles the flat key-value + array format used in agent definitions
    const yaml = match[1];
    const result: Record<string, unknown> = {};

    let currentKey: string | null = null;
    let currentArray: string[] | null = null;

    for (const line of yaml.split('\n')) {
      // Array item: "  - value"
      const arrayMatch = line.match(/^\s+-\s+(.+)$/);
      if (arrayMatch && currentKey && currentArray) {
        currentArray.push(arrayMatch[1].trim());
        continue;
      }

      // If we were building an array, save it
      if (currentKey && currentArray) {
        result[currentKey] = currentArray;
        currentKey = null;
        currentArray = null;
      }

      // Key-value: "key: value"
      const kvMatch = line.match(/^(\w[\w-]*)\s*:\s*(.*)$/);
      if (kvMatch) {
        const key = kvMatch[1];
        const value = kvMatch[2].trim();

        if (value === '' || value === '[]') {
          // Start of array or empty value
          currentKey = key;
          currentArray = [];
        } else {
          result[key] = value;
        }
      }
    }

    // Save any trailing array
    if (currentKey && currentArray) {
      result[currentKey] = currentArray;
    }

    return result;
  }
}

// ============================================================================
// Singleton
// ============================================================================

let instance: PermissionResolver | null = null;

export function getPermissionResolver(projectDir?: string): PermissionResolver {
  if (!instance) {
    instance = new PermissionResolver(projectDir);
  }
  return instance;
}
