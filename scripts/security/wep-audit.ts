#!/usr/bin/env bun
/**
 * wep-audit.ts — WEP Sacred File Audit Tool
 *
 * Scans WEP proposals against SACRED_FILES to report violations.
 *
 * Usage:
 *   bun run scripts/security/wep-audit.ts
 */

import { existsSync, readFileSync, readdirSync } from 'fs';
import { join } from 'path';

const PROJECT_ROOT = process.env.PROJECT_ROOT || process.cwd();
const PROPOSALS_DIR = join(PROJECT_ROOT, 'psi', 'memory', 'evolution', 'proposals');

const SACRED_FILES = [
  'SOUL.md',
  'CLAUDE.md',
  'USER.md',
  'BOOT.md',
  'VOICE_CALIBRATION.md',
  'psi/source/',
  '.claude/agents/',
  'psi/state/pulse/heartbeat.json',
  'lib/matrix-memory-agents/src/heartbeat/',
  '.claude/hooks/',
];

function extractAffectedFiles(content: string): string[] {
  const files: string[] = [];
  let inAffected = false;

  for (const line of content.split('\n')) {
    if (/^affected_files:/.test(line)) {
      inAffected = true;
      continue;
    }
    if (inAffected) {
      const match = line.match(/^\s+-\s+(.+)$/);
      if (match) {
        files.push(match[1].trim());
      } else if (!/^\s/.test(line)) {
        break;
      }
    }
  }

  return files;
}

function isSacred(filepath: string): string | null {
  for (const sacred of SACRED_FILES) {
    if (filepath.includes(sacred)) return sacred;
  }
  return null;
}

function main() {
  console.log('WEP Sacred File Audit');
  console.log('====================\n');

  if (!existsSync(PROPOSALS_DIR)) {
    console.log('No proposals directory found — nothing to audit.');
    process.exit(0);
  }

  const files = readdirSync(PROPOSALS_DIR).filter(f => f.startsWith('WEP-') && f.endsWith('.md'));
  if (files.length === 0) {
    console.log('No WEP proposals found — clean.');
    process.exit(0);
  }

  let violations = 0;

  for (const file of files) {
    const content = readFileSync(join(PROPOSALS_DIR, file), 'utf8');
    const affected = extractAffectedFiles(content);

    for (const af of affected) {
      const sacred = isSacred(af);
      if (sacred) {
        console.log(`  VIOLATION: ${file} → ${af} (sacred: ${sacred})`);
        violations++;
      }
    }
  }

  console.log(`\nAudited ${files.length} WEPs. ${violations} violation(s) found.`);
  process.exit(violations > 0 ? 1 : 0);
}

main();
