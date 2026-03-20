/**
 * Coordinator — ADR-019 Handshake Protocol
 *
 * Manages the lifecycle of parallel work sessions. The Coordinator is the
 * "brain" that the Oracle delegates to for multi-agent coordination:
 *
 *   1. PLAN    — Write handshake.json with scope assignments + merge order
 *   2. SPAWN   — Each agent reads handshake to know its boundaries
 *   3. WORK    — Agents update status; Coordinator monitors
 *   4. SYNC    — Coordinator updates handshake when dependencies resolve
 *   5. MERGE   — Follow mergeOrder for sequential merging
 *   6. CLEANUP — Archive handshake, clear coordination dir
 *
 * See: docs/multi-agent-protocol.md
 */

import { existsSync, mkdirSync, readFileSync, writeFileSync, readdirSync, unlinkSync } from 'fs';
import { join } from 'path';
import { createLogger } from '../core/utils/logger';
import { getLockManager } from './lock-manager';
import type {
  HandshakeSession,
  TaskDecomposition,
  SessionPhase,
  AgentStatusRecord,
  CoordinationConfig,
} from './types';
import { DEFAULT_COORDINATION_CONFIG } from './types';

const log = createLogger('Coordinator');

// ============================================================================
// Coordinator
// ============================================================================

export class Coordinator {
  private config: CoordinationConfig;
  private handshakePath: string;
  private agentsDir: string;
  private resultsDir: string;
  private logsDir: string;

  constructor(config?: Partial<CoordinationConfig>) {
    this.config = { ...DEFAULT_COORDINATION_CONFIG, ...config };
    this.handshakePath = join(this.config.baseDir, 'handshake.json');
    this.agentsDir = join(this.config.baseDir, 'agents');
    this.resultsDir = join(this.config.baseDir, 'results');
    this.logsDir = join(this.config.baseDir, 'logs');

    // Ensure directories exist
    mkdirSync(this.agentsDir, { recursive: true });
    mkdirSync(this.resultsDir, { recursive: true });
    mkdirSync(this.logsDir, { recursive: true });
  }

  // ============================================================================
  // Session Lifecycle
  // ============================================================================

  /**
   * Plan parallel work: create a new coordination session with scope assignments.
   * Called by the Oracle before spawning agents.
   */
  planParallelWork(description: string, tasks: TaskDecomposition[], mergeOrder?: string[]): HandshakeSession {
    // Check for existing active session
    const existing = this.getSession();
    if (existing && existing.phase !== 'complete' && existing.phase !== 'failed') {
      log.warn('Active session exists, completing it first', { sessionId: existing.sessionId });
      this.transitionPhase('complete');
    }

    const now = new Date();
    const sessionId = `session-${now.toISOString().replace(/[:.]/g, '-').slice(0, 19)}`;

    const session: HandshakeSession = {
      sessionId,
      orchestrator: 'Oracle',
      startedAt: now.toISOString(),
      phase: 'planning',
      plan: {
        description,
        decomposition: tasks,
        mergeOrder: mergeOrder || tasks.map(t => t.taskId),
        sharedReadOnly: ['CLAUDE.md', 'SOUL.md', '.claude/agents/**', 'psi/source/**'],
      },
      lastHeartbeat: now.toISOString(),
    };

    this.writeSession(session);
    this.logEvent('session:created', { sessionId, taskCount: tasks.length });
    log.info(`Session created: ${sessionId}`, { description, taskCount: tasks.length });

    return session;
  }

  /**
   * Transition the session to a new phase.
   */
  transitionPhase(phase: SessionPhase): HandshakeSession | null {
    const session = this.getSession();
    if (!session) {
      log.warn('No active session to transition');
      return null;
    }

    const oldPhase = session.phase;
    session.phase = phase;
    session.lastHeartbeat = new Date().toISOString();
    this.writeSession(session);

    this.logEvent('session:phase-change', { sessionId: session.sessionId, from: oldPhase, to: phase });
    log.info(`Session phase: ${oldPhase} → ${phase}`, { sessionId: session.sessionId });

    return session;
  }

  /**
   * Update a task's status within the session.
   */
  updateTaskStatus(taskId: string, status: TaskDecomposition['status']): HandshakeSession | null {
    const session = this.getSession();
    if (!session) return null;

    const task = session.plan.decomposition.find(t => t.taskId === taskId);
    if (!task) {
      log.warn(`Task not found: ${taskId}`);
      return null;
    }

    task.status = status;
    session.lastHeartbeat = new Date().toISOString();
    this.writeSession(session);

    this.logEvent('task:status-change', { sessionId: session.sessionId, taskId, status });

    // Check if all tasks are complete — auto-transition to merging
    const allComplete = session.plan.decomposition.every(
      t => t.status === 'complete' || t.status === 'error'
    );
    if (allComplete && session.phase === 'working') {
      this.transitionPhase('merging');
    }

    return session;
  }

