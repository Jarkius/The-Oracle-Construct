#!/usr/bin/env bun
/**
 * Release all locks held by a specific agent.
 *
 * Called by matrix-subagent-complete.sh when an agent finishes.
 * Usage: bun run scripts/coordination/release-agent-locks.ts <agent-id>
 */

import { readdirSync, readFileSync, unlinkSync } from 'fs';
import { join } from 'path';

const agentId = process.argv[2];
if (!agentId) {
  console.error('Usage: release-agent-locks.ts <agent-id>');
  process.exit(1);
}

const locksDir = join(process.env.HOME || process.env.USERPROFILE || '/tmp', '.matrix', 'coordination', 'locks');

let released = 0;
try {
  for (const file of readdirSync(locksDir)) {
    if (!file.endsWith('.lock')) continue;
    try {
      const lock = JSON.parse(readFileSync(join(locksDir, file), 'utf8'));
      if (lock.owner === agentId) {
        unlinkSync(join(locksDir, file));
        released++;
      }
    } catch { /* skip */ }
  }
} catch { /* dir may not exist */ }

if (released > 0) {
  console.log(`Released ${released} locks for agent ${agentId}`);
}
