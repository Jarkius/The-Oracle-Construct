/**
 * Skill Hot-Loader — Runtime Skill Discovery
 *
 * Watches skill directories for new/modified manifests and updates
 * the SkillRegistry in real-time. "Hot-load" means the SQLite registry
 * stays in sync with the filesystem so the next `/skillname` invocation
 * reads the updated file.
 *
 * Emits events: skill:added, skill:updated, skill:removed
 *
 * See: Phase 13 — Skill Hot-Load + Composition
 */

import { existsSync, readdirSync, readFileSync, watch, type FSWatcher } from 'fs';
import { join } from 'path';
import { createLogger } from '../core/utils/logger';
import type { SkillManifest } from './types';

const log = createLogger('SkillHotLoader');

type SkillEvent = 'skill:added' | 'skill:updated' | 'skill:removed';
type SkillEventHandler = (event: SkillEvent, manifest: SkillManifest) => void;

export class SkillHotLoader {
  private watchers: FSWatcher[] = [];
  private watchDirs: string[] = [];
  private handlers: SkillEventHandler[] = [];
  private knownSkills: Map<string, { manifest: SkillManifest; mtime: number }> = new Map();
  private scanInterval: ReturnType<typeof setInterval> | null = null;

  constructor(private projectDir: string) {
    // Default skill directories
    this.watchDirs = [
      join(projectDir, '.claude', 'skills'),
      join(projectDir, '.agent', 'skills'),
    ];
  }

  /**
   * Add a directory to watch for skill manifests.
   */
  addWatchDir(dir: string): void {
    if (!this.watchDirs.includes(dir)) {
      this.watchDirs.push(dir);
    }
  }

  /**
   * Register an event handler for skill changes.
   */
  on(handler: SkillEventHandler): void {
    this.handlers.push(handler);
  }

  /**
   * Start watching for skill changes.
   * Performs initial scan, then watches for filesystem changes.
   */
  start(pollIntervalMs: number = 5000): void {
    log.info('Starting skill hot-loader');

    // Initial scan
    this.scan();

    // Watch each directory
    for (const dir of this.watchDirs) {
      if (!existsSync(dir)) continue;

      try {
        const watcher = watch(dir, { recursive: true }, (eventType, filename) => {
          if (filename && (filename.endsWith('skill.manifest.json') || filename.endsWith('.manifest.json'))) {
            log.info(`Detected change: ${eventType} ${filename}`);
            this.scan();
          }
        });
        this.watchers.push(watcher);
        log.info(`Watching: ${dir}`);
      } catch (err) {
        log.warn(`Failed to watch ${dir}: ${err}`);
      }
    }

    // Periodic scan as fallback (fs.watch can miss events)
    this.scanInterval = setInterval(() => this.scan(), pollIntervalMs);
  }

  /**
   * Stop watching.
   */
  stop(): void {
    for (const watcher of this.watchers) {
      watcher.close();
    }
    this.watchers = [];

    if (this.scanInterval) {
      clearInterval(this.scanInterval);
      this.scanInterval = null;
    }

    log.info('Skill hot-loader stopped');
  }

  /**
   * Force a full scan of all watch directories.
   */
  scan(): SkillManifest[] {
    const found = new Map<string, { manifest: SkillManifest; path: string; mtime: number }>();

    for (const dir of this.watchDirs) {
      if (!existsSync(dir)) continue;
      this.scanDir(dir, found);
    }

    // Detect additions and updates
    for (const [id, { manifest, mtime }] of found) {
      const existing = this.knownSkills.get(id);

      if (!existing) {
        // New skill
        this.knownSkills.set(id, { manifest, mtime });
        this.emit('skill:added', manifest);
      } else if (mtime > existing.mtime) {
        // Updated skill
        this.knownSkills.set(id, { manifest, mtime });
        this.emit('skill:updated', manifest);
      }
    }

    // Detect removals
    for (const [id, { manifest }] of this.knownSkills) {
      if (!found.has(id)) {
        this.knownSkills.delete(id);
        this.emit('skill:removed', manifest);
      }
    }

    return Array.from(found.values()).map(f => f.manifest);
  }

  /**
   * Get all currently known skills.
   */
  getKnownSkills(): SkillManifest[] {
    return Array.from(this.knownSkills.values()).map(s => s.manifest);
  }

  // Internal

  private scanDir(dir: string, found: Map<string, { manifest: SkillManifest; path: string; mtime: number }>): void {
    try {
      for (const entry of readdirSync(dir, { withFileTypes: true })) {
        const fullPath = join(dir, entry.name);

        if (entry.isDirectory()) {
          // Look for manifest inside skill directory
          const manifestPath = join(fullPath, 'skill.manifest.json');
          this.tryLoadManifest(manifestPath, found);
        } else if (entry.name.endsWith('.manifest.json')) {
          this.tryLoadManifest(fullPath, found);
        }
      }
    } catch { /* dir doesn't exist or can't read */ }
  }

  private tryLoadManifest(path: string, found: Map<string, { manifest: SkillManifest; path: string; mtime: number }>): void {
    try {
      if (!existsSync(path)) return;

      const stat = Bun.file(path);
      const raw = readFileSync(path, 'utf8');
      const manifest = JSON.parse(raw) as SkillManifest;

      if (!manifest.id || !manifest.version) {
        log.warn(`Invalid manifest (missing id/version): ${path}`);
        return;
      }

      found.set(manifest.id, {
        manifest,
        path,
        mtime: stat.lastModified,
      });
    } catch (err) {
      log.warn(`Failed to load manifest ${path}: ${err}`);
    }
  }

  private emit(event: SkillEvent, manifest: SkillManifest): void {
    log.info(`${event}: ${manifest.id}@${manifest.version}`);
    for (const handler of this.handlers) {
      try {
        handler(event, manifest);
      } catch (err) {
        log.error(`Handler error for ${event}: ${err}`);
      }
    }
  }
}

// ============================================================================
// Singleton
// ============================================================================

let instance: SkillHotLoader | null = null;

export function getSkillHotLoader(projectDir?: string): SkillHotLoader {
  if (!instance) {
    instance = new SkillHotLoader(projectDir || process.cwd());
  }
  return instance;
}