  /**
   * Resolve dependencies: when a task completes, check if blocked tasks can unblock.
   */
  resolveDependencies(completedTaskId: string): string[] {
    const session = this.getSession();
    if (!session) return [];

    const unblocked: string[] = [];

    for (const task of session.plan.decomposition) {
      if (task.status !== 'blocked') continue;
      if (!task.dependsOn.includes(completedTaskId)) continue;

      // Check if ALL dependencies are now complete
      const allDepsComplete = task.dependsOn.every(depId => {
        const dep = session.plan.decomposition.find(t => t.taskId === depId);
        return dep && dep.status === 'complete';
      });

      if (allDepsComplete) {
        task.status = 'planned'; // Ready to work
        unblocked.push(task.taskId);
        this.logEvent('task:unblocked', { taskId: task.taskId, resolvedBy: completedTaskId });
      }
    }

    if (unblocked.length > 0) {
      session.lastHeartbeat = new Date().toISOString();
      this.writeSession(session);
      log.info(`Unblocked ${unblocked.length} tasks after ${completedTaskId} completed`, { unblocked });
    }

    return unblocked;
  }

  // ============================================================================
  // Session Queries
  // ============================================================================

  /**
   * Get the current coordination session.
   */
  getSession(): HandshakeSession | null {
    try {
      if (!existsSync(this.handshakePath)) return null;
      const raw = readFileSync(this.handshakePath, 'utf8');
      return JSON.parse(raw) as HandshakeSession;
    } catch {
      return null;
    }
  }

  /**
   * Check if a file path falls within an agent's assigned scope.
   */
  isInScope(filePath: string, agentId: string): boolean {
    const session = this.getSession();
    if (!session) return true; // No session = no restrictions

    const task = session.plan.decomposition.find(
      t => t.assignee.includes(agentId)
    );
    if (!task) return false;

    return task.scope.some(pattern => {
      if (pattern.endsWith('/**')) {
        const dir = pattern.slice(0, -3);
        return filePath.startsWith(dir);
      }
      if (pattern.endsWith('/*')) {
        const dir = pattern.slice(0, -2);
        return filePath.startsWith(dir) && !filePath.slice(dir.length + 1).includes('/');
      }
      return filePath === pattern || filePath.startsWith(pattern);
    });
  }

  /**
   * Check if a file is in the shared read-only set.
   */
  isSharedReadOnly(filePath: string): boolean {
    const session = this.getSession();
    if (!session) return false;

    return session.plan.sharedReadOnly.some(pattern => {
      if (pattern.endsWith('/**')) {
        return filePath.startsWith(pattern.slice(0, -3));
      }
      return filePath === pattern;
    });
  }

  /**
   * Get the merge order from the current session.
   */
  getMergeOrder(): string[] {
    const session = this.getSession();
    return session?.plan.mergeOrder || [];
  }

  /**
   * Check if a session is active (not complete or failed).
   */
  isActive(): boolean {
    const session = this.getSession();
    return !!session && session.phase !== 'complete' && session.phase !== 'failed';
  }

  // ============================================================================
  // Cleanup
  // ============================================================================

  /**
   * Complete and archive the current session.
   */
  completeSession(archiveDir?: string): void {
    const session = this.getSession();
    if (!session) return;

    session.phase = 'complete';
    session.lastHeartbeat = new Date().toISOString();

    // Archive handshake
    if (archiveDir) {
      mkdirSync(archiveDir, { recursive: true });
      const archivePath = join(archiveDir, `${session.sessionId}.json`);
      writeFileSync(archivePath, JSON.stringify(session, null, 2));
      log.info(`Session archived to ${archivePath}`);
    }

    // Release all locks
    const lockManager = getLockManager(this.config);
    for (const task of session.plan.decomposition) {
      const agentMatch = task.assignee.match(/\(([^)]+)\)/);
      if (agentMatch) {
        lockManager.releaseAllForAgent(agentMatch[1]);
      }
    }

    // Clean coordination state
    this.cleanAgentStatuses();
    this.cleanMessages();
    this.cleanResults();

    // Remove handshake
    try { unlinkSync(this.handshakePath); } catch { /* ok */ }

    this.logEvent('session:completed', { sessionId: session.sessionId });
    log.info(`Session completed: ${session.sessionId}`);
  }

  // ============================================================================
  // Internal Helpers
  // ============================================================================

  private writeSession(session: HandshakeSession): void {
    writeFileSync(this.handshakePath, JSON.stringify(session, null, 2));
  }

  private cleanAgentStatuses(): void {
    try {
      for (const f of readdirSync(this.agentsDir)) {
        unlinkSync(join(this.agentsDir, f));
      }
    } catch { /* ok */ }
  }

  private cleanMessages(): void {
    const messagesDir = join(this.config.baseDir, 'messages');
    try {
      for (const f of readdirSync(messagesDir)) {
        unlinkSync(join(messagesDir, f));
      }
    } catch { /* ok */ }
  }

  private cleanResults(): void {
    try {
      for (const f of readdirSync(this.resultsDir)) {
        unlinkSync(join(this.resultsDir, f));
      }
    } catch { /* ok */ }
  }

  private logEvent(type: string, data: Record<string, unknown>): void {
    const entry = {
      ts: new Date().toISOString(),
      type,
      ...data,
    };
    const logFile = join(this.logsDir, 'coordination.jsonl');
    try {
      const line = JSON.stringify(entry) + '\n';
      writeFileSync(logFile, line, { flag: 'a' });
    } catch { /* non-blocking */ }
  }
}

// ============================================================================
// Singleton
// ============================================================================

let instance: Coordinator | null = null;

export function getCoordinator(config?: Partial<CoordinationConfig>): Coordinator {
  if (!instance) {
    instance = new Coordinator(config);
  }
  return instance;
}
