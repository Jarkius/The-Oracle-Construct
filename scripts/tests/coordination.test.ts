/**
 * Coordination Tests — ADR-019 Cross-Worktree Safety
 *
 * Tests for the coordination module:
 * - LockManager: acquire, release, re-entrant, contention, expiry, directory locks, cleanExpired
 * - Coordinator: planParallelWork, transitionPhase, updateTaskStatus, resolveDependencies, isInScope, isSharedReadOnly, completeSession
 * - StatusWriter: writeStatus, readStatus, readAllStatuses, transition, updateProgress, allTerminal, removeStatus
 * - MessageBus: send, receive, broadcast, receiveAll, recent, purge, getByType
 */

import { describe, test, expect, beforeEach, afterEach } from 'bun:test';
import { mkdtempSync, rmSync, existsSync, writeFileSync, readFileSync } from 'fs';
import { join } from 'path';
import { tmpdir } from 'os';
import { LockManager } from '../../src/coordination/lock-manager';
import { Coordinator } from '../../src/coordination/coordinator';
import { StatusWriter } from '../../src/coordination/status-writer';
import { MessageBus } from '../../src/coordination/message-bus';
import type { TaskDecomposition, CoordinationConfig } from '../../src/coordination/types';

// ============================================================================
// Helpers
// ============================================================================

function makeTempDir(): string {
  return mkdtempSync(join(tmpdir(), 'coord-test-'));
}

function makeConfig(baseDir: string): Partial<CoordinationConfig> {
  return {
    baseDir,
    lockExpiryMs: 60 * 60 * 1000,
    messageTtlMs: 60 * 60 * 1000,
    statusPollMs: 2000,
  };
}

function makeTasks(): TaskDecomposition[] {
  return [
    {
      taskId: 'task-auth',
      assignee: 'Neo (agent-1)',
      scope: ['src/auth/**'],
      branch: 'agent-1/feature-auth',
      status: 'planned',
      dependsOn: [],
    },
    {
      taskId: 'task-api',
      assignee: 'Trinity (agent-2)',
      scope: ['src/api/**'],
      branch: 'agent-2/feature-api',
      status: 'planned',
      dependsOn: [],
    },
    {
      taskId: 'task-tests',
      assignee: 'Tank (agent-3)',
      scope: ['tests/**'],
      branch: 'agent-3/feature-tests',
      status: 'blocked',
      dependsOn: ['task-auth', 'task-api'],
    },
  ];
}

// ============================================================================
// LockManager
// ============================================================================

