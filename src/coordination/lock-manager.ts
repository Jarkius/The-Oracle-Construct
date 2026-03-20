/**
 * Lock Manager — ADR-019 File Ownership Protocol
 *
 * Manages file locks for cross-worktree coordination. Before editing any file,
 * agents must claim a lock. Locks are advisory — enforced by the PreToolUse
 * hook chain (matrix-lock-check.sh).
 *
 * Lock files live at ~/.matrix/coordination/locks/{sha256-of-path}.lock
 * as individual JSON files. Atomic creation via exclusive write flag.
 *
 * See: docs/multi-agent-protocol.md#file-locking
 */

import { existsSync, mkdirSync, readdirSync, readFileSync, unlinkSync, writeFileSync } from 'fs';
import { join } from 'path';
import { createHash } from 'crypto';
import { createLogger } from '../core/utils/logger';
import type { FileLock, LockResult, CoordinationConfig } from './types';
import { DEFAULT_COORDINATION_CONFIG } from './types';

const log = createLogger('LockManager');

// ============================================================================
// Lock Manager
// ============================================================================

export class LockManager {
  private locksDir: string;
  private config: CoordinationConfig;

  constructor(config?: Partial<CoordinationConfig>) {
    this.config = { ...DEFAULT_COORDINATION_CONFIG, ...config };
    this.locksDir = join(this.config.baseDir, 'locks');
    mkdirSync(this.locksDir, { recursive: true });
  }

  /**
   * Compute the lock file path for a given file path.
   * Uses SHA256 hash to avoid filesystem-unsafe characters.
   */
  private lockFileFor(filePath: string): string {
    const hash = createHash('sha256').update(filePath).digest('hex');
    return join(this.locksDir, `${hash}.lock`);
  }

  /**
   * Attempt to acquire a lock on a file path.
   * Uses exclusive file creation (wx flag) for atomicity.
   */
  acquireLock(agentId: string, filePath: string, task: string = '', worktree: string = ''): LockResult {
    const lockFile = this.lockFileFor(filePath);

    // Check existing lock
    const existing = this.readLock(lockFile);
    if (existing) {
      // Same owner — re-entrant lock
      if (existing.owner === agentId) {
        return { acquired: true, lockPath: lockFile };
      }

      // Check expiry
      if (new Date(existing.expiresAt) > new Date()) {
        log.info(`Lock contention: ${filePath} held by ${existing.owner}`, { agentId, holder: existing.owner });
        return { acquired: false, holder: existing.owner, lockPath: lockFile };
      }

      // Expired — remove stale lock
      log.info(`Removing expired lock: ${filePath} (was ${existing.owner})`, { filePath });
      this.removeLockFile(lockFile);
    }

    // Create new lock
    const now = new Date();
    const lock: FileLock = {
      path: filePath,
      owner: agentId,
      worktree,
      claimedAt: now.toISOString(),
      expiresAt: new Date(now.getTime() + this.config.lockExpiryMs).toISOString(),
      task,
    };

    try {
      // Atomic create — fails if file already exists (race condition safe)
      writeFileSync(lockFile, JSON.stringify(lock, null, 2), { flag: 'wx' });
      log.info(`Lock acquired: ${filePath}`, { agentId, lockFile });
      return { acquired: true, lockPath: lockFile };
    } catch (err: any) {
      if (err.code === 'EEXIST') {
        // Another agent won the race
        const raceWinner = this.readLock(lockFile);
        return { acquired: false, holder: raceWinner?.owner, lockPath: lockFile };
      }
      log.error(`Failed to acquire lock: ${err.message}`, { filePath, agentId });
      return { acquired: false };
    }
  }

  /**
   * Release a specific lock. Only the owner can release.
   */
  releaseLock(agentId: string, filePath: string): boolean {
    const lockFile = this.lockFileFor(filePath);
    const existing = this.readLock(lockFile);

    if (!existing) {
      return true; // No lock to release
    }

    if (existing.owner !== agentId) {
      log.warn(`Cannot release lock: ${filePath} owned by ${existing.owner}, not ${agentId}`);
      return false;
    }

    this.removeLockFile(lockFile);
    log.info(`Lock released: ${filePath}`, { agentId });
    return true;
  }

