/**
 * Merge Queue — ADR-019 Coordinated Sequential Merging
 *
 * Processes agent worktree merges in the order defined by handshake.json.
 * After each successful merge, rebases remaining branches onto the updated
 * base branch so they see the latest changes.
 *
 * Why sequential? Parallel merges create cascading conflicts. If agents 1 and 2
 * both change adjacent lines, merging both simultaneously is undefined.
 * Sequential merge with rebase ensures each merge sees the full picture.
 *
 * Lifecycle:
 *   1. Agents complete work → added to queue via enqueue()
 *   2. When all expected agents are queued (or processAll() is called)
 *   3. Process in handshake mergeOrder: merge first → rebase remaining → next
 *   4. Broadcast dependency-resolved after each successful merge
 *   5. Skip on conflict, notify orchestrator, continue with next
 *
 * See: docs/multi-agent-protocol.md#merge-queue
 */

import { createLogger } from '../utils/logger';
import { getCoordinator } from './coordinator';
import { getMessageBus } from './message-bus';
import { getStatusWriter } from './status-writer';
import { getLockManager } from './lock-manager';
import type {
  MergeQueueEntry,
  MergeQueueResult,
  CoordinationConfig,
} from './types';
import { DEFAULT_COORDINATION_CONFIG } from './types';

const log = createLogger('MergeQueue');

// ============================================================================
// Merge Queue
// ============================================================================

export class MergeQueue {
  private queue: Map<string, MergeQueueEntry> = new Map(); // keyed by taskId
  private results: MergeQueueResult[] = [];
  private processing = false;
  private config: CoordinationConfig;

  constructor(config?: Partial<CoordinationConfig>) {
    this.config = { ...DEFAULT_COORDINATION_CONFIG, ...config };
  }

  /**
   * Add an agent's completed work to the merge queue.
   */
  enqueue(entry: MergeQueueEntry): void {
    this.queue.set(entry.taskId, entry);
    log.info(`Enqueued merge: ${entry.agentId} (task: ${entry.taskId}, branch: ${entry.branch})`);
  }

  /**
   * Get the ordered list of pending merges based on handshake mergeOrder.
   * Entries not in the handshake are appended at the end by completion time.
   */
  getOrderedQueue(): MergeQueueEntry[] {
    const coordinator = getCoordinator(this.config);
    const mergeOrder = coordinator.getMergeOrder();
    const ordered: MergeQueueEntry[] = [];
    const unordered: MergeQueueEntry[] = [];

    // First: entries in handshake merge order
    for (const taskId of mergeOrder) {
      const entry = this.queue.get(taskId);
      if (entry) {
        ordered.push(entry);
      }
    }

    // Second: entries not in handshake (sorted by completion time)
    for (const [taskId, entry] of this.queue) {
      if (!mergeOrder.includes(taskId)) {
        unordered.push(entry);
      }
    }
    unordered.sort((a, b) => a.completedAt.localeCompare(b.completedAt));

    return [...ordered, ...unordered];
  }

