/**
 * Heartbeat Watchdog — Config Integrity Validation
 *
 * Periodically validates heartbeat.json schema integrity.
 * If corruption is detected, restores from heartbeat.json.bak.
 *
 * See: Phase 10 WEP Safeguards
 */

import { existsSync, readFileSync, writeFileSync, copyFileSync } from 'fs';
import { createLogger } from '../core/utils/logger';

const log = createLogger('HeartbeatWatchdog');

interface HeartbeatConfig {
  enabled: boolean;
  auto_evolve?: boolean;
  check_interval_ms?: number;
  checks?: Record<string, unknown>;
  [key: string]: unknown;
}

const REQUIRED_FIELDS = ['enabled'] as const;

export class HeartbeatWatchdog {
  private configPath: string;
  private backupPath: string;

  constructor(projectRoot: string) {
    this.configPath = `${projectRoot}/psi/state/pulse/heartbeat.json`;
    this.backupPath = `${this.configPath}.bak`;
  }

  /**
   * Create a backup of the current heartbeat config.
   * Should be called on daemon startup.
   */
  saveBackup(): boolean {
    try {
      if (!existsSync(this.configPath)) return false;

      // Validate before backing up — don't backup corrupt state
      const config = this.readConfig();
      if (!config || !this.validateSchema(config)) {
        log.warn('Current config is invalid — not overwriting backup');
        return false;
      }

      copyFileSync(this.configPath, this.backupPath);
      log.info('Heartbeat config backup saved');
      return true;
    } catch (err) {
      log.error(`Failed to save backup: ${err}`);
      return false;
    }
  }

  /**
   * Validate the current heartbeat config.
   * Returns true if valid, false if corrupt.
   */
  validate(): { valid: boolean; errors: string[] } {
    const errors: string[] = [];

    if (!existsSync(this.configPath)) {
      return { valid: true, errors: [] }; // No config = not corrupt, just missing
    }

    const config = this.readConfig();
    if (!config) {
      errors.push('Failed to parse heartbeat.json as JSON');
      return { valid: false, errors };
    }

    if (!this.validateSchema(config)) {
      errors.push('Schema validation failed: missing required fields');
    }

    if (typeof config.enabled !== 'boolean') {
      errors.push(`"enabled" must be boolean, got ${typeof config.enabled}`);
    }

    if (config.auto_evolve !== undefined && typeof config.auto_evolve !== 'boolean') {
      errors.push(`"auto_evolve" must be boolean, got ${typeof config.auto_evolve}`);
    }

    if (config.check_interval_ms !== undefined && typeof config.check_interval_ms !== 'number') {
      errors.push(`"check_interval_ms" must be number, got ${typeof config.check_interval_ms}`);
    }

    return { valid: errors.length === 0, errors };
  }

  /**
   * Restore heartbeat config from backup.
   */
  restore(): boolean {
    if (!existsSync(this.backupPath)) {
      log.error('No backup available to restore from');
      return false;
    }

    try {
      copyFileSync(this.backupPath, this.configPath);
      log.info('Heartbeat config restored from backup');
      return true;
    } catch (err) {
      log.error(`Failed to restore from backup: ${err}`);
      return false;
    }
  }

  /**
   * Full check: validate and restore if corrupt.
   */
  checkAndRestore(): { action: 'ok' | 'restored' | 'failed'; errors?: string[] } {
    const { valid, errors } = this.validate();

    if (valid) {
      return { action: 'ok' };
    }

    log.warn(`Heartbeat config corrupted: ${errors.join(', ')}`);

    if (this.restore()) {
      return { action: 'restored', errors };
    }

    return { action: 'failed', errors };
  }

  // Internal

  private readConfig(): HeartbeatConfig | null {
    try {
      const raw = readFileSync(this.configPath, 'utf8');
      return JSON.parse(raw);
    } catch {
      return null;
    }
  }

  private validateSchema(config: HeartbeatConfig): boolean {
    for (const field of REQUIRED_FIELDS) {
      if (!(field in config)) return false;
    }
    return true;
  }
}