describe('LockManager', () => {
  let tempDir: string;
  let lockManager: LockManager;

  beforeEach(() => {
    tempDir = makeTempDir();
    lockManager = new LockManager(makeConfig(tempDir));
  });

  afterEach(() => {
    rmSync(tempDir, { recursive: true, force: true });
  });

  test('acquireLock returns acquired=true for unclaimed file', () => {
    const result = lockManager.acquireLock('agent-1', 'src/auth/login.ts', 'implement login');
    expect(result.acquired).toBe(true);
    expect(result.lockPath).toBeDefined();
  });

  test('releaseLock succeeds for the owner', () => {
    lockManager.acquireLock('agent-1', 'src/auth/login.ts');
    const released = lockManager.releaseLock('agent-1', 'src/auth/login.ts');
    expect(released).toBe(true);

    // Lock should be gone
    const lock = lockManager.checkLock('src/auth/login.ts');
    expect(lock).toBeNull();
  });

  test('releaseLock fails for non-owner', () => {
    lockManager.acquireLock('agent-1', 'src/auth/login.ts');
    const released = lockManager.releaseLock('agent-2', 'src/auth/login.ts');
    expect(released).toBe(false);
  });

  test('re-entrant lock: same owner can re-acquire', () => {
    const first = lockManager.acquireLock('agent-1', 'src/auth/login.ts');
    expect(first.acquired).toBe(true);

    const second = lockManager.acquireLock('agent-1', 'src/auth/login.ts');
    expect(second.acquired).toBe(true);
  });

  test('contention: different agent cannot acquire held lock', () => {
    lockManager.acquireLock('agent-1', 'src/auth/login.ts');
    const result = lockManager.acquireLock('agent-2', 'src/auth/login.ts');
    expect(result.acquired).toBe(false);
    expect(result.holder).toBe('agent-1');
  });

  test('expiry: expired lock can be taken by another agent', () => {
    // Create a lock with very short expiry
    const shortExpiryManager = new LockManager({
      ...makeConfig(tempDir),
      lockExpiryMs: 1, // 1ms expiry
    });
    shortExpiryManager.acquireLock('agent-1', 'src/expired.ts');

    // Wait for expiry
    const start = Date.now();
    while (Date.now() - start < 10) { /* busy wait */ }

    // Different agent should be able to claim it
    const result = shortExpiryManager.acquireLock('agent-2', 'src/expired.ts');
    expect(result.acquired).toBe(true);
  });

  test('directory lock blocks child file', () => {
    lockManager.acquireLock('agent-1', 'src/auth/');
    const childLock = lockManager.checkLockWithParents('src/auth/jwt.ts');
    expect(childLock).not.toBeNull();
    expect(childLock!.owner).toBe('agent-1');
  });

  test('cleanExpired removes only expired locks', () => {
    // Create lock with very short expiry
    const shortExpiryManager = new LockManager({
      ...makeConfig(tempDir),
      lockExpiryMs: 1,
    });
    shortExpiryManager.acquireLock('agent-1', 'src/old.ts');

    // Create a normal lock (will not expire)
    const normalManager = new LockManager(makeConfig(tempDir));
    normalManager.acquireLock('agent-2', 'src/new.ts');

    // Wait for the short-expiry lock to expire
    const start = Date.now();
    while (Date.now() - start < 10) { /* busy wait */ }

    const cleaned = normalManager.cleanExpired();
    expect(cleaned).toBe(1);

    // The normal lock should still exist
    const remaining = normalManager.listActiveLocks();
    expect(remaining.length).toBe(1);
    expect(remaining[0].owner).toBe('agent-2');
  });

  test('releaseAllForAgent releases only that agent locks', () => {
    lockManager.acquireLock('agent-1', 'src/a.ts');
    lockManager.acquireLock('agent-1', 'src/b.ts');
    lockManager.acquireLock('agent-2', 'src/c.ts');

    const released = lockManager.releaseAllForAgent('agent-1');
    expect(released).toBe(2);

    const remaining = lockManager.listActiveLocks();
    expect(remaining.length).toBe(1);
    expect(remaining[0].owner).toBe('agent-2');
  });

  test('getLocksForAgent returns only that agent locks', () => {
    lockManager.acquireLock('agent-1', 'src/a.ts');
    lockManager.acquireLock('agent-2', 'src/b.ts');
    lockManager.acquireLock('agent-1', 'src/c.ts');

    const locks = lockManager.getLocksForAgent('agent-1');
    expect(locks.length).toBe(2);
    expect(locks.every(l => l.owner === 'agent-1')).toBe(true);
  });

  test('checkLock returns null for non-existent lock', () => {
    const lock = lockManager.checkLock('nonexistent.ts');
    expect(lock).toBeNull();
  });

  test('releaseLock on non-existent file returns true', () => {
    const released = lockManager.releaseLock('agent-1', 'nonexistent.ts');
    expect(released).toBe(true);
  });
});

// ============================================================================
// Coordinator
// ============================================================================

