/**
 * Skill Registry — SQLite-backed skill registration, resolution, and lifecycle
 *
 * Singleton registry that stores skill manifests with versioning.
 * Uses the same DB patterns as src/db/core.ts.
 */

import { db } from '../core/db/core';
import { createLogger } from '../core/utils/logger';
import type { SkillManifest, SkillVersion, SkillResolution } from './types';
import { satisfies, latest, compareSemver } from './versioning';

const log = createLogger('SkillRegistry');

// ============================================================================
// Schema
// ============================================================================

function ensureSchema(): void {
  db.exec(`
    CREATE TABLE IF NOT EXISTS skill_registry (
      id TEXT NOT NULL,
      version TEXT NOT NULL,
      manifest_json TEXT NOT NULL,
      path TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'active',
      installed_at TEXT NOT NULL,
      last_used TEXT,
      PRIMARY KEY (id, version)
    )
  `);
  // Index for tag-based and status queries
  db.exec(`
    CREATE INDEX IF NOT EXISTS idx_skill_registry_status
      ON skill_registry(status)
  `);
}

// Initialize schema on module load
ensureSchema();

// ============================================================================
// Prepared statements
// ============================================================================

const stmts = {
  insert: db.prepare(`
    INSERT OR REPLACE INTO skill_registry
      (id, version, manifest_json, path, status, installed_at, last_used)
    VALUES (?, ?, ?, ?, 'active', ?, NULL)
  `),

  getByIdVersion: db.prepare(`
    SELECT * FROM skill_registry WHERE id = ? AND version = ?
  `),

  getAllVersions: db.prepare(`
    SELECT * FROM skill_registry WHERE id = ? ORDER BY installed_at DESC
  `),

  getActive: db.prepare(`
    SELECT * FROM skill_registry WHERE id = ? AND status = 'active'
  `),

  updateLastUsed: db.prepare(`
    UPDATE skill_registry SET last_used = ? WHERE id = ? AND version = ?
  `),

  deprecate: db.prepare(`
    UPDATE skill_registry SET status = 'deprecated' WHERE id = ? AND version = ?
  `),

  searchByQuery: db.prepare(`
    SELECT * FROM skill_registry
    WHERE status = 'active'
      AND (id LIKE ? OR manifest_json LIKE ?)
    ORDER BY id, installed_at DESC
  `),

  listAll: db.prepare(`
    SELECT * FROM skill_registry WHERE status = 'active' ORDER BY id
  `),
};

// ============================================================================
// Row helpers
// ============================================================================

interface SkillRow {
  id: string;
  version: string;
  manifest_json: string;
  path: string;
  status: string;
  installed_at: string;
  last_used: string | null;
}

function rowToManifest(row: SkillRow): SkillManifest {
  return JSON.parse(row.manifest_json) as SkillManifest;
}

function rowToVersion(row: SkillRow): SkillVersion {
  return {
    id: row.id,
    version: row.version,
    installedAt: row.installed_at,
    lastUsed: row.last_used ?? undefined,
    status: row.status as SkillVersion['status'],
  };
}

// ============================================================================
// SkillRegistry class
// ============================================================================

export class SkillRegistry {
  /**
   * Register a skill manifest at a given path.
   * If the same id+version already exists it will be replaced.
   */
  register(manifest: SkillManifest, path: string): void {
    const now = new Date().toISOString();
    stmts.insert.run(
      manifest.id,
      manifest.version,
      JSON.stringify(manifest),
      path,
      now,
    );
    log.info('Registered skill', { id: manifest.id, version: manifest.version, path });
  }

  /**
   * Resolve a skill by id and optional version range.
   * If no range is provided, returns the latest active version.
   * Touches last_used on successful resolution.
   */
  resolve(id: string, versionRange?: string): SkillResolution | null {
    const rows = stmts.getActive.all(id) as SkillRow[];
    if (rows.length === 0) return null;

    let match: SkillRow | undefined;

    if (versionRange) {
      // Find the latest version satisfying the range
      const candidates = rows.filter(r => satisfies(r.version, versionRange));
      if (candidates.length === 0) return null;
      const bestVersion = latest(candidates.map(r => r.version));
      match = candidates.find(r => r.version === bestVersion);
    } else {
      // Pick latest active version
      const bestVersion = latest(rows.map(r => r.version));
      match = rows.find(r => r.version === bestVersion);
    }

    if (!match) return null;

    // Touch last_used
    stmts.updateLastUsed.run(new Date().toISOString(), match.id, match.version);

    return {
      manifest: rowToManifest(match),
      path: match.path,
      resolved: true,
    };
  }

  /**
   * Full-text search across skill ids and manifest JSON.
   */
  search(query: string): SkillResolution[] {
    const like = `%${query}%`;
    const rows = stmts.searchByQuery.all(like, like) as SkillRow[];

    // Deduplicate: keep only latest version per id
    const byId = new Map<string, SkillRow>();
    for (const row of rows) {
      const existing = byId.get(row.id);
      if (!existing || compareSemver(row.version, existing.version) > 0) {
        byId.set(row.id, row);
      }
    }

    return Array.from(byId.values()).map(row => ({
      manifest: rowToManifest(row),
      path: row.path,
      resolved: true,
    }));
  }

  /**
   * List all active skills that have a specific tag.
   */
  listByTag(tag: string): SkillResolution[] {
    // Tags are stored inside manifest_json; use a LIKE filter then
    // verify in JS for accuracy.
    const like = `%"${tag}"%`;
    const rows = (stmts.searchByQuery.all(like, like) as SkillRow[])
      .filter(row => {
        const manifest = rowToManifest(row);
        return manifest.tags.includes(tag);
      });

    // Deduplicate to latest version per id
    const byId = new Map<string, SkillRow>();
    for (const row of rows) {
      const existing = byId.get(row.id);
      if (!existing || compareSemver(row.version, existing.version) > 0) {
        byId.set(row.id, row);
      }
    }

    return Array.from(byId.values()).map(row => ({
      manifest: rowToManifest(row),
      path: row.path,
      resolved: true,
    }));
  }

  /**
   * Get the full version history for a skill.
   */
  getVersionHistory(id: string): SkillVersion[] {
    const rows = stmts.getAllVersions.all(id) as SkillRow[];
    return rows.map(rowToVersion);
  }

  /**
   * Mark a specific version of a skill as deprecated.
   */
  deprecate(id: string, version: string): boolean {
    const row = stmts.getByIdVersion.get(id, version) as SkillRow | undefined;
    if (!row) {
      log.warn('Cannot deprecate: skill version not found', { id, version });
      return false;
    }
    stmts.deprecate.run(id, version);
    log.info('Deprecated skill', { id, version });
    return true;
  }

  /**
   * List all active skills (latest version each).
   */
  listAll(): SkillResolution[] {
    const rows = stmts.listAll.all() as SkillRow[];

    const byId = new Map<string, SkillRow>();
    for (const row of rows) {
      const existing = byId.get(row.id);
      if (!existing || compareSemver(row.version, existing.version) > 0) {
        byId.set(row.id, row);
      }
    }

    return Array.from(byId.values()).map(row => ({
      manifest: rowToManifest(row),
      path: row.path,
      resolved: true,
    }));
  }
}

// ============================================================================
// Singleton
// ============================================================================

let instance: SkillRegistry | null = null;

export function getSkillRegistry(): SkillRegistry {
  if (!instance) {
    instance = new SkillRegistry();
  }
  return instance;
}
