/**
 * Matrix Nerve — Entry Point
 *
 * Self-healing nervous system for The Matrix.
 * Manages daemon health with L1→L5 escalation,
 * known-fix pattern matching, and state transition detection.
 *
 * Can run standalone or as a module in the heartbeat daemon.
 */

export { Supervisor } from './supervisor';
export { EscalationEngine } from './escalation';
export { StateDetector } from './state-detector';
export { KnownFixEngine } from './known-fixes';
export * from './types';

import { Supervisor } from './supervisor';

/**
 * Create and initialize a Nerve supervisor with default Matrix daemons.
 */
export async function createNerve(cwd: string): Promise<Supervisor> {
  const supervisor = new Supervisor(cwd);

  // Register all Matrix daemons
  supervisor.register('heartbeat', 37892, 'bun run src/daemons/heartbeat/heartbeat-daemon.ts start');
  supervisor.register('gateway', 8082, 'bun run src/daemons/gateway/matrix-gateway.ts');
  supervisor.register('hub', 8081, 'bun run src/daemons/hub/matrix-hub.ts');
  supervisor.register('indexer', 37890, 'bun run src/memory/indexer/indexer-daemon.ts start');

  await supervisor.init();
  return supervisor;
}
