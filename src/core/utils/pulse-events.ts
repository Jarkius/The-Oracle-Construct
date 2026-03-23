import { appendFile } from 'node:fs/promises';
import { join } from 'path';
import { PROJECT_ROOT } from '../paths';

const EVENTS_PATH = join(PROJECT_ROOT, 'psi', 'state', 'pulse', 'events.jsonl');

export async function emitPulseEvent(
  type: string,
  agent: string,
  data: Record<string, unknown> = {}
): Promise<void> {
  const event = JSON.stringify({
    ts: new Date().toISOString(),
    type,
    agent,
    session: process.env.SESSION_ID || 'unknown',
    data
  });
  await appendFile(EVENTS_PATH, event + '\n');
}
