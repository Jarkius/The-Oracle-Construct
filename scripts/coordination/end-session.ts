#!/usr/bin/env bun
/**
 * end-session.ts — End coordination session, trigger merge queue, cleanup
 * Usage: bun run scripts/coordination/end-session.ts [--force]
 */

import { existsSync, mkdirSync, readdirSync, unlinkSync } from 'fs';
import { join } from 'path';
import { homedir } from 'os';
import { getCoordinator, getMergeQueue, getLockManager } from '../../lib/matrix-memory-agents/src/coordination/index';

const force = process.argv.includes('--force');
const baseDir = join(homedir(), '.matrix', 'coordination');
const projectRoot = join(import.meta.dir, '..', '..');

const coordinator = getCoordinator();
const session = coordinator.getSession();

if (!session) {
  console.log('No active coordination session.');
  process.exit(0);
}

if (session.phase === 'complete') {
  console.log(`Session ${session.sessionId} is already complete.`);
  process.exit(0);
}

// Warn if not forced and agents are still working
const workingTasks = session.plan.decomposition.filter(t => t.status === 'working');
if (workingTasks.length > 0 && !force) {
  console.error(`${workingTasks.length} task(s) still working. Use --force to end anyway.`);
  console.error('Working tasks:');
  for (const t of workingTasks) {
    console.error(`  ${t.taskId} — ${t.assignee}`);
  }
  process.exit(1);
}

console.log(`Ending session: ${session.sessionId}`);
console.log(`  Phase: ${session.phase}`);
console.log(`  Tasks: ${session.plan.decomposition.length}`);
console.log('');

// Process merge queue
const mergeQueue = getMergeQueue();
const queued = mergeQueue.getOrderedQueue();
let mergeResults: { success: number; failed: number } = { success: 0, failed: 0 };

if (queued.length > 0) {
  console.log(`Processing merge queue (${queued.length} entries)...`);
  const results = await mergeQueue.processAll(projectRoot);
  mergeResults.success = results.filter(r => r.success).length;
  mergeResults.failed = results.filter(r => !r.success).length;
  console.log(`  Merged: ${mergeResults.success} success, ${mergeResults.failed} failed`);
} else {
  console.log('Merge queue: empty (nothing to merge)');
}

// Release all locks
const locksDir = join(baseDir, 'locks');
let locksReleased = 0;
try {
  for (const f of readdirSync(locksDir)) {
    if (!f.endsWith('.lock')) continue;
    try { unlinkSync(join(locksDir, f)); locksReleased++; } catch { /* skip */ }
  }
} catch { /* dir missing */ }
console.log(`Locks released: ${locksReleased}`);

// Archive session
const archiveDir = join(projectRoot, 'psi', 'memory', 'sessions');
mkdirSync(archiveDir, { recursive: true });
coordinator.completeSession(archiveDir);
console.log(`Session archived to: ${archiveDir}/${session.sessionId}.json`);

// Clean transient files
const transientDirs = ['agents', 'messages', 'results'];
let cleaned = 0;
for (const sub of transientDirs) {
  const dir = join(baseDir, sub);
  try {
    for (const f of readdirSync(dir)) {
      try { unlinkSync(join(dir, f)); cleaned++; } catch { /* skip */ }
    }
  } catch { /* dir missing */ }
}
console.log(`Cleaned ${cleaned} transient files`);

// Summary
console.log('');
console.log('\x1b[32mSession ended.\x1b[0m');
console.log(`  Session:  ${session.sessionId}`);
console.log(`  Merges:   ${mergeResults.success} ok, ${mergeResults.failed} failed`);
console.log(`  Locks:    ${locksReleased} released`);
console.log(`  Cleaned:  ${cleaned} files`);
