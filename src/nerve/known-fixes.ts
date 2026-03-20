/**
 * Matrix Nerve — Known Fixes Registry
 *
 * Self-learning fix registry. Pattern-match errors to known solutions.
 * Auto-execute safe fixes, queue unsafe ones for approval.
 *
 * Pattern 8 from Oracle Nerve handoff.
 */

import { readFile, writeFile, appendFile } from 'node:fs/promises';
import type { KnownFix, KnownFixRegistry, MatchPattern, PulseEvent } from './types';

export class KnownFixEngine {
  private registry: KnownFixRegistry = { version: 1, fixes: [] };
  private registryPath: string;
  private eventsPath: string;

  constructor(registryPath: string, eventsPath: string) {
    this.registryPath = registryPath;
    this.eventsPath = eventsPath;
  }

  /**
   * Load the fix registry from disk.
   */
  async load(): Promise<void> {
    try {
      const content = await readFile(this.registryPath, 'utf-8');
      this.registry = JSON.parse(content);
    } catch {
      // No registry yet — start empty
      this.registry = { version: 1, fixes: [] };
    }
  }

  /**
   * Save the registry back to disk (after stat updates).
   */
  async save(): Promise<void> {
    await writeFile(
      this.registryPath,
      JSON.stringify(this.registry, null, 2) + '\n'
    );
  }

  /**
   * Find a matching fix for an error event.
   */
  findFix(service: string, errorStr: string, exitCode?: number): KnownFix | null {
    const lower = errorStr.toLowerCase();

    return this.registry.fixes.find(fix => {
      const m = fix.match;
      if (m.service && m.service !== service) return false;
      if (m.error_contains && !lower.includes(m.error_contains.toLowerCase())) return false;
      if (m.exit_code !== undefined && m.exit_code !== exitCode) return false;
      return true;
    }) ?? null;
  }

  /**
   * Execute a known fix. Returns true if the fix command succeeded.
   */
  async executeFix(fix: KnownFix): Promise<boolean> {
    if (!fix.auto) return false;

    try {
      const proc = Bun.spawn(['sh', '-c', fix.fix], {
        stdout: 'pipe',
        stderr: 'pipe',
      });
      await proc.exited;
      const success = proc.exitCode === 0;

      // Update stats
      if (success) {
        fix.successCount++;
      } else {
        fix.failCount++;
      }
      fix.lastUsed = Date.now();

      await this.emitEvent('nerve:fix-applied', {
        fixId: fix.id,
        description: fix.description,
        success,
        auto: true,
      });

      await this.save();
      return success;
    } catch (err) {
      fix.failCount++;
      fix.lastUsed = Date.now();
      await this.save();

      await this.emitEvent('nerve:fix-failed', {
        fixId: fix.id,
        error: String(err),
      });

      return false;
    }
  }

  /**
   * Add a new fix to the registry.
   */
  async addFix(fix: Omit<KnownFix, 'successCount' | 'failCount' | 'lastUsed'>): Promise<void> {
    const existing = this.registry.fixes.findIndex(f => f.id === fix.id);
    const fullFix: KnownFix = {
      ...fix,
      successCount: 0,
      failCount: 0,
      lastUsed: null,
    };

    if (existing >= 0) {
      this.registry.fixes[existing] = fullFix;
    } else {
      this.registry.fixes.push(fullFix);
    }

    await this.save();
  }

  /**
   * Get all fixes with their success rates.
   */
  getFixStats(): Array<KnownFix & { successRate: number }> {
    return this.registry.fixes.map(fix => ({
      ...fix,
      successRate: fix.successCount + fix.failCount > 0
        ? fix.successCount / (fix.successCount + fix.failCount)
        : 0,
    }));
  }

  /**
   * Get the full registry.
   */
  getRegistry(): KnownFixRegistry {
    return this.registry;
  }

  private async emitEvent(
    type: string,
    data: Record<string, unknown>
  ): Promise<void> {
    const event: PulseEvent = {
      id: `ev_${Date.now()}`,
      ts: new Date().toISOString(),
      type,
      agent: 'nerve',
      data,
    };
    await appendFile(this.eventsPath, JSON.stringify(event) + '\n');
  }
}
