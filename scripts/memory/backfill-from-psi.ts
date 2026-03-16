#!/usr/bin/env bun
/**
 * backfill-from-psi.ts - Import real markdown content into SQLite (no ChromaDB needed)
 *
 * Imports:
 * 1. Retrospectives → sessions table
 * 2. Learnings → learnings table
 * 3. ADRs → learnings table (architecture category)
 * 4. Blueprints/Plans → learnings table (architecture category)
 *
 * All entries get FTS-indexed automatically via SQLite triggers.
 */

import { createLearning, createSession, getSessionById } from '../src/core/db';
import type { LearningRecord, SessionRecord } from '../src/core/db';
import { existsSync, readFileSync, readdirSync, statSync } from 'fs';
import { join, basename } from 'path';

const PROJECT_ROOT = join(import.meta.dir, '..', '..', '..', '..');
const PSI = join(PROJECT_ROOT, 'psi');

let imported = { sessions: 0, learnings: 0, skipped: 0 };

// ─── Find markdown files recursively ───
function findMdFiles(dir: string): string[] {
  if (!existsSync(dir)) return [];
  const files: string[] = [];
  function walk(d: string) {
    for (const entry of readdirSync(d)) {
      const full = join(d, entry);
      const stat = statSync(full);
      if (stat.isDirectory()) walk(full);
      else if (entry.endsWith('.md')) files.push(full);
    }
  }
  walk(dir);
  return files;
}

