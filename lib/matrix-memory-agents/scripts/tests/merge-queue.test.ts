/**
 * Merge Queue Tests — ADR-019 Coordinated Sequential Merging
 *
 * Tests for the merge queue module (queue management only):
 * - enqueue: adding entries to the queue
 * - getOrderedQueue: follows handshake merge order
 * - dequeue: removing entries from the queue
 * - clear: clearing the queue
 * - size: tracking queue size
 *
 * NOTE: processAll() requires real git operations, so only queue
 * management methods are tested here. Integration tests for actual
 * merging should use a real git repo fixture.
 */

import { describe, test, expect, beforeEach, afterEach } from 'bun:test';
import { mkdtempSync, rmSync } from 'fs';
import { join } from 'path';
import { tmpdir } from 'os';
import { MergeQueue } from '../../src/coordination/merge-queue';
import { Coordinator } from '../../src/coordination/coordinator';
import type { MergeQueueEntry, CoordinationConfig, TaskDecomposition } from '../../src/coordination/types';

// ============================================================================
// Helpers
// ============================================================================

function makeTempDir(): string {
  return mkdtempSync(join(tmpdir(), 'merge-queue-test-'));
}

function makeConfig(baseDir: string): Partial<CoordinationConfig> {
  return {
    baseDir,
    lockExpiryMs: 60 * 60 * 1000,
    messageTtlMs: 60 * 60 * 1000,
    statusPollMs: 2000,
  };
}

function makeEntry(taskId: string, agentId: string, branch: string): MergeQueueEntry {
  return {
    agentId,
    taskId,
    branch,
    worktree: `/tmp/worktrees/${agentId}`,
    completedAt: new Date().toISOString(),
    priority: 0,
  };
}

function makeTasks(): TaskDecomposition[] {
  return [
    {
      taskId: 'task-auth',
      assignee: 'Neo (agent-1)',
      scope: ['src/auth/**'],
      branch: 'agent-1/feature-auth',
      status: 'complete',
      dependsOn: [],
    },
    {
      taskId: 'task-api',
      assignee: 'Trinity (agent-2)',
      scope: ['src/api/**'],
      branch: 'agent-2/feature-api',
      status: 'complete',
      dependsOn: [],
    },
    {
      taskId: 'task-tests',
      assignee: 'Tank (agent-3)',
      scope: ['tests/**'],
      branch: 'agent-3/feature-tests',
      status: 'complete',
      dependsOn: ['task-auth', 'task-api'],
    },
  ];
}

// ============================================================================
// Merge Queue Tests
// ============================================================================

