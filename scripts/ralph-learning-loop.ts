/**
 * Ralph Learning Loop - Continuous learning evolution
 *
 * Cycles through:
 * 1. Capture learnings from recent work
 * 2. Distill sessions into structured knowledge
 * 3. Consolidate duplicates
 * 4. Validate useful learnings
 * 5. Report metrics
 */

import { getLearningLoop } from '../src/memory/learning/loop';
import { runConsolidation } from '../src/memory/learning/consolidation';
import { runMigration } from './memory/migrate-dual-collection';
import { listLearningsFromDb, listSessionsFromDb, validateLearning } from '../src/core/db';
import { initVectorDB, isInitialized } from '../src/memory/vector-db';

interface IterationStats {
  iteration: number;
  distilled: number;
  consolidated: number;
  migrated: { knowledge: number; lessons: number };
  validated: number;
  totals: {
    learnings: number;
    knowledge: number;
    lessons: number;
    byConfidence: Record<string, number>;
  };
}

async function getMetrics() {
  const learnings = listLearningsFromDb({ limit: 10000 });
  const byConfidence: Record<string, number> = { proven: 0, high: 0, medium: 0, low: 0 };

  for (const l of learnings) {
    const conf = l.confidence || 'low';
    byConfidence[conf] = (byConfidence[conf] || 0) + 1;
  }

  // Count knowledge and lessons via SQL
  const { Database } = await import('bun:sqlite');
  const db = new Database('data/agents.db');
  const knowledgeCount = db.query('SELECT COUNT(*) as count FROM knowledge').get() as { count: number };
  const lessonsCount = db.query('SELECT COUNT(*) as count FROM lessons').get() as { count: number };
  db.close();

  return {
    learnings: learnings.length,
    knowledge: knowledgeCount.count,
    lessons: lessonsCount.count,
    byConfidence,
  };
}

async function runIteration(iteration: number): Promise<IterationStats> {
  console.log(`\n${'='.repeat(60)}`);
  console.log(`  ITERATION ${iteration}`);
  console.log(`${'='.repeat(60)}\n`);

  const loop = getLearningLoop();
  const stats: IterationStats = {
    iteration,
    distilled: 0,
    consolidated: 0,
    migrated: { knowledge: 0, lessons: 0 },
    validated: 0,
    totals: await getMetrics(),
  };

  // 1. Auto-distill from recent sessions
  console.log('📚 Step 1: Distilling learnings from sessions...');
  try {
    const distillResult = await loop.autoDistillSessions({ limit: 5 });
    stats.distilled = distillResult.learningsExtracted;
    console.log(`   Extracted ${distillResult.learningsExtracted} learnings from ${distillResult.sessionsProcessed} sessions`);
  } catch (e) {
    console.log(`   Distill error: ${e instanceof Error ? e.message : e}`);
  }

  // 2. Consolidate duplicates (every 3rd iteration)
  if (iteration % 3 === 0) {
    console.log('\n🔄 Step 2: Consolidating duplicates...');
    try {
      const consolidateResult = await runConsolidation({
        dryRun: false,
        minSimilarity: 0.88,
        limit: 10,
      });
      stats.consolidated = consolidateResult.merged;
      console.log(`   Merged ${consolidateResult.merged} duplicates from ${consolidateResult.candidatesFound} candidates`);
    } catch (e) {
      console.log(`   Consolidation error: ${e instanceof Error ? e.message : e}`);
    }
  } else {
    console.log('\n🔄 Step 2: Skipping consolidation (runs every 3rd iteration)');
  }

  // 3. Migrate to dual-collection (every 5th iteration)
  if (iteration % 5 === 0) {
    console.log('\n📦 Step 3: Migrating to dual-collection...');
    try {
      const migrateResult = await runMigration({
        dryRun: false,
        limit: 20,
        minConfidenceToKeep: 'medium',
      });
      stats.migrated.knowledge = migrateResult.toKnowledge;
      stats.migrated.lessons = migrateResult.toLessons;
      console.log(`   Migrated ${migrateResult.toKnowledge} to knowledge, ${migrateResult.toLessons} to lessons`);
    } catch (e) {
      console.log(`   Migration error: ${e instanceof Error ? e.message : e}`);
    }
  } else {
    console.log('\n📦 Step 3: Skipping migration (runs every 5th iteration)');
  }

  // 4. Auto-validate high-value learnings
  console.log('\n✅ Step 4: Validating high-value learnings...');
  try {
    // Find learnings that have been linked multiple times (indicates value)
    const { Database } = await import('bun:sqlite');
    const db = new Database('data/agents.db');

    // Find learnings with multiple links (popular = valuable)
    const popular = db.query(`
      SELECT to_learning_id as id, COUNT(*) as link_count
      FROM learning_links
      GROUP BY to_learning_id
      HAVING link_count >= 2
      ORDER BY link_count DESC
      LIMIT 5
    `).all() as Array<{ id: number; link_count: number }>;

    for (const p of popular) {
      validateLearning(p.id);
      stats.validated++;
    }
    db.close();

    console.log(`   Validated ${stats.validated} frequently-linked learnings`);
  } catch (e) {
    console.log(`   Validation error: ${e instanceof Error ? e.message : e}`);
  }

  // 5. Get final metrics
  stats.totals = await getMetrics();

  // Report
  console.log('\n📊 Iteration Summary:');
  console.log(`   Distilled: ${stats.distilled}`);
  console.log(`   Consolidated: ${stats.consolidated}`);
  console.log(`   Migrated: ${stats.migrated.knowledge} knowledge, ${stats.migrated.lessons} lessons`);
  console.log(`   Validated: ${stats.validated}`);
  console.log(`\n   Totals:`);
  console.log(`     Learnings: ${stats.totals.learnings}`);
  console.log(`     Knowledge: ${stats.totals.knowledge}`);
  console.log(`     Lessons: ${stats.totals.lessons}`);
  console.log(`     Confidence: proven=${stats.totals.byConfidence.proven}, high=${stats.totals.byConfidence.high}, medium=${stats.totals.byConfidence.medium}, low=${stats.totals.byConfidence.low}`);

  return stats;
}

