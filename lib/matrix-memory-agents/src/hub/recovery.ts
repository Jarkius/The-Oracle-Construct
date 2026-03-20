/**
 * Hub Recovery - Crash detection and state restoration
 *
 * On startup: reads ~/.matrix-hub/state.json, detects whether this is a
 * restart after a crash, and logs a recovery event.
 *
 * Provides periodic state snapshots so the hub can restore its knowledge
 * of connected matrices after an unexpected restart.
 *
 * Singleton pattern — use getRecoveryManager() to access.
 */

import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'fs';
import { join } from 'path';
import { createLogger } from '../utils/logger';

const log = createLogger('HubRecovery');

// ============================================================================
// Types
// ============================================================================

export interface HubStateSnapshot {
  /** ISO timestamp when state was saved */
  savedAt: string;
  /** Hub process PID at time of save */
  pid: number;
  /** Whether the hub was shut down gracefully */
  gracefulShutdown: boolean;
  /** Matrix IDs that were connected at time of save */
  connectedMatrices: string[];
  /** Arbitrary metadata for future use */
  meta?: Record<string, unknown>;
}

export interface RecoveryInfo {
  /** Whether this startup is recovering from a crash */
  isRecovery: boolean;
  /** Previous state if recovery, null otherwise */
  previousState: HubStateSnapshot | null;
  /** Matrix IDs that were connected before the crash */
  lostConnections: string[];
}

// ============================================================================
// Paths
// ============================================================================

const HOME = process.env.HOME || process.env.USERPROFILE || '';
const STATE_DIR = join(HOME, '.matrix-hub');
const STATE_FILE = join(STATE_DIR, 'state.json');

// ============================================================================
// Singleton
// ============================================================================

let instance: RecoveryManager | null = null;

class RecoveryManager {
  private saveInterval: ReturnType<typeof setInterval> | null = null;
  private recoveryInfo: RecoveryInfo;

  constructor() {
    this.recoveryInfo = this.detectRecovery();
  }

  /**
   * Detect whether this startup is a recovery from a crash.
   * A crash is detected when state.json exists with gracefulShutdown = false.
   */
  private detectRecovery(): RecoveryInfo {
    const noRecovery: RecoveryInfo = {
      isRecovery: false,
      previousState: null,
      lostConnections: [],
    };

    if (!existsSync(STATE_FILE)) {
      log.info('No previous state found, fresh start');
      return noRecovery;
    }

    try {
      const raw = readFileSync(STATE_FILE, 'utf-8');
      const previousState = JSON.parse(raw) as HubStateSnapshot;

      if (!previousState.gracefulShutdown) {
        const lostConnections = previousState.connectedMatrices || [];
        log.warn('Crash recovery detected', {
          previousPid: previousState.pid,
          savedAt: previousState.savedAt,
          lostConnections: lostConnections.length,
        });
        return {
          isRecovery: true,
          previousState,
          lostConnections,
        };
      }

      log.info('Previous shutdown was graceful, no recovery needed');
      return noRecovery;
    } catch (err) {
      log.error('Failed to read previous state file', { error: String(err) });
      return noRecovery;
    }
  }

  /**
   * Get recovery information from startup detection.
   */
  getRecoveryInfo(): RecoveryInfo {
    return this.recoveryInfo;
  }

  /**
   * Save a snapshot of the current hub state.
   * Called periodically and on graceful shutdown.
   */
  saveState(connectedMatrices: Map<string, unknown> | string[], gracefulShutdown: boolean = false): void {
    try {
      if (!existsSync(STATE_DIR)) {
        mkdirSync(STATE_DIR, { recursive: true });
      }

      const matrixIds = Array.isArray(connectedMatrices)
        ? connectedMatrices
        : Array.from(connectedMatrices.keys());

      const snapshot: HubStateSnapshot = {
        savedAt: new Date().toISOString(),
        pid: process.pid,
        gracefulShutdown,
        connectedMatrices: matrixIds,
      };

      writeFileSync(STATE_FILE, JSON.stringify(snapshot, null, 2), 'utf-8');
      log.debug('State snapshot saved', {
        connectedMatrices: matrixIds.length,
        gracefulShutdown,
      });
    } catch (err) {
      log.error('Failed to save state snapshot', { error: String(err) });
    }
  }

  /**
   * Load the most recent state snapshot from disk.
   * Returns null if no state file exists or it cannot be read.
   */
  loadState(): HubStateSnapshot | null {
    if (!existsSync(STATE_FILE)) {
      return null;
    }

    try {
      const raw = readFileSync(STATE_FILE, 'utf-8');
      return JSON.parse(raw) as HubStateSnapshot;
    } catch (err) {
      log.error('Failed to load state', { error: String(err) });
      return null;
    }
  }

  /**
   * Start periodic state snapshots.
   * @param getConnectedMatrices - callback that returns the current connected matrices
   * @param intervalMs - snapshot interval in milliseconds (default 30s)
   */
  startPeriodicSave(
    getConnectedMatrices: () => Map<string, unknown> | string[],
    intervalMs: number = 30000,
  ): void {
    if (this.saveInterval) {
      clearInterval(this.saveInterval);
    }

    this.saveInterval = setInterval(() => {
      this.saveState(getConnectedMatrices());
    }, intervalMs);

    log.info('Periodic state snapshots started', { intervalMs });
  }

  /**
   * Stop periodic snapshots and save a final graceful-shutdown snapshot.
   */
  stopPeriodicSave(connectedMatrices: Map<string, unknown> | string[]): void {
    if (this.saveInterval) {
      clearInterval(this.saveInterval);
      this.saveInterval = null;
    }

    // Final snapshot marking graceful shutdown
    this.saveState(connectedMatrices, true);
    log.info('Periodic snapshots stopped, graceful shutdown recorded');
  }
}

// ============================================================================
// Public API
// ============================================================================

/**
 * Get the singleton RecoveryManager instance.
 */
export function getRecoveryManager(): RecoveryManager {
  if (!instance) {
    instance = new RecoveryManager();
  }
  return instance;
}

/**
 * Convenience: save current hub state snapshot.
 */
export function saveState(connectedMatrices: Map<string, unknown> | string[], graceful: boolean = false): void {
  getRecoveryManager().saveState(connectedMatrices, graceful);
}

/**
 * Convenience: load the last saved hub state.
 */
export function loadState(): HubStateSnapshot | null {
  return getRecoveryManager().loadState();
}

/**
 * Reset the recovery manager (useful for testing).
 */
export function resetRecoveryManager(): void {
  if (instance) {
    instance.stopPeriodicSave([]);
  }
  instance = null;
}