describe('Coordinator', () => {
  let tempDir: string;
  let coordinator: Coordinator;

  beforeEach(() => {
    tempDir = makeTempDir();
    coordinator = new Coordinator(makeConfig(tempDir));
  });

  afterEach(() => {
    rmSync(tempDir, { recursive: true, force: true });
  });

  test('planParallelWork creates a session with planning phase', () => {
    const tasks = makeTasks();
    const session = coordinator.planParallelWork('Build auth system', tasks);

    expect(session.sessionId).toMatch(/^session-/);
    expect(session.phase).toBe('planning');
    expect(session.orchestrator).toBe('Oracle');
    expect(session.plan.decomposition.length).toBe(3);
    expect(session.plan.description).toBe('Build auth system');
  });

  test('planParallelWork uses provided merge order', () => {
    const tasks = makeTasks();
    const mergeOrder = ['task-api', 'task-auth', 'task-tests'];
    const session = coordinator.planParallelWork('Build', tasks, mergeOrder);

    expect(session.plan.mergeOrder).toEqual(mergeOrder);
  });

  test('planParallelWork defaults merge order to task order', () => {
    const tasks = makeTasks();
    const session = coordinator.planParallelWork('Build', tasks);

    expect(session.plan.mergeOrder).toEqual(['task-auth', 'task-api', 'task-tests']);
  });

  test('transitionPhase updates session phase', () => {
    coordinator.planParallelWork('Build', makeTasks());
    const updated = coordinator.transitionPhase('working');

    expect(updated).not.toBeNull();
    expect(updated!.phase).toBe('working');
  });

  test('transitionPhase returns null with no active session', () => {
    const result = coordinator.transitionPhase('working');
    expect(result).toBeNull();
  });

  test('updateTaskStatus changes a task status', () => {
    coordinator.planParallelWork('Build', makeTasks());
    const updated = coordinator.updateTaskStatus('task-auth', 'working');

    expect(updated).not.toBeNull();
    const task = updated!.plan.decomposition.find(t => t.taskId === 'task-auth');
    expect(task!.status).toBe('working');
  });

  test('updateTaskStatus returns null for unknown task', () => {
    coordinator.planParallelWork('Build', makeTasks());
    const result = coordinator.updateTaskStatus('nonexistent', 'working');
    expect(result).toBeNull();
  });

  test('updateTaskStatus auto-transitions to merging when all tasks complete', () => {
    coordinator.planParallelWork('Build', makeTasks());
    coordinator.transitionPhase('working');

    coordinator.updateTaskStatus('task-auth', 'complete');
    coordinator.updateTaskStatus('task-api', 'complete');
    coordinator.updateTaskStatus('task-tests', 'complete');

    const session = coordinator.getSession();
    expect(session!.phase).toBe('merging');
  });

  test('resolveDependencies unblocks tasks when dependencies complete', () => {
    coordinator.planParallelWork('Build', makeTasks());

    // Complete task-auth
    coordinator.updateTaskStatus('task-auth', 'complete');
    let unblocked = coordinator.resolveDependencies('task-auth');
    // task-tests depends on BOTH task-auth and task-api, so not unblocked yet
    expect(unblocked.length).toBe(0);

    // Complete task-api — now task-tests should unblock
    coordinator.updateTaskStatus('task-api', 'complete');
    unblocked = coordinator.resolveDependencies('task-api');
    expect(unblocked).toContain('task-tests');
  });

  test('resolveDependencies returns empty array with no session', () => {
    const result = coordinator.resolveDependencies('task-auth');
    expect(result).toEqual([]);
  });

  test('isInScope matches files within agent scope', () => {
    coordinator.planParallelWork('Build', makeTasks());

    expect(coordinator.isInScope('src/auth/login.ts', 'agent-1')).toBe(true);
    expect(coordinator.isInScope('src/auth/jwt.ts', 'agent-1')).toBe(true);
    expect(coordinator.isInScope('src/api/routes.ts', 'agent-1')).toBe(false);
  });

  test('isInScope returns false for unknown agent', () => {
    coordinator.planParallelWork('Build', makeTasks());
    expect(coordinator.isInScope('src/auth/login.ts', 'agent-unknown')).toBe(false);
  });

  test('isInScope returns true when no session exists', () => {
    expect(coordinator.isInScope('anything.ts', 'anyone')).toBe(true);
  });

  test('isSharedReadOnly identifies shared files', () => {
    coordinator.planParallelWork('Build', makeTasks());

    expect(coordinator.isSharedReadOnly('CLAUDE.md')).toBe(true);
    expect(coordinator.isSharedReadOnly('SOUL.md')).toBe(true);
    expect(coordinator.isSharedReadOnly('.claude/agents/neo.md')).toBe(true);
    expect(coordinator.isSharedReadOnly('psi/source/config.ts')).toBe(true);
    expect(coordinator.isSharedReadOnly('src/auth/login.ts')).toBe(false);
  });

  test('isSharedReadOnly returns false when no session', () => {
    expect(coordinator.isSharedReadOnly('CLAUDE.md')).toBe(false);
  });

  test('completeSession cleans up coordination state', () => {
    coordinator.planParallelWork('Build', makeTasks());
    coordinator.completeSession();

    const session = coordinator.getSession();
    expect(session).toBeNull();
    expect(coordinator.isActive()).toBe(false);
  });

  test('completeSession archives session when archiveDir provided', () => {
    const archiveDir = join(tempDir, 'archive');
    coordinator.planParallelWork('Build', makeTasks());
    const session = coordinator.getSession();
    const sessionId = session!.sessionId;

    coordinator.completeSession(archiveDir);

    expect(existsSync(join(archiveDir, `${sessionId}.json`))).toBe(true);
  });

  test('getSession returns null when no handshake file', () => {
    expect(coordinator.getSession()).toBeNull();
  });

  test('isActive returns true for non-terminal sessions', () => {
    coordinator.planParallelWork('Build', makeTasks());
    expect(coordinator.isActive()).toBe(true);

    coordinator.transitionPhase('working');
    expect(coordinator.isActive()).toBe(true);
  });

  test('isActive returns false for complete/failed sessions', () => {
    coordinator.planParallelWork('Build', makeTasks());
    coordinator.transitionPhase('complete');
    expect(coordinator.isActive()).toBe(false);
  });
});