  /**
   * Process all queued merges sequentially.
   *
   * For each merge:
   *   1. Merge the agent's branch into base
   *   2. If successful: rebase remaining queued branches, broadcast, cleanup
   *   3. If conflict: skip, notify, continue
   *
   * Returns results for all processed entries.
   */
  async processAll(repoPath: string): Promise<MergeQueueResult[]> {
    if (this.processing) {
      log.warn('Merge queue is already processing');
      return this.results;
    }

    this.processing = true;
    this.results = [];
    const messageBus = getMessageBus(this.config);
    const coordinator = getCoordinator(this.config);
    const statusWriter = getStatusWriter(this.config);
    const lockManager = getLockManager(this.config);

    const ordered = this.getOrderedQueue();
    log.info(`Processing merge queue: ${ordered.length} entries`);

    // Transition session to merging phase
    coordinator.transitionPhase('merging');

    for (let i = 0; i < ordered.length; i++) {
      const entry = ordered[i];
      log.info(`Merging ${i + 1}/${ordered.length}: ${entry.agentId} (${entry.branch})`);

      try {
        const result = await this.mergeOne(entry, repoPath);
        this.results.push(result);

        if (result.success) {
          // Update task status in handshake
          coordinator.updateTaskStatus(entry.taskId, 'complete');

          // Release agent's locks
          lockManager.releaseAllForAgent(entry.agentId);

          // Update agent status
          statusWriter.transition(entry.agentId, 'complete');

          // Broadcast dependency-resolved so blocked agents can unblock
          const unblocked = coordinator.resolveDependencies(entry.taskId);
          if (unblocked.length > 0) {
            messageBus.broadcast(
              'orchestrator',
              'dependency-resolved',
              `Task ${entry.taskId} merged — unblocked: ${unblocked.join(', ')}`,
              JSON.stringify({ mergedTask: entry.taskId, unblocked, commitHash: result.commitHash })
            );
          }

          // Broadcast merge success
          messageBus.broadcast(
            'orchestrator',
            'completion',
            `Merged ${entry.branch} into base`,
            JSON.stringify({ agentId: entry.agentId, branch: entry.branch, commitHash: result.commitHash })
          );

          // Rebase remaining queued branches onto updated base
          const remaining = ordered.slice(i + 1);
          if (remaining.length > 0) {
            await this.rebaseRemaining(remaining, repoPath);
          }

          // Remove from queue
          this.queue.delete(entry.taskId);

          log.info(`Merge successful: ${entry.branch} → ${result.commitHash}`);
        } else {
          // Merge failed — skip and continue
          log.warn(`Merge failed for ${entry.branch}: ${result.error}`, {
            conflictFiles: result.conflictFiles,
          });

          // Notify orchestrator of conflict
          messageBus.send({
            from: 'merge-queue',
            to: 'orchestrator',
            type: 'blocker',
            subject: `Merge conflict: ${entry.branch}`,
            body: JSON.stringify({
              agentId: entry.agentId,
              taskId: entry.taskId,
              branch: entry.branch,
              conflictFiles: result.conflictFiles,
              error: result.error,
            }),
          });

          // Mark task as error in handshake
          coordinator.updateTaskStatus(entry.taskId, 'error');
          statusWriter.transition(entry.agentId, 'error');
        }
      } catch (err) {
        const error = err instanceof Error ? err.message : String(err);
        log.error(`Unexpected error merging ${entry.branch}: ${error}`);

        this.results.push({
          agentId: entry.agentId,
          branch: entry.branch,
          success: false,
          error: `Unexpected: ${error}`,
        });

        coordinator.updateTaskStatus(entry.taskId, 'error');
      }
    }

    this.processing = false;

    // Check if session is ready to complete
    const session = coordinator.getSession();
    if (session) {
      const allDone = session.plan.decomposition.every(
        t => t.status === 'complete' || t.status === 'error'
      );
      if (allDone) {
        log.info('All merges processed — session ready for completion');
      }
    }

    log.info(`Merge queue complete: ${this.results.filter(r => r.success).length}/${this.results.length} successful`);
    return this.results;
  }

