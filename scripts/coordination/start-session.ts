#!/usr/bin/env bun
/**
 * start-session.ts — Create a coordination session for parallel agent work
 * Usage: bun run scripts/coordination/start-session.ts --agents 3 --task "Build feature X"
 */

import { existsSync, mkdirSync } from 'fs';
import { join } from 'path';
import { homedir } from 'os';
import { getCoordinator } from '../../lib/matrix-memory-agents/src/coordination/index';

// Parse args
const args = process.argv.slice(2);
let agentCount = 3;
let task = '';

for (let i = 0; i < args.length; i++) {
  if (args[i] === '--agents' && args[i + 1]) {
    agentCount = parseInt(args[i + 1], 10);
    i++;
  } else if (args[i] === '--task' && args[i + 1]) {
    task = args[i + 1];
    i++;
  }
}

if (!task) {
  console.error('Usage: start-session.ts --agents <n> --task "<description>"');
  console.error('  --agents  Number of agents (default: 3)');
  console.error('  --task    Task description (required)');
  process.exit(1);
}

// Ensure coordination dirs exist
const baseDir = join(homedir(), '.matrix', 'coordination');
for (const sub of ['agents', 'messages', 'locks', 'results']) {
  const dir = join(baseDir, sub);
  if (!existsSync(dir)) {
    mkdirSync(dir, { recursive: true });
  }
}

// Build task decomposition stubs for each agent
const tasks = Array.from({ length: agentCount }, (_, i) => ({
  taskId: `task-${i + 1}`,
  assignee: `agent-${i + 1}`,
  scope: [] as string[],
  branch: `agent-${i + 1}/work`,
  status: 'planned' as const,
  dependsOn: [] as string[],
}));

// Start session
const coordinator = getCoordinator();
const session = coordinator.planParallelWork(task, tasks);

console.log(`\x1b[32mSession created\x1b[0m`);
console.log(`  ID:     ${session.sessionId}`);
console.log(`  Task:   ${task}`);
console.log(`  Agents: ${agentCount}`);
console.log(`  Phase:  ${session.phase}`);
console.log(`  Dir:    ${baseDir}`);
console.log('');
console.log('Task assignments:');
for (const t of session.plan.decomposition) {
  console.log(`  ${t.taskId} -> ${t.assignee} (branch: ${t.branch})`);
}
console.log('');
console.log(`Merge order: ${session.plan.mergeOrder.join(' -> ')}`);