// ============================================================================
// StatusWriter
// ============================================================================

describe('StatusWriter', () => {
  let tempDir: string;
  let statusWriter: StatusWriter;

  beforeEach(() => {
    tempDir = makeTempDir();
    statusWriter = new StatusWriter(makeConfig(tempDir));
  });

  afterEach(() => {
    rmSync(tempDir, { recursive: true, force: true });
  });

  test('writeStatus creates a status file', () => {
    statusWriter.writeStatus('agent-1', {
      agentId: 'agent-1',
      name: 'Neo',
      status: 'working',
      currentTask: 'Implement auth',
    });

    const status = statusWriter.readStatus('agent-1');
    expect(status).not.toBeNull();
    expect(status!.name).toBe('Neo');
    expect(status!.status).toBe('working');
    expect(status!.currentTask).toBe('Implement auth');
  });

  test('writeStatus merges with existing status', () => {
    statusWriter.writeStatus('agent-1', {
      agentId: 'agent-1',
      name: 'Neo',
      worktree: '/tmp/wt-1',
      branch: 'agent-1/auth',
    });

    // Update only progress
    statusWriter.writeStatus('agent-1', {
      agentId: 'agent-1',
      progress: 0.5,
    });

    const status = statusWriter.readStatus('agent-1');
    expect(status!.name).toBe('Neo');
    expect(status!.worktree).toBe('/tmp/wt-1');
    expect(status!.progress).toBe(0.5);
  });

  test('readStatus returns null for non-existent agent', () => {
    expect(statusWriter.readStatus('nonexistent')).toBeNull();
  });

  test('readAllStatuses returns all agent statuses', () => {
    statusWriter.writeStatus('agent-1', { agentId: 'agent-1', name: 'Neo', status: 'working' });
    statusWriter.writeStatus('agent-2', { agentId: 'agent-2', name: 'Trinity', status: 'idle' });
    statusWriter.writeStatus('agent-3', { agentId: 'agent-3', name: 'Tank', status: 'blocked' });

    const all = statusWriter.readAllStatuses();
    expect(all.length).toBe(3);
  });

  test('transition updates only status and lastUpdate', () => {
    statusWriter.writeStatus('agent-1', {
      agentId: 'agent-1',
      name: 'Neo',
      status: 'idle',
      currentTask: 'Waiting',
    });

    statusWriter.transition('agent-1', 'working');

    const status = statusWriter.readStatus('agent-1');
    expect(status!.status).toBe('working');
    expect(status!.name).toBe('Neo');
    // currentTask should be preserved from the existing status
    expect(status!.currentTask).toBe('Waiting');
  });

  test('updateProgress clamps to 0-1 range', () => {
    statusWriter.writeStatus('agent-1', { agentId: 'agent-1' });

    statusWriter.updateProgress('agent-1', 1.5);
    expect(statusWriter.readStatus('agent-1')!.progress).toBe(1);

    statusWriter.updateProgress('agent-1', -0.5);
    expect(statusWriter.readStatus('agent-1')!.progress).toBe(0);

    statusWriter.updateProgress('agent-1', 0.75);
    expect(statusWriter.readStatus('agent-1')!.progress).toBe(0.75);
  });

  test('updateProgress optionally sets currentTask', () => {
    statusWriter.writeStatus('agent-1', { agentId: 'agent-1' });
    statusWriter.updateProgress('agent-1', 0.3, 'Writing tests');

    const status = statusWriter.readStatus('agent-1');
    expect(status!.progress).toBe(0.3);
    expect(status!.currentTask).toBe('Writing tests');
  });

  test('allTerminal returns true when all agents are complete or error', () => {
    statusWriter.writeStatus('agent-1', { agentId: 'agent-1', status: 'complete' });
    statusWriter.writeStatus('agent-2', { agentId: 'agent-2', status: 'error' });

    expect(statusWriter.allTerminal()).toBe(true);
  });

  test('allTerminal returns false when any agent is still working', () => {
    statusWriter.writeStatus('agent-1', { agentId: 'agent-1', status: 'complete' });
    statusWriter.writeStatus('agent-2', { agentId: 'agent-2', status: 'working' });

    expect(statusWriter.allTerminal()).toBe(false);
  });

  test('allTerminal returns false when no agents exist', () => {
    expect(statusWriter.allTerminal()).toBe(false);
  });

  test('removeStatus deletes the agent status file', () => {
    statusWriter.writeStatus('agent-1', { agentId: 'agent-1', name: 'Neo' });
    expect(statusWriter.readStatus('agent-1')).not.toBeNull();

    statusWriter.removeStatus('agent-1');
    expect(statusWriter.readStatus('agent-1')).toBeNull();
  });

  test('removeStatus is safe for non-existent agent', () => {
    // Should not throw
    statusWriter.removeStatus('nonexistent');
  });

  test('getByStatus filters correctly', () => {
    statusWriter.writeStatus('agent-1', { agentId: 'agent-1', status: 'working' });
    statusWriter.writeStatus('agent-2', { agentId: 'agent-2', status: 'idle' });
    statusWriter.writeStatus('agent-3', { agentId: 'agent-3', status: 'working' });

    const working = statusWriter.getByStatus('working');
    expect(working.length).toBe(2);
    expect(working.every(s => s.status === 'working')).toBe(true);
  });
});

