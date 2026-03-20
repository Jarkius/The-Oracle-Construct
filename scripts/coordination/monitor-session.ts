#!/usr/bin/env bun
/**
 * monitor-session.ts — Display real-time coordination status
 * Usage: bun run scripts/coordination/monitor-session.ts
 */

import { existsSync, readdirSync, readFileSync } from 'fs';
import { join } from 'path';
import { homedir } from 'os';
import { getCoordinator, getStatusWriter, getMergeQueue } from '../../lib/matrix-memory-agents/src/coordination/index';
import type { AgentStatusRecord, FileLock, CoordinationMessage } from '../../lib/matrix-memory-agents/src/coordination/index';

const baseDir = join(homedir(), '.matrix', 'coordination');
const RESET = '\x1b[0m';
const BOLD = '\x1b[1m';
const GREEN = '\x1b[32m';
const YELLOW = '\x1b[33m';
const RED = '\x1b[31m';
const CYAN = '\x1b[36m';
const DIM = '\x1b[2m';

function statusColor(status: string): string {
  switch (status) {
    case 'complete': return GREEN;
    case 'working': return CYAN;
    case 'blocked': case 'error': return RED;
    case 'idle': case 'starting': return YELLOW;
    default: return RESET;
  }
}

// Session info
const coordinator = getCoordinator();
const session = coordinator.getSession();
console.log(`${BOLD}=== Coordination Monitor ===${RESET}\n`);

if (session) {
  const phaseColor = session.phase === 'complete' ? GREEN : session.phase === 'failed' ? RED : CYAN;
  console.log(`Session: ${session.sessionId}`);
  console.log(`Phase:   ${phaseColor}${session.phase}${RESET}`);
  console.log(`Task:    ${session.plan.description}`);
  console.log(`Updated: ${DIM}${session.lastHeartbeat}${RESET}\n`);
} else {
  console.log(`${YELLOW}No active session${RESET}\n`);
}

// Agents table
console.log(`${BOLD}--- AGENTS ---${RESET}`);
const statuses = getStatusWriter().readAllStatuses();
if (statuses.length === 0) {
  console.log(`${DIM}  (no agents)${RESET}`);
} else {
  console.log(`  ${'ID'.padEnd(16)} ${'Status'.padEnd(12)} ${'Progress'.padEnd(10)} ${'Task'.padEnd(30)} Updated`);
  for (const s of statuses) {
    const pct = `${Math.round(s.progress * 100)}%`.padEnd(10);
    const c = statusColor(s.status);
    console.log(`  ${s.agentId.padEnd(16)} ${c}${s.status.padEnd(12)}${RESET} ${pct} ${(s.currentTask || '-').padEnd(30)} ${DIM}${s.lastUpdate}${RESET}`);
  }
}
console.log('');

// Locks table
console.log(`${BOLD}--- FILE LOCKS ---${RESET}`);
const locksDir = join(baseDir, 'locks');
const locks: FileLock[] = [];
try {
  for (const f of readdirSync(locksDir)) {
    if (!f.endsWith('.lock')) continue;
    try { locks.push(JSON.parse(readFileSync(join(locksDir, f), 'utf8'))); } catch { /* skip */ }
  }
} catch { /* dir missing */ }

if (locks.length === 0) {
  console.log(`${DIM}  (no locks)${RESET}`);
} else {
  console.log(`  ${'File'.padEnd(40)} ${'Owner'.padEnd(16)} Expires`);
  for (const l of locks) {
    console.log(`  ${l.path.padEnd(40)} ${l.owner.padEnd(16)} ${DIM}${l.expiresAt}${RESET}`);
  }
}
console.log('');

// Merge queue
console.log(`${BOLD}--- MERGE QUEUE ---${RESET}`);
const queue = getMergeQueue().getOrderedQueue();
if (queue.length === 0) {
  console.log(`${DIM}  (empty)${RESET}`);
} else {
  for (let i = 0; i < queue.length; i++) {
    const e = queue[i];
    console.log(`  ${i + 1}. ${e.agentId} — branch: ${CYAN}${e.branch}${RESET} (task: ${e.taskId})`);
  }
}
console.log('');

// Recent messages (last 5)
console.log(`${BOLD}--- RECENT MESSAGES ---${RESET}`);
const msgsDir = join(baseDir, 'messages');
const msgs: CoordinationMessage[] = [];
try {
  const files = readdirSync(msgsDir).filter(f => f.endsWith('.json')).sort().reverse().slice(0, 5);
  for (const f of files) {
    try { msgs.push(JSON.parse(readFileSync(join(msgsDir, f), 'utf8'))); } catch { /* skip */ }
  }
} catch { /* dir missing */ }

if (msgs.length === 0) {
  console.log(`${DIM}  (no messages)${RESET}`);
} else {
  for (const m of msgs) {
    console.log(`  ${DIM}${m.timestamp}${RESET} [${m.type}] ${m.from} -> ${m.to}: ${m.subject}`);
  }
}