  /**
   * Release all locks held by an agent. Used on agent completion/crash.
   */
  releaseAllForAgent(agentId: string): number {
    let released = 0;
    const lockFiles = this.listLockFiles();

    for (const lockFile of lockFiles) {
      const lock = this.readLock(lockFile);
      if (lock && lock.owner === agentId) {
        this.removeLockFile(lockFile);
        released++;
        log.info(`Released lock: ${lock.path}`, { agentId });
      }
    }

    log.info(`Released ${released} locks for agent ${agentId}`);
    return released;
  }

  /**
   * Check if a file is locked and by whom.
   */
  checkLock(filePath: string): FileLock | null {
    const lockFile = this.lockFileFor(filePath);
    const lock = this.readLock(lockFile);

    if (!lock) return null;

    // Check expiry
    if (new Date(lock.expiresAt) <= new Date()) {
      this.removeLockFile(lockFile);
      return null;
    }

    return lock;
  }

  /**
   * Check if a file path falls under a directory lock.
   * E.g., if src/auth/ is locked, src/auth/jwt.ts is also locked.
   */
  checkLockWithParents(filePath: string): FileLock | null {
    // Check exact path
    const direct = this.checkLock(filePath);
    if (direct) return direct;

    // Check parent directories
    const parts = filePath.split('/');
    for (let i = parts.length - 1; i > 0; i--) {
      const parentPath = parts.slice(0, i).join('/') + '/';
      const parentLock = this.checkLock(parentPath);
      if (parentLock) return parentLock;
    }

    return null;
  }

  /**
   * List all active (non-expired) locks.
   */
  listActiveLocks(): FileLock[] {
    const locks: FileLock[] = [];
    const now = new Date();

    for (const lockFile of this.listLockFiles()) {
      const lock = this.readLock(lockFile);
      if (lock && new Date(lock.expiresAt) > now) {
        locks.push(lock);
      } else if (lock) {
        // Clean up expired
        this.removeLockFile(lockFile);
      }
    }

    return locks;
  }

  /**
   * Remove all expired locks.
   */
  cleanExpired(): number {
    let cleaned = 0;
    const now = new Date();

    for (const lockFile of this.listLockFiles()) {
      const lock = this.readLock(lockFile);
      if (lock && new Date(lock.expiresAt) <= now) {
        this.removeLockFile(lockFile);
        cleaned++;
      }
    }

    if (cleaned > 0) {
      log.info(`Cleaned ${cleaned} expired locks`);
    }
    return cleaned;
  }

  /**
   * Get all locks owned by a specific agent.
   */
  getLocksForAgent(agentId: string): FileLock[] {
    return this.listActiveLocks().filter(l => l.owner === agentId);
  }

  // ============================================================================
  // Internal helpers
  // ============================================================================

  private readLock(lockFile: string): FileLock | null {
    try {
      if (!existsSync(lockFile)) return null;
      const raw = readFileSync(lockFile, 'utf8');
      return JSON.parse(raw) as FileLock;
    } catch {
      return null;
    }
  }

  private removeLockFile(lockFile: string): void {
    try {
      unlinkSync(lockFile);
    } catch { /* already gone */ }
  }

  private listLockFiles(): string[] {
    try {
      return readdirSync(this.locksDir)
        .filter(f => f.endsWith('.lock'))
        .map(f => join(this.locksDir, f));
    } catch {
      return [];
    }
  }
}

// ============================================================================
// Singleton
// ============================================================================

let instance: LockManager | null = null;

export function getLockManager(config?: Partial<CoordinationConfig>): LockManager {
  if (!instance) {
    instance = new LockManager(config);
  }
  return instance;
}