  /**
   * Merge a single agent's branch into the base branch.
   */
  private async mergeOne(entry: MergeQueueEntry, repoPath: string): Promise<MergeQueueResult> {
    const { $ } = await import('bun');

    // Detect base branch
    const baseBranch = await this.detectBaseBranch(repoPath);

    // Ensure we're on the base branch
    const checkoutResult = await $`git -C ${repoPath} checkout ${baseBranch}`.quiet().nothrow();
    if (checkoutResult.exitCode !== 0) {
      return {
        agentId: entry.agentId,
        branch: entry.branch,
        success: false,
        error: `Failed to checkout ${baseBranch}: ${checkoutResult.stderr}`,
      };
    }

    // Check if there are commits to merge
    const logOutput = await $`git -C ${repoPath} log ${baseBranch}..${entry.branch} --oneline`.text().catch(() => '');
    if (!logOutput.trim()) {
      return {
        agentId: entry.agentId,
        branch: entry.branch,
        success: true,
        commitHash: undefined,
      };
    }

    // Attempt merge with no-ff for clean history
    const mergeResult = await $`git -C ${repoPath} merge --no-ff ${entry.branch} -m "Merge ${entry.agentId} work from ${entry.branch}"`.quiet().nothrow();

    if (mergeResult.exitCode === 0) {
      const commitHash = (await $`git -C ${repoPath} rev-parse HEAD`.text().catch(() => '')).trim();
      return {
        agentId: entry.agentId,
        branch: entry.branch,
        success: true,
        commitHash,
      };
    }

    // Merge conflict — get conflict files and abort
    const conflictOutput = await $`git -C ${repoPath} diff --name-only --diff-filter=U`.text().catch(() => '');
    const conflictFiles = conflictOutput.split('\n').filter(Boolean);

    // Abort the failed merge
    await $`git -C ${repoPath} merge --abort`.quiet().nothrow();

    return {
      agentId: entry.agentId,
      branch: entry.branch,
      success: false,
      conflictFiles,
      error: 'Merge conflict',
    };
  }

  /**
   * Rebase remaining queued branches onto the updated base branch.
   * If rebase fails for a branch, log a warning but don't block the queue.
   */
  private async rebaseRemaining(remaining: MergeQueueEntry[], repoPath: string): Promise<void> {
    const { $ } = await import('bun');
    const baseBranch = await this.detectBaseBranch(repoPath);

    for (const entry of remaining) {
      // If the agent has a worktree, rebase in the worktree
      const targetPath = entry.worktree || repoPath;

      try {
        // Fetch latest base in the worktree
        await $`git -C ${targetPath} fetch origin ${baseBranch}`.quiet().nothrow();

        // Attempt rebase
        const result = await $`git -C ${targetPath} rebase ${baseBranch}`.quiet().nothrow();

        if (result.exitCode === 0) {
          log.info(`Rebased ${entry.branch} onto ${baseBranch}`);
        } else {
          // Abort failed rebase — agent will need to resolve manually or at merge time
          await $`git -C ${targetPath} rebase --abort`.quiet().nothrow();
          log.warn(`Rebase failed for ${entry.branch} — will attempt merge without rebase`);
        }
      } catch {
        log.warn(`Could not rebase ${entry.branch} — skipping`);
      }
    }
  }

  /**
   * Detect the base branch for the repo.
   */
  private async detectBaseBranch(repoPath: string): Promise<string> {
    const { $ } = await import('bun');

    for (const branch of ['main', 'master']) {
      const result = await $`git -C ${repoPath} rev-parse --verify ${branch}`.quiet().nothrow();
      if (result.exitCode === 0) return branch;
    }

    const current = (await $`git -C ${repoPath} branch --show-current`.text().catch(() => 'main')).trim();
    return current || 'main';
  }

  // ============================================================================
  // Query
  // ============================================================================

  /**
   * Get current queue size.
   */
  get size(): number {
    return this.queue.size;
  }

  /**
   * Check if the queue is currently processing.
   */
  get isProcessing(): boolean {
    return this.processing;
  }

  /**
   * Get results from the last processAll() run.
   */
  getResults(): MergeQueueResult[] {
    return [...this.results];
  }

  /**
   * Get all queued entries (unordered).
   */
  getEntries(): MergeQueueEntry[] {
    return Array.from(this.queue.values());
  }

  /**
   * Check if a specific task is queued.
   */
  isQueued(taskId: string): boolean {
    return this.queue.has(taskId);
  }

  /**
   * Remove an entry from the queue (e.g., if agent is cancelled).
   */
  dequeue(taskId: string): boolean {
    return this.queue.delete(taskId);
  }

  /**
   * Clear the queue and results.
   */
  clear(): void {
    this.queue.clear();
    this.results = [];
  }
}

// ============================================================================
// Singleton
// ============================================================================

let instance: MergeQueue | null = null;

export function getMergeQueue(config?: Partial<CoordinationConfig>): MergeQueue {
  if (!instance) {
    instance = new MergeQueue(config);
  }
  return instance;
}
