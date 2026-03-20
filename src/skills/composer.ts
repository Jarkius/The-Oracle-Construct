/**
 * Skill Composer — Bundle Resolution & Dependency Graphs
 *
 * Resolves skill bundles (skills with `compose` field) into ordered
 * execution plans. Detects circular dependencies. Computes permission
 * unions so the enforcement engine can check if an agent has all
 * required permissions for a composed skill.
 *
 * See: Phase 13 — Skill Hot-Load + Composition
 */

import { createLogger } from '../core/utils/logger';
import type { SkillManifest, SkillResolution } from './types';

const log = createLogger('SkillComposer');

export interface CompositionPlan {
  /** The root skill that triggered composition */
  root: SkillManifest;
  /** Ordered list of skills to execute (topological sort) */
  executionOrder: SkillResolution[];
  /** Union of all permissions required by component skills */
  requiredPermissions: string[];
  /** Whether composition was fully resolved */
  resolved: boolean;
  /** Errors encountered during resolution */
  errors: string[];
}

export class SkillComposer {
  private resolver: (id: string, versionRange?: string) => SkillResolution | null;

  /**
   * @param resolver Function that resolves a skill ID + version range to a SkillResolution.
   *                 Typically backed by SkillRegistry.resolve().
   */
  constructor(resolver: (id: string, versionRange?: string) => SkillResolution | null) {
    this.resolver = resolver;
  }

  /**
   * Compose a skill bundle into an ordered execution plan.
   *
   * If the skill has no `compose` field, returns a plan with just the single skill.
   * If it has `compose`, recursively resolves all components and builds a topological order.
   */
  compose(manifest: SkillManifest): CompositionPlan {
    const errors: string[] = [];
    const allPermissions = new Set<string>(manifest.permissions);
    const executionOrder: SkillResolution[] = [];
    const visiting = new Set<string>(); // For cycle detection
    const visited = new Set<string>();

    if (!manifest.compose || manifest.compose.length === 0) {
      // Not a composed skill — single execution
      return {
        root: manifest,
        executionOrder: [{
          manifest,
          path: manifest.entrypoint,
          resolved: true,
        }],
        requiredPermissions: Array.from(allPermissions),
        resolved: true,
        errors: [],
      };
    }

    // Resolve component skills via topological sort (DFS)
    const resolveComponent = (specifier: string): boolean => {
      const { id, versionRange } = this.parseSpecifier(specifier);

      if (visiting.has(id)) {
        const cycle = `Circular dependency detected: ${id} → ... → ${id}`;
        errors.push(cycle);
        log.error(cycle);
        return false;
      }

      if (visited.has(id)) return true; // Already resolved

      visiting.add(id);

      const resolution = this.resolver(id, versionRange);
      if (!resolution || !resolution.resolved) {
        errors.push(`Failed to resolve component: ${specifier}`);
        log.warn(`Unresolved component: ${specifier}`);
        visiting.delete(id);
        return false;
      }

      // Add component permissions to union
      for (const perm of resolution.manifest.permissions) {
        allPermissions.add(perm);
      }

      // Recursively resolve sub-compositions
      if (resolution.manifest.compose) {
        for (const subSpec of resolution.manifest.compose) {
          if (!resolveComponent(subSpec)) {
            // Continue resolving others even if one fails
          }
        }
      }

      // Also resolve dependencies
      if (resolution.manifest.dependencies) {
        for (const dep of resolution.manifest.dependencies) {
          if (!resolveComponent(dep)) {
            // Continue
          }
        }
      }

      visiting.delete(id);
      visited.add(id);
      executionOrder.push(resolution);
      return true;
    };

    // Resolve all compose targets
    for (const specifier of manifest.compose) {
      resolveComponent(specifier);
    }

    // Add the root skill at the end (after all components)
    executionOrder.push({
      manifest,
      path: manifest.entrypoint,
      resolved: true,
    });

    const resolved = errors.length === 0;
    if (!resolved) {
      log.warn(`Composition partially resolved for ${manifest.id}: ${errors.length} errors`);
    }

    return {
      root: manifest,
      executionOrder,
      requiredPermissions: Array.from(allPermissions),
      resolved,
      errors,
    };
  }

  /**
   * Check if an agent has all permissions required by a composed skill.
   */
  checkPermissions(plan: CompositionPlan, agentPermissions: string[]): { allowed: boolean; missing: string[] } {
    const missing = plan.requiredPermissions.filter(p => !agentPermissions.includes(p));
    return {
      allowed: missing.length === 0,
      missing,
    };
  }

  /**
   * Parse a specifier like "skill-a@^1.0" into { id, versionRange }.
   */
  private parseSpecifier(specifier: string): { id: string; versionRange?: string } {
    const atIndex = specifier.lastIndexOf('@');
    if (atIndex > 0) {
      return {
        id: specifier.slice(0, atIndex),
        versionRange: specifier.slice(atIndex + 1),
      };
    }
    return { id: specifier };
  }
}

// ============================================================================
// Singleton
// ============================================================================

let instance: SkillComposer | null = null;

export function getSkillComposer(
  resolver: (id: string, versionRange?: string) => SkillResolution | null
): SkillComposer {
  if (!instance) {
    instance = new SkillComposer(resolver);
  }
  return instance;
}