// ============================================================================
// MessageBus
// ============================================================================

describe('MessageBus', () => {
  let tempDir: string;
  let bus: MessageBus;

  beforeEach(() => {
    tempDir = makeTempDir();
    bus = new MessageBus(makeConfig(tempDir));
  });

  afterEach(() => {
    rmSync(tempDir, { recursive: true, force: true });
  });

  test('send creates a message with id and timestamp', () => {
    const msg = bus.send({
      from: 'agent-1',
      to: 'agent-2',
      type: 'completion',
      subject: 'Auth done',
      body: 'Completed login implementation',
    });

    expect(msg.id).toMatch(/^msg-/);
    expect(msg.timestamp).toBeDefined();
    expect(msg.from).toBe('agent-1');
    expect(msg.to).toBe('agent-2');
    expect(msg.type).toBe('completion');
  });

  test('receive returns messages addressed to agent', () => {
    bus.send({ from: 'agent-1', to: 'agent-2', type: 'completion', subject: 'Done', body: '' });
    bus.send({ from: 'agent-1', to: 'agent-3', type: 'completion', subject: 'Other', body: '' });

    const messages = bus.receive('agent-2');
    expect(messages.length).toBe(1);
    expect(messages[0].subject).toBe('Done');
  });

  test('receive includes broadcasts (to=all)', () => {
    bus.send({ from: 'orchestrator', to: 'all', type: 'broadcast', subject: 'Start', body: '' });
    bus.send({ from: 'agent-1', to: 'agent-2', type: 'completion', subject: 'Direct', body: '' });

    const messages = bus.receive('agent-2');
    expect(messages.length).toBe(2);
  });

  test('broadcast sends to all', () => {
    const msg = bus.broadcast('orchestrator', 'broadcast', 'Phase change', 'Moving to merging');
    expect(msg.to).toBe('all');
    expect(msg.type).toBe('broadcast');

    // All agents should see broadcasts
    const agent1Msgs = bus.receive('agent-1');
    const agent2Msgs = bus.receive('agent-2');
    expect(agent1Msgs.length).toBe(1);
    expect(agent2Msgs.length).toBe(1);
  });

  test('receiveAll returns all messages regardless of recipient', () => {
    bus.send({ from: 'agent-1', to: 'agent-2', type: 'completion', subject: 'A', body: '' });
    bus.send({ from: 'agent-2', to: 'agent-3', type: 'discovery', subject: 'B', body: '' });
    bus.send({ from: 'orchestrator', to: 'all', type: 'broadcast', subject: 'C', body: '' });

    const all = bus.receiveAll();
    expect(all.length).toBe(3);
  });

  test('receiveAll filters by since timestamp', () => {
    bus.send({ from: 'agent-1', to: 'all', type: 'broadcast', subject: 'Old', body: '' });
    const cutoff = new Date();

    // Small delay so timestamp is after cutoff
    const start = Date.now();
    while (Date.now() - start < 10) { /* busy wait */ }

    bus.send({ from: 'agent-2', to: 'all', type: 'broadcast', subject: 'New', body: '' });

    const after = bus.receiveAll(cutoff);
    expect(after.length).toBe(1);
    expect(after[0].subject).toBe('New');
  });

  test('recent returns last N messages', () => {
    for (let i = 0; i < 5; i++) {
      bus.send({ from: 'agent-1', to: 'all', type: 'broadcast', subject: `Msg ${i}`, body: '' });
    }

    const last3 = bus.recent(3);
    expect(last3.length).toBe(3);
  });

  test('purge removes old messages', () => {
    bus.send({ from: 'agent-1', to: 'all', type: 'broadcast', subject: 'Old', body: '' });

    // Purge everything older than now + some margin
    const start = Date.now();
    while (Date.now() - start < 10) { /* busy wait */ }

    const purged = bus.purge(new Date());
    expect(purged).toBeGreaterThanOrEqual(1);

    const remaining = bus.receiveAll();
    expect(remaining.length).toBe(0);
  });

  test('getByType filters messages by type', () => {
    bus.send({ from: 'agent-1', to: 'all', type: 'blocker', subject: 'Blocked', body: '' });
    bus.send({ from: 'agent-1', to: 'all', type: 'completion', subject: 'Done', body: '' });
    bus.send({ from: 'agent-2', to: 'all', type: 'blocker', subject: 'Also blocked', body: '' });

    const blockers = bus.getByType('blocker');
    expect(blockers.length).toBe(2);
    expect(blockers.every(m => m.type === 'blocker')).toBe(true);
  });

  test('receive with since filter excludes old messages', () => {
    bus.send({ from: 'agent-1', to: 'agent-2', type: 'completion', subject: 'Old', body: '' });

    const cutoff = new Date();
    const start = Date.now();
    while (Date.now() - start < 10) { /* busy wait */ }

    bus.send({ from: 'agent-1', to: 'agent-2', type: 'completion', subject: 'New', body: '' });

    const messages = bus.receive('agent-2', cutoff);
    expect(messages.length).toBe(1);
    expect(messages[0].subject).toBe('New');
  });

  test('messages are sorted by timestamp (oldest first)', () => {
    bus.send({ from: 'agent-1', to: 'all', type: 'broadcast', subject: 'First', body: '' });
    // Small delay for different timestamps
    const start = Date.now();
    while (Date.now() - start < 5) { /* busy wait */ }
    bus.send({ from: 'agent-2', to: 'all', type: 'broadcast', subject: 'Second', body: '' });

    const messages = bus.receiveAll();
    expect(messages.length).toBe(2);
    expect(messages[0].subject).toBe('First');
    expect(messages[1].subject).toBe('Second');
  });
});
