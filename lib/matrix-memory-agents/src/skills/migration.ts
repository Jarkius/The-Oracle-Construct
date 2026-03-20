/**
 * Skill Registry Migration
 *
 * Imports the existing flat skill-registry.json into the SQLite-backed
 * SkillRegistry, assigning version 1.0.0 to every discovered skill.
 */

import { existsSync, readFileSync } from 'fs';
import { resolve } from 'path';
import { createLogger } from '../utils/logger';
import { getSkillRegistry } from './registry';
import type { SkillManifest } from './types';

const log = createLogger('SkillMigration');

/** Shape of a single entry in the legacy skill-registry.json */
interface LegacySkillEntry {
  id: string;
  path: string;
  name: string;
  description: string;
  agent?: string;
  user_invocable?: boolean;
  has_frontmatter?: boolean;
  size_bytes?: number;
  modified?: string;
  discovered_at?: string;
}

interface LegacySkillRegistry {
  skills: Record<string, LegacySkillEntry>;
  last_scan?: string;
  total?: number;
}

/**
 * Default path to the legacy skill registry JSON.
 * Resolves relative to the matrix root (4 levels up from src/skills/).
 */
const DEFAULT_LEGACY_PATH = resolve(
  __dirname, '..', '..', '..', '..', 'psi', 'state', 'pulse', 'skill-registry.json',
);

/**
 * Derive tags from a legacy skill entry based on its path and id.
 */
function deriveTags(entry: LegacySkillEntry): string[] {
  const tags: string[] = [];

  // Tag based on path location
  if (entry.path.includes('.agent/workflows/')) tags.push('workflow');
  if (entry.path.includes('.claude/commands/')) tags.push('command');

  // Tag based on id namespace (e.g. "learn:concept" -> "learn")
  if (entry.id.includes(':')) {
    tags.push(entry.id.split(':')[0]);
  }

  // Tag if user-invocable
  if (entry.user_invocable) tags.push('user-invocable');

  return tags;
}

/**
 * Convert a legacy entry to a SkillManifest at version 1.0.0.
 */
function toManifest(entry: LegacySkillEntry): SkillManifest {
  return {
    id: entry.id,
    version: '1.0.0',
    description: entry.description,
    author: entry.agent ?? undefined,
    dependencies: [],
    entrypoint: entry.path,
    permissions: [],
    tags: deriveTags(entry),
  };
}

/**
 * Migrate legacy skill-registry.json into the SQLite skill registry.
 *
 * @param jsonPath - Path to the legacy JSON file (defaults to psi/state/pulse/skill-registry.json)
 * @returns Number of skills migrated
 */
export function migrateSkillRegistry(jsonPath?: string): number {
  const filePath = jsonPath ?? DEFAULT_LEGACY_PATH;

  if (!existsSync(filePath)) {
    log.warn('Legacy skill registry not found, skipping migration', { path: filePath });
    return 0;
  }

  let data: LegacySkillRegistry;
  try {
    const raw = readFileSync(filePath, 'utf-8');
    data = JSON.parse(raw) as LegacySkillRegistry;
  } catch (err) {
    log.error('Failed to parse legacy skill registry', { path: filePath, error: String(err) });
    return 0;
  }

  if (!data.skills || typeof data.skills !== 'object') {
    log.warn('Legacy skill registry has no skills object', { path: filePath });
    return 0;
  }

  const registry = getSkillRegistry();
  let count = 0;

  for (const [_key, entry] of Object.entries(data.skills)) {
    try {
      const manifest = toManifest(entry);
      registry.register(manifest, entry.path);
      count++;
    } catch (err) {
      log.error('Failed to migrate skill', { id: entry.id, error: String(err) });
    }
  }

  log.info('Migration complete', { migrated: count, total: Object.keys(data.skills).length });
  return count;
}