async function main() {
  const maxIterations = parseInt(process.argv[2] || '20');
  const delaySeconds = parseInt(process.argv[3] || '5');

  console.log('╔════════════════════════════════════════════════════════════╗');
  console.log('║           RALPH LEARNING LOOP - EVOLUTION ENGINE           ║');
  console.log('╠════════════════════════════════════════════════════════════╣');
  console.log(`║  Iterations: ${maxIterations.toString().padEnd(45)}║`);
  console.log(`║  Delay: ${delaySeconds}s between iterations${' '.repeat(32)}║`);
  console.log('╚════════════════════════════════════════════════════════════╝');

  // Initialize
  if (!isInitialized()) {
    console.log('\n🔧 Initializing Vector DB...');
    await initVectorDB();
  }

  const startMetrics = await getMetrics();
  console.log('\n📈 Starting Metrics:');
  console.log(`   Learnings: ${startMetrics.learnings}`);
  console.log(`   Knowledge: ${startMetrics.knowledge}`);
  console.log(`   Lessons: ${startMetrics.lessons}`);
  console.log(`   Confidence: proven=${startMetrics.byConfidence.proven}, high=${startMetrics.byConfidence.high}, medium=${startMetrics.byConfidence.medium}, low=${startMetrics.byConfidence.low}`);

  const allStats: IterationStats[] = [];

  for (let i = 1; i <= maxIterations; i++) {
    const stats = await runIteration(i);
    allStats.push(stats);

    if (i < maxIterations) {
      console.log(`\n⏳ Waiting ${delaySeconds}s before next iteration...`);
      await new Promise(resolve => setTimeout(resolve, delaySeconds * 1000));
    }
  }

  // Final summary
  const endMetrics = await getMetrics();

  console.log('\n');
  console.log('╔════════════════════════════════════════════════════════════╗');
  console.log('║                    FINAL SUMMARY                           ║');
  console.log('╚════════════════════════════════════════════════════════════╝');

  console.log('\n📊 Metrics Change:');
  console.log(`   Learnings: ${startMetrics.learnings} → ${endMetrics.learnings} (${endMetrics.learnings - startMetrics.learnings > 0 ? '+' : ''}${endMetrics.learnings - startMetrics.learnings})`);
  console.log(`   Knowledge: ${startMetrics.knowledge} → ${endMetrics.knowledge} (${endMetrics.knowledge - startMetrics.knowledge > 0 ? '+' : ''}${endMetrics.knowledge - startMetrics.knowledge})`);
  console.log(`   Lessons: ${startMetrics.lessons} → ${endMetrics.lessons} (${endMetrics.lessons - startMetrics.lessons > 0 ? '+' : ''}${endMetrics.lessons - startMetrics.lessons})`);

  console.log('\n📈 Confidence Evolution:');
  console.log(`   Proven: ${startMetrics.byConfidence.proven} → ${endMetrics.byConfidence.proven}`);
  console.log(`   High: ${startMetrics.byConfidence.high} → ${endMetrics.byConfidence.high}`);
  console.log(`   Medium: ${startMetrics.byConfidence.medium} → ${endMetrics.byConfidence.medium}`);
  console.log(`   Low: ${startMetrics.byConfidence.low} → ${endMetrics.byConfidence.low}`);

  const totalDistilled = allStats.reduce((sum, s) => sum + s.distilled, 0);
  const totalConsolidated = allStats.reduce((sum, s) => sum + s.consolidated, 0);
  const totalValidated = allStats.reduce((sum, s) => sum + s.validated, 0);

  console.log('\n🎯 Total Actions:');
  console.log(`   Distilled: ${totalDistilled} learnings`);
  console.log(`   Consolidated: ${totalConsolidated} duplicates`);
  console.log(`   Validated: ${totalValidated} learnings`);

  console.log('\n✅ LEARNING_EVOLVED');
}

main().catch(console.error);