// ─── Extract title from markdown ───
function extractTitle(content: string, fallback: string): string {
  const match = content.match(/^#\s+(.+)$/m);
  return match ? match[1].trim().slice(0, 200) : fallback;
}

// ─── Extract summary section ───
function extractSummary(content: string): string {
  const match = content.match(/##\s*Summary\s*\n([\s\S]*?)(?=\n##|$)/i);
  return match ? match[1].trim().slice(0, 2000) : content.slice(0, 500);
}

// ─── Detect category from path or content ───
function detectCategory(filepath: string, content: string): string {
  const pathLower = filepath.toLowerCase();
  if (pathLower.includes('/adr/')) return 'architecture';
  if (pathLower.includes('/blueprint')) return 'architecture';
  if (pathLower.includes('/plan')) return 'architecture';
  if (pathLower.includes('/retrospective')) return 'retrospective';

  // From learning subdirectory
  const dirMatch = filepath.match(/learnings\/(\w+)\//);
  if (dirMatch) return dirMatch[1];

  // Heuristic from content
  if (content.includes('security') || content.includes('vulnerability')) return 'security';
  if (content.includes('performance') || content.includes('latency')) return 'performance';
  if (content.includes('voice') || content.includes('TTS')) return 'tooling';

  return 'insight';
}

// ─── Extract date from filepath ───
function extractDate(filepath: string): string {
  const dateMatch = filepath.match(/(\d{4}-\d{2}-\d{2})/);
  const timeMatch = filepath.match(/(\d{2}\.\d{2})/);
  if (dateMatch) {
    const time = timeMatch ? timeMatch[1].replace('.', ':') : '12:00';
    return `${dateMatch[1]}T${time}:00Z`;
  }
  return statSync(filepath).mtime.toISOString();
}

// ─── Import retrospectives as sessions ───
function importRetrospectives() {
  console.log('\n📝 Importing retrospectives as sessions...');
  const files = findMdFiles(join(PSI, 'memory', 'retrospectives'));

  for (const file of files) {
    const content = readFileSync(file, 'utf-8');
    if (content.length < 50) { imported.skipped++; continue; }

    const title = extractTitle(content, basename(file, '.md'));
    const summary = extractSummary(content);
    const date = extractDate(file);
    const sessionId = `retro_${basename(file, '.md').replace(/[^a-zA-Z0-9_-]/g, '_')}`;

    // Skip if already exists
    if (getSessionById(sessionId)) { imported.skipped++; continue; }

    try {
      createSession({
        id: sessionId,
        summary: `${title}\n\n${summary}`,
        started_at: date,
        project_path: PROJECT_ROOT,
        visibility: 'public',
      } as SessionRecord);
      imported.sessions++;
    } catch (e) {
      console.log(`  ⚠ Skip ${basename(file)}: ${(e as Error).message?.slice(0, 60)}`);
      imported.skipped++;
    }
  }
  console.log(`  ✓ ${imported.sessions} sessions imported`);
}

// ─── Import learnings ───
function importLearnings() {
  console.log('\n🧠 Importing learnings...');
  const files = findMdFiles(join(PSI, 'memory', 'learnings'));
  let count = 0;

  for (const file of files) {
    const content = readFileSync(file, 'utf-8');
    if (content.length < 30) { imported.skipped++; continue; }

    const title = extractTitle(content, basename(file, '.md'));
    const category = detectCategory(file, content);
    const date = extractDate(file);

    try {
      createLearning({
        category,
        title,
        description: content.slice(0, 3000),
        confidence: 'medium',
        source_url: `file://${file}`,
        what_happened: `Imported from ${file.replace(PROJECT_ROOT, '')}`,
        lesson: extractSummary(content),
        project_path: PROJECT_ROOT,
        visibility: 'public',
      } as LearningRecord);
      count++;
    } catch (e) {
      console.log(`  ⚠ Skip ${basename(file)}: ${(e as Error).message?.slice(0, 60)}`);
      imported.skipped++;
    }
  }
  imported.learnings += count;
  console.log(`  ✓ ${count} learnings imported`);
}

// ─── Import ADRs as architecture learnings ───
function importADRs() {
  console.log('\n📐 Importing ADRs as architecture learnings...');
  const files = findMdFiles(join(PSI, 'memory', 'adr'));
  let count = 0;

  for (const file of files) {
    const content = readFileSync(file, 'utf-8');
    if (content.length < 30) { imported.skipped++; continue; }

    const title = extractTitle(content, basename(file, '.md'));

    try {
      createLearning({
        category: 'architecture',
        title: `ADR: ${title}`,
        description: content.slice(0, 3000),
        confidence: 'high',
        source_url: `file://${file}`,
        what_happened: `Architecture Decision Record: ${title}`,
        lesson: extractSummary(content),
        project_path: PROJECT_ROOT,
        visibility: 'public',
      } as LearningRecord);
      count++;
    } catch (e) {
      console.log(`  ⚠ Skip ${basename(file)}: ${(e as Error).message?.slice(0, 60)}`);
      imported.skipped++;
    }
  }
  imported.learnings += count;
  console.log(`  ✓ ${count} ADR learnings imported`);
}

// ─── Import blueprints and plans ───
function importPlansAndBlueprints() {
  console.log('\n🗺️ Importing blueprints and plans...');
  let count = 0;

  for (const subdir of ['blueprints', 'plans']) {
    const files = findMdFiles(join(PSI, 'memory', subdir));
    for (const file of files) {
      const content = readFileSync(file, 'utf-8');
      if (content.length < 30) { imported.skipped++; continue; }

      const title = extractTitle(content, basename(file, '.md'));

      try {
        createLearning({
          category: 'architecture',
          title: `${subdir === 'blueprints' ? 'Blueprint' : 'Plan'}: ${title}`,
          description: content.slice(0, 3000),
          confidence: 'medium',
          source_url: `file://${file}`,
          what_happened: `${subdir}: ${title}`,
          lesson: extractSummary(content),
          project_path: PROJECT_ROOT,
          visibility: 'public',
        } as LearningRecord);
        count++;
      } catch (e) {
        console.log(`  ⚠ Skip ${basename(file)}: ${(e as Error).message?.slice(0, 60)}`);
        imported.skipped++;
      }
    }
  }
  imported.learnings += count;
  console.log(`  ✓ ${count} plan/blueprint learnings imported`);
}

// ─── Import active research ───
function importActiveResearch() {
  console.log('\n🔬 Importing active research...');
  const files = findMdFiles(join(PSI, 'learn', 'active'));
  let count = 0;

  for (const file of files) {
    const content = readFileSync(file, 'utf-8');
    if (content.length < 50) { imported.skipped++; continue; }

    const title = extractTitle(content, basename(file, '.md'));
    const category = detectCategory(file, content);

    try {
      createLearning({
        category,
        title: `Research: ${title}`,
        description: content.slice(0, 3000),
        confidence: 'medium',
        source_url: `file://${file}`,
        what_happened: `Active research: ${title}`,
        lesson: extractSummary(content),
        project_path: PROJECT_ROOT,
        visibility: 'public',
      } as LearningRecord);
      count++;
    } catch (e) {
      console.log(`  ⚠ Skip ${basename(file)}: ${(e as Error).message?.slice(0, 60)}`);
      imported.skipped++;
    }
  }
  imported.learnings += count;
  console.log(`  ✓ ${count} research learnings imported`);
}

// ─── Main ───
console.log('═══════════════════════════════════════');
console.log('  BACKFILL: psi/ → SQLite (FTS-indexed)');
console.log('═══════════════════════════════════════');
console.log(`  Project: ${PROJECT_ROOT}`);
console.log(`  PSI dir: ${PSI}`);

importRetrospectives();
importLearnings();
importADRs();
importPlansAndBlueprints();
importActiveResearch();

console.log('\n═══════════════════════════════════════');
console.log(`  DONE: ${imported.sessions} sessions, ${imported.learnings} learnings imported`);
console.log(`  Skipped: ${imported.skipped}`);
console.log('  All entries are FTS-indexed automatically.');
console.log('═══════════════════════════════════════');