describe('MergeQueue', () => {
  let tempDir: string;
  let mergeQueue: MergeQueue;
  let coordinator: Coordinator;

  beforeEach(() => {
    tempDir = makeTempDir();
    const config = makeConfig(tempDir);
    mergeQueue = new MergeQueue(config);
    coordinator = new Coordinator(config);
  });

  afterEach(() => {
    rmSync(tempDir, { recursive: true, force: true });
  });

  test('enqueue adds entry to queue', () => {
    const entry = makeEntry('task-auth', 'agent-1', 'agent-1/feature-auth');
    mergeQueue.enqueue(entry);

    expect(mergeQueue.size).toBe(1);
    expect(mergeQueue.isQueued('task-auth')).toBe(true);
  });

  test('enqueue replaces duplicate taskId', () => {
    const entry1 = makeEntry('task-auth', 'agent-1', 'agent-1/feature-auth');
    const entry2 = makeEntry('task-auth', 'agent-1', 'agent-1/feature-auth-v2');

    mergeQueue.enqueue(entry1);
    mergeQueue.enqueue(entry2);

    expect(mergeQueue.size).toBe(1);
    const entries = mergeQueue.getEntries();
    expect(entries[0].branch).toBe('agent-1/feature-auth-v2');
  });

  test('getOrderedQueue follows handshake merge order', () => {
    // Create a session with a specific merge order
    const tasks = makeTasks();
    const mergeOrder = ['task-api', 'task-auth', 'task-tests'];
    coordinator.planParallelWork('Build', tasks, mergeOrder);

    // Enqueue in a different order
    mergeQueue.enqueue(makeEntry('task-tests', 'agent-3', 'agent-3/feature-tests'));
    mergeQueue.enqueue(makeEntry('task-auth', 'agent-1', 'agent-1/feature-auth'));
    mergeQueue.enqueue(makeEntry('task-api', 'agent-2', 'agent-2/feature-api'));

    const ordered = mergeQueue.getOrderedQueue();
    expect(ordered.length).toBe(3);
    // Should follow handshake merge order: api, auth, tests
    expect(ordered[0].taskId).toBe('task-api');
    expect(ordered[1].taskId).toBe('task-auth');
    expect(ordered[2].taskId).toBe('task-tests');
  });

  test('getOrderedQueue appends unordered entries at the end', () => {
    // Create a session that only knows about 2 tasks
    const tasks = makeTasks().slice(0, 2);
    coordinator.planParallelWork('Build', tasks);

    // Enqueue 3 entries — one not in the handshake
    mergeQueue.enqueue(makeEntry('task-auth', 'agent-1', 'agent-1/feature-auth'));
    mergeQueue.enqueue(makeEntry('task-api', 'agent-2', 'agent-2/feature-api'));
    mergeQueue.enqueue(makeEntry('task-extra', 'agent-4', 'agent-4/feature-extra'));

    const ordered = mergeQueue.getOrderedQueue();
    expect(ordered.length).toBe(3);
    // Handshake entries first (in order), then unknown entry at end
    expect(ordered[0].taskId).toBe('task-auth');
    expect(ordered[1].taskId).toBe('task-api');
    expect(ordered[2].taskId).toBe('task-extra');
  });

  test('dequeue removes entry from queue', () => {
    mergeQueue.enqueue(makeEntry('task-auth', 'agent-1', 'agent-1/feature-auth'));
    mergeQueue.enqueue(makeEntry('task-api', 'agent-2', 'agent-2/feature-api'));

    const removed = mergeQueue.dequeue('task-auth');
    expect(removed).toBe(true);
    expect(mergeQueue.size).toBe(1);
    expect(mergeQueue.isQueued('task-auth')).toBe(false);
    expect(mergeQueue.isQueued('task-api')).toBe(true);
  });

  test('dequeue returns false for non-existent entry', () => {
    const removed = mergeQueue.dequeue('nonexistent');
    expect(removed).toBe(false);
  });

  test('clear removes all entries and results', () => {
    mergeQueue.enqueue(makeEntry('task-auth', 'agent-1', 'agent-1/feature-auth'));
    mergeQueue.enqueue(makeEntry('task-api', 'agent-2', 'agent-2/feature-api'));

    mergeQueue.clear();
    expect(mergeQueue.size).toBe(0);
    expect(mergeQueue.getEntries().length).toBe(0);
    expect(mergeQueue.getResults().length).toBe(0);
  });

  test('size returns current queue count', () => {
    expect(mergeQueue.size).toBe(0);

    mergeQueue.enqueue(makeEntry('task-1', 'agent-1', 'branch-1'));
    expect(mergeQueue.size).toBe(1);

    mergeQueue.enqueue(makeEntry('task-2', 'agent-2', 'branch-2'));
    expect(mergeQueue.size).toBe(2);

    mergeQueue.dequeue('task-1');
    expect(mergeQueue.size).toBe(1);

    mergeQueue.clear();
    expect(mergeQueue.size).toBe(0);
  });

  test('isQueued returns correct boolean', () => {
    expect(mergeQueue.isQueued('task-1')).toBe(false);

    mergeQueue.enqueue(makeEntry('task-1', 'agent-1', 'branch-1'));
    expect(mergeQueue.isQueued('task-1')).toBe(true);

    mergeQueue.dequeue('task-1');
    expect(mergeQueue.isQueued('task-1')).toBe(false);
  });

  test('isProcessing is false by default', () => {
    expect(mergeQueue.isProcessing).toBe(false);
  });

  test('getEntries returns all queued entries', () => {
    mergeQueue.enqueue(makeEntry('task-auth', 'agent-1', 'branch-1'));
    mergeQueue.enqueue(makeEntry('task-api', 'agent-2', 'branch-2'));

    const entries = mergeQueue.getEntries();
    expect(entries.length).toBe(2);
    const taskIds = entries.map(e => e.taskId).sort();
    expect(taskIds).toEqual(['task-api', 'task-auth']);
  });

  test('getResults returns empty array before processAll', () => {
    expect(mergeQueue.getResults()).toEqual([]);
  });

  test('multiple enqueue and dequeue operations maintain consistency', () => {
    mergeQueue.enqueue(makeEntry('task-1', 'agent-1', 'b1'));
    mergeQueue.enqueue(makeEntry('task-2', 'agent-2', 'b2'));
    mergeQueue.enqueue(makeEntry('task-3', 'agent-3', 'b3'));
    expect(mergeQueue.size).toBe(3);

    mergeQueue.dequeue('task-2');
    expect(mergeQueue.size).toBe(2);
    expect(mergeQueue.isQueued('task-2')).toBe(false);

    mergeQueue.enqueue(makeEntry('task-4', 'agent-4', 'b4'));
    expect(mergeQueue.size).toBe(3);

    mergeQueue.clear();
    expect(mergeQueue.size).toBe(0);
  });
});
