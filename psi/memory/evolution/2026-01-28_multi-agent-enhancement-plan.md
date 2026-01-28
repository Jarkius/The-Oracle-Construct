# Plan: Multi-Agent Enhancement for The Matrix

> *"The One becomes many. Each with purpose, all with wisdom."*

## Overview

Enhance **Agent Orchestra** (matrix-memory-agents) to maximize **capability, efficiency, performance, and intelligence** for The Matrix ecosystem.

### Current State (Completed Integration)
- ✅ PARENT.md established lineage
- ✅ Bidirectional sync (psi/ ↔ SQLite)
- ✅ Voice bridge connected
- ✅ Workflows created (/memory-sync, /orchestra)
- ✅ 92 sessions indexed, 114 learnings captured

### Enhancement Goals
| Goal | Metric | Current | Target |
|------|--------|---------|--------|
| **Speed** | Task routing latency | ~500ms | <100ms |
| **Intelligence** | Routing accuracy | Manual | Auto-optimal |
| **Efficiency** | Agent utilization | Reactive | Predictive |
| **Learning** | Confidence evolution | Manual | Auto-promote |

---

## Phase 1: Oracle Routing Intelligence

### 1.1 Fast Routing Cache

**Problem**: Current routing uses Haiku LLM call (~500ms per decision)
**Solution**: Cache common task→role mappings

**File**: `src/oracle/routing-cache.ts`
```typescript
interface RoutingCache {
  // Pattern → recommended role+model
  patterns: Map<string, { role: string; model: string; confidence: number }>;
  // Cache hit tracking for analytics
  hits: number;
  misses: number;
}

// Pre-populated patterns from historical routing decisions
// NOTE: Sonnet is the floor - no haiku for task execution
const FAST_PATTERNS = {
  'fix bug': { role: 'debugger', model: 'sonnet' },
  'write test': { role: 'tester', model: 'sonnet' },
  'implement feature': { role: 'coder', model: 'sonnet' },
  'review code': { role: 'reviewer', model: 'sonnet' },
  'search for': { role: 'researcher', model: 'sonnet' },  // Sonnet floor
  'find files': { role: 'researcher', model: 'sonnet' },  // Sonnet floor
  'analyze architecture': { role: 'architect', model: 'opus' },
  'security review': { role: 'architect', model: 'opus' },
  'refactor system': { role: 'architect', model: 'opus' },
};
```

### 1.2 Learning-Informed Routing

**File**: `src/oracle/task-router.ts` (enhance existing)

```typescript
// Before routing, check if similar tasks succeeded with specific roles
async function getHistoricalSuccess(taskType: string): Promise<RoleSuccess[]> {
  return db.query(`
    SELECT role, model,
           COUNT(*) as attempts,
           SUM(CASE WHEN status='completed' THEN 1 ELSE 0 END) as successes
    FROM agent_tasks
    WHERE task_type = ? AND created_at > datetime('now', '-7 days')
    GROUP BY role, model
    ORDER BY successes DESC
  `).all(taskType);
}
```

---

## Phase 2: Adaptive Agent Spawning

### 2.1 Predictive Spawning

**Problem**: Reactive spawning waits until queue backs up
**Solution**: Predict demand and pre-spawn

**File**: `src/oracle/predictive-spawner.ts`
```typescript
interface SpawnPrediction {
  shouldSpawn: boolean;
  recommendedRole: string;
  confidence: number;
  reason: string;
}

async function predictSpawnNeed(): Promise<SpawnPrediction> {
  const metrics = {
    queueGrowthRate: getQueueGrowthRate(5), // last 5 minutes
    avgTaskDuration: getAvgTaskDuration(),
    activeAgents: getActiveAgentCount(),
    pendingTasks: getPendingTaskCount(),
  };

  // Spawn if queue will overflow before current tasks complete
  const timeToOverflow = (MAX_QUEUE - metrics.pendingTasks) / metrics.queueGrowthRate;
  const timeToComplete = metrics.pendingTasks * metrics.avgTaskDuration / metrics.activeAgents;

  return {
    shouldSpawn: timeToOverflow < timeToComplete,
    recommendedRole: getMostNeededRole(),
    confidence: 0.8,
    reason: `Queue overflow in ${timeToOverflow}min, completion in ${timeToComplete}min`
  };
}
```

### 2.2 Agent Pool Management

**File**: `src/oracle/agent-pool.ts`
```typescript
interface AgentPoolConfig {
  minAgents: number;        // Always keep this many warm
  maxAgents: number;        // Never exceed
  idleTimeout: number;      // Retire after N minutes idle
  warmupRoles: string[];    // Pre-spawn these roles
}

const DEFAULT_POOL: AgentPoolConfig = {
  minAgents: 2,
  maxAgents: 8,
  idleTimeout: 10,
  warmupRoles: ['coder', 'tester'],
};
```

---

## Phase 3: Learning Confidence Evolution

### 3.1 Auto-Validation System

**Problem**: Learnings stay at 'medium' confidence forever
**Solution**: Track usage and auto-promote

**File**: `src/learning/auto-validator.ts`
```typescript
interface ValidationTriggers {
  // Promote to 'high' when:
  usageCount: number;           // Used in N successful tasks
  crossAgentValidation: number; // Validated by N different agents
  timeSinceCreation: number;    // Survived N days without contradiction
}

async function checkPromotionCandidates(): Promise<LearningRecord[]> {
  return db.query(`
    SELECT l.*,
           COUNT(DISTINCT t.agent_id) as agent_validations,
           COUNT(t.id) as usage_count
    FROM learnings l
    LEFT JOIN agent_tasks t ON t.learnings_used LIKE '%' || l.id || '%'
    WHERE l.confidence = 'medium'
      AND l.created_at < datetime('now', '-3 days')
    GROUP BY l.id
    HAVING usage_count >= 3 OR agent_validations >= 2
  `).all();
}
```

### 3.2 Confidence Decay

**File**: `src/learning/confidence-decay.ts`
```typescript
// Decay stale learnings that haven't been validated
async function applyConfidenceDecay(): Promise<number> {
  const decayed = db.run(`
    UPDATE learnings
    SET confidence = CASE
      WHEN confidence = 'proven' THEN 'high'
      WHEN confidence = 'high' THEN 'medium'
      ELSE 'low'
    END,
    updated_at = datetime('now')
    WHERE last_validated_at < datetime('now', '-30 days')
      AND confidence != 'low'
  `);
  return decayed.changes;
}
```

---

## Phase 4: Task Parallelization

### 4.1 Dependency Graph Analysis

**File**: `src/oracle/task-decomposer.ts` (enhance existing)
```typescript
interface TaskGraph {
  nodes: Map<string, SubTask>;
  edges: Map<string, string[]>;  // task → dependencies
  criticalPath: string[];        // longest chain
  parallelizable: string[][];    // groups that can run together
}

function analyzeParallelism(subtasks: SubTask[]): TaskGraph {
  // Build dependency graph
  // Identify independent tasks that can run in parallel
  // Calculate critical path for scheduling
}
```

### 4.2 Parallel Execution Strategy

```typescript
// Instead of sequential:
// task1 → task2 → task3 → task4

// Execute in parallel waves:
// Wave 1: [task1, task2] (independent)
// Wave 2: [task3] (depends on task1)
// Wave 3: [task4] (depends on task2, task3)
```

---

## Phase 5: Cross-Matrix Learning Sync

### 5.1 Learning Propagation

**Problem**: Each matrix instance learns independently
**Solution**: Sync high-confidence learnings via Matrix Hub

**File**: `src/matrix/learning-sync.ts`
```typescript
interface LearningSyncMessage {
  type: 'learning_broadcast';
  learning: LearningRecord;
  sourceMatrix: string;
  confidence: number;
}

async function broadcastProvenLearning(learning: LearningRecord) {
  if (learning.confidence === 'proven') {
    await matrixHub.broadcast({
      type: 'learning_broadcast',
      learning,
      sourceMatrix: getMatrixId(),
      confidence: learning.times_validated || 1,
    });
  }
}
```

### 5.2 Conflict Resolution

```typescript
// When receiving learning from another matrix:
async function handleIncomingLearning(msg: LearningSyncMessage) {
  const existing = findSimilarLearning(msg.learning);

  if (!existing) {
    // New learning - import with lower confidence
    createLearning({ ...msg.learning, confidence: 'medium' });
  } else if (msg.confidence > existing.times_validated) {
    // External has more validation - consider merging
    mergeLearnings(existing, msg.learning);
  }
  // Otherwise keep local version
}
```

---

## Phase 6: Performance Optimizations

### 6.1 Embedding Cache

**Problem**: Re-embedding same queries wastes compute
**Solution**: LRU cache for embeddings

**File**: `src/vector-db.ts` (enhance)
```typescript
const embeddingCache = new LRUCache<string, number[]>({
  max: 1000,
  ttl: 1000 * 60 * 60, // 1 hour
});

async function getEmbedding(text: string): Promise<number[]> {
  const cached = embeddingCache.get(text);
  if (cached) return cached;

  const embedding = await computeEmbedding(text);
  embeddingCache.set(text, embedding);
  return embedding;
}
```

### 6.2 Batch Operations

```typescript
// Instead of individual inserts:
for (const learning of learnings) {
  await saveLearning(learning);  // N database calls
}

// Batch insert:
await saveLearningsBatch(learnings);  // 1 database call
```

### 6.3 Connection Pooling

```typescript
// ChromaDB connection reuse
const chromaPool = {
  connections: [],
  maxSize: 5,
  async acquire() { /* reuse or create */ },
  release(conn) { /* return to pool */ },
};
```

---

## Phase 7: Model Selection Intelligence

### 7.1 Quality Floor: Sonnet as Minimum

**Rationale**: Haiku is fast but often produces shallow results. Using Sonnet as the floor ensures consistent quality while Opus handles complex reasoning.

**File**: `src/oracle/model-config.ts`
```typescript
interface ModelConfig {
  floorModel: 'haiku' | 'sonnet';  // Minimum model for any task
  ceilingModel: 'sonnet' | 'opus'; // Maximum model for cost control
  autoEscalate: boolean;           // Escalate on failure
}

const MODEL_CONFIGS = {
  // Quality-first (recommended for The Matrix)
  quality: {
    floorModel: 'sonnet',   // Never use haiku for real tasks
    ceilingModel: 'opus',
    autoEscalate: true,
  },
  // Cost-optimized (for high-volume simple tasks)
  budget: {
    floorModel: 'haiku',
    ceilingModel: 'sonnet',
    autoEscalate: false,
  },
  // Balanced
  balanced: {
    floorModel: 'sonnet',
    ceilingModel: 'sonnet',  // Cap at sonnet, no opus
    autoEscalate: true,
  },
};

// Default: Quality-first for Matrix operations
const DEFAULT_CONFIG = MODEL_CONFIGS.quality;
```

### 7.2 Updated Mind Hierarchy

```
┌─────────────────────────────────────────────────┐
│         ARCHITECT/STRATEGIST (Opus)             │
│   Oracle · Architect · Final Reviewer           │
│   High-level planning, complex reasoning,       │
│   system design, security, final code reviews   │
├─────────────────────────────────────────────────┤
│         RELIABLE IMPLEMENTER (Sonnet)           │
│   Neo · Coder · Tester · Debugger               │
│   Boilerplate, modules, CRUD, tests,            │
│   commit messages, straightforward coding       │
├─────────────────────────────────────────────────┤
│         FAST COORDINATOR/SCANNER (Haiku)        │
│   Tank · Operator · Pre-flight Scanner          │
│   Parallel checks, file scanning, log analysis, │
│   find-and-replace, codebase indexing           │
│   ⚠️  LATENCY-CRITICAL tasks only               │
└─────────────────────────────────────────────────┘
```

### 7.3 When to Use Each Model

| Model | Role | Use For | Never For |
|-------|------|---------|-----------|
| **Opus** | Architect/Strategist | Planning, complex reasoning, system design, final reviews, security analysis | Simple CRUD, boilerplate |
| **Sonnet** | Implementer | Code generation, tests, modules, CRUD, commit messages, documentation | Complex architecture decisions |
| **Haiku** | Coordinator/Scanner | Parallel log scanning, file indexing, find-replace, pre-flight checks | Implementation, code generation |

### 7.4 Workflow Pattern: Haiku → Opus → Sonnet

```
1. HAIKU scans codebase rapidly (load file references)
         ↓
2. OPUS analyzes and plans (architecture, strategy)
         ↓
3. SONNET implements (code, tests, modules)
         ↓
4. OPUS reviews final result (quality gate)
```

### 7.5 Task Type → Model Mapping

```typescript
const TASK_MODEL_MAP = {
  // Haiku: Fast coordination (latency-critical)
  'scan_codebase': 'haiku',
  'index_files': 'haiku',
  'parallel_log_check': 'haiku',
  'find_and_replace': 'haiku',
  'pre_flight_scan': 'haiku',
  'routing_decision': 'haiku',

  // Sonnet: Reliable implementation
  'implement_feature': 'sonnet',
  'write_tests': 'sonnet',
  'fix_bug': 'sonnet',
  'generate_boilerplate': 'sonnet',
  'write_documentation': 'sonnet',
  'crud_operations': 'sonnet',
  'commit_message': 'sonnet',

  // Opus: Strategy and quality
  'system_design': 'opus',
  'architecture_review': 'opus',
  'security_analysis': 'opus',
  'complex_refactor': 'opus',
  'final_code_review': 'opus',
  'strategic_planning': 'opus',
};
```

### 7.4 Configuration in .matrix.json

```json
{
  "model_config": {
    "floor": "sonnet",
    "ceiling": "opus",
    "auto_escalate": true,
    "haiku_allowed_for": ["routing", "classification"]
  }
}
```

### 7.5 Retry Escalation (Sonnet → Opus only)

```typescript
// Start with sonnet floor, escalate to opus on failure
async function executeWithEscalation(task: Task): Promise<Result> {
  const config = getModelConfig();
  const models = [config.floorModel, config.ceilingModel].filter(unique);

  for (const model of models) {
    const result = await execute(task, model);
    if (result.success) return result;

    // Log escalation for learning
    logEscalation(task, model, result.error);
  }
  throw new Error('All models failed');
}
```

---

## Implementation Priority

| Phase | Impact | Effort | Priority |
|-------|--------|--------|----------|
| 1. Routing Cache | High | Low | 🔴 P0 |
| 6. Embedding Cache | High | Low | 🔴 P0 |
| 3. Auto-Validation | High | Medium | 🟡 P1 |
| 2. Predictive Spawning | Medium | Medium | 🟡 P1 |
| 7. Cost-Aware Routing | Medium | Low | 🟡 P1 |
| 4. Task Parallelization | High | High | 🟢 P2 |
| 5. Cross-Matrix Sync | Medium | High | 🟢 P2 |

---

## Key Files to Modify

| File | Change | Phase |
|------|--------|-------|
| `src/oracle/routing-cache.ts` | **Create** - Fast pattern matching | 1 |
| `src/oracle/task-router.ts` | **Enhance** - Learning-informed routing | 1 |
| `src/oracle/predictive-spawner.ts` | **Create** - Demand prediction | 2 |
| `src/oracle/agent-pool.ts` | **Create** - Pool management | 2 |
| `src/learning/auto-validator.ts` | **Create** - Confidence evolution | 3 |
| `src/oracle/task-decomposer.ts` | **Enhance** - Parallel analysis | 4 |
| `src/matrix/learning-sync.ts` | **Create** - Cross-matrix sync | 5 |
| `src/vector-db.ts` | **Enhance** - Embedding cache | 6 |
| `src/oracle/cost-router.ts` | **Create** - Cost-aware selection | 7 |

---

## Verification & Testing

### Phase 0: Baseline Metrics (Before Enhancements)

```bash
# Capture current performance baseline
bun run scripts/tests/baseline-metrics.ts

# Expected baseline:
# - Routing latency: ~500ms
# - Cache hit rate: 0%
# - Learning promotion: manual only
# - Spawn trigger: reactive (queue > 5)
```

### Test Suite: Phase 1 - Routing Cache

**File**: `scripts/tests/routing-cache.test.ts`
```typescript
describe('Routing Cache', () => {
  test('cache hit returns in <100ms', async () => {
    // Warm cache with known pattern
    await routeTask({ type: 'fix bug', description: 'fix login' });

    // Second call should hit cache
    const start = performance.now();
    const result = await routeTask({ type: 'fix bug', description: 'fix logout' });
    const elapsed = performance.now() - start;

    expect(elapsed).toBeLessThan(100);
    expect(result.cacheHit).toBe(true);
  });

  test('cache miss falls back to LLM routing', async () => {
    const result = await routeTask({ type: 'novel_task', description: 'unusual request' });
    expect(result.cacheHit).toBe(false);
    expect(result.role).toBeDefined();
  });

  test('historical success influences routing', async () => {
    // Simulate 5 successful debug tasks with 'smith' role
    await simulateSuccessfulTasks('debug', 'smith', 5);

    // New debug task should prefer 'smith'
    const result = await routeTask({ type: 'debug', description: 'investigate crash' });
    expect(result.role).toBe('smith');
  });
});
```

### Test Suite: Phase 2 - Predictive Spawning

**File**: `scripts/tests/predictive-spawning.test.ts`
```typescript
describe('Predictive Spawning', () => {
  test('triggers spawn before queue overflow', async () => {
    // Set up: 1 agent, 5 pending tasks
    const pool = createTestPool({ agents: 1, pendingTasks: 5 });

    // Simulate rapid task arrival (10 tasks/min)
    await simulateTaskArrival(pool, { rate: 10, duration: 30 });

    // Should have spawned additional agent proactively
    expect(pool.getAgentCount()).toBeGreaterThan(1);
    expect(pool.getSpawnReason()).toContain('predictive');
  });

  test('maintains minimum warm agents', async () => {
    const pool = createTestPool({ minAgents: 2 });

    // Let agents idle for 15 minutes
    await advanceTime(15 * 60 * 1000);

    // Should still have minimum agents
    expect(pool.getAgentCount()).toBeGreaterThanOrEqual(2);
  });

  test('retires idle agents after timeout', async () => {
    const pool = createTestPool({ minAgents: 2, maxAgents: 5, idleTimeout: 10 });

    // Spawn 5 agents, complete all tasks
    await pool.spawnAgents(5);
    await pool.completeAllTasks();

    // Wait for idle timeout
    await advanceTime(11 * 60 * 1000);

    // Should have retired to minimum
    expect(pool.getAgentCount()).toBe(2);
  });
});
```

### Test Suite: Phase 3 - Learning Confidence Evolution

**File**: `scripts/tests/auto-validation.test.ts`
```typescript
describe('Learning Auto-Validation', () => {
  test('promotes learning after 3 successful uses', async () => {
    // Create learning at medium confidence
    const learningId = await createLearning({
      title: 'Test pattern',
      confidence: 'medium',
    });

    // Use learning in 3 successful tasks
    for (let i = 0; i < 3; i++) {
      await completeTaskWithLearning(learningId);
    }

    // Run auto-validation
    await checkPromotionCandidates();

    // Should be promoted to 'high'
    const learning = await getLearning(learningId);
    expect(learning.confidence).toBe('high');
  });

  test('decays stale learnings after 30 days', async () => {
    const learningId = await createLearning({
      title: 'Old pattern',
      confidence: 'high',
      last_validated_at: '2025-12-01',  // 60 days ago
    });

    await applyConfidenceDecay();

    const learning = await getLearning(learningId);
    expect(learning.confidence).toBe('medium');
  });

  test('cross-agent validation promotes faster', async () => {
    const learningId = await createLearning({
      title: 'Cross-validated pattern',
      confidence: 'medium',
    });

    // Use by 2 different agents (even just once each)
    await completeTaskWithLearning(learningId, { agentId: 1 });
    await completeTaskWithLearning(learningId, { agentId: 2 });

    await checkPromotionCandidates();

    const learning = await getLearning(learningId);
    expect(learning.confidence).toBe('high');
  });
});
```

### Test Suite: Phase 4 - Task Parallelization

**File**: `scripts/tests/task-parallelization.test.ts`
```typescript
describe('Task Parallelization', () => {
  test('identifies independent tasks for parallel execution', () => {
    const subtasks = [
      { id: 'A', depends: [] },
      { id: 'B', depends: [] },
      { id: 'C', depends: ['A'] },
      { id: 'D', depends: ['B', 'C'] },
    ];

    const graph = analyzeParallelism(subtasks);

    expect(graph.parallelizable).toEqual([
      ['A', 'B'],  // Wave 1
      ['C'],       // Wave 2
      ['D'],       // Wave 3
    ]);
  });

  test('calculates critical path correctly', () => {
    const subtasks = [
      { id: 'A', depends: [], estimate: 5 },
      { id: 'B', depends: [], estimate: 3 },
      { id: 'C', depends: ['A'], estimate: 2 },
      { id: 'D', depends: ['B', 'C'], estimate: 4 },
    ];

    const graph = analyzeParallelism(subtasks);

    // Critical path: A(5) → C(2) → D(4) = 11
    // Not: B(3) → D(4) = 7
    expect(graph.criticalPath).toEqual(['A', 'C', 'D']);
    expect(graph.estimatedDuration).toBe(11);
  });
});
```

### Test Suite: Phase 7 - Model Selection

**File**: `scripts/tests/model-selection.test.ts`
```typescript
describe('Model Selection', () => {
  test('uses sonnet floor for implementation tasks', async () => {
    const tasks = [
      { type: 'implement_feature', description: 'add login' },
      { type: 'write_tests', description: 'test auth' },
      { type: 'fix_bug', description: 'fix crash' },
    ];

    for (const task of tasks) {
      const result = await selectModel(task);
      expect(result.model).toBe('sonnet');
    }
  });

  test('uses haiku only for coordination tasks', async () => {
    const tasks = [
      { type: 'scan_codebase', description: 'find all files' },
      { type: 'routing_decision', description: 'route task' },
      { type: 'pre_flight_scan', description: 'check files' },
    ];

    for (const task of tasks) {
      const result = await selectModel(task);
      expect(result.model).toBe('haiku');
    }
  });

  test('uses opus for architecture tasks', async () => {
    const tasks = [
      { type: 'system_design', description: 'design auth system' },
      { type: 'security_analysis', description: 'audit permissions' },
      { type: 'final_code_review', description: 'review PR' },
    ];

    for (const task of tasks) {
      const result = await selectModel(task);
      expect(result.model).toBe('opus');
    }
  });

  test('escalates sonnet → opus on failure', async () => {
    // Mock sonnet failure
    mockModelResponse('sonnet', { success: false, error: 'too complex' });
    mockModelResponse('opus', { success: true });

    const result = await executeWithEscalation({ type: 'complex_task' });

    expect(result.success).toBe(true);
    expect(result.escalations).toEqual(['sonnet → opus']);
  });

  test('workflow pattern: haiku → opus → sonnet → opus', async () => {
    const complexTask = { description: 'refactor auth system' };

    // Track model usage through workflow
    const workflow = await executeWorkflow(complexTask);

    expect(workflow.phases).toEqual([
      { phase: 'scan', model: 'haiku' },
      { phase: 'plan', model: 'opus' },
      { phase: 'implement', model: 'sonnet' },
      { phase: 'review', model: 'opus' },
    ]);
  });
});
```

### Integration Test: Full Workflow

**File**: `scripts/tests/integration.test.ts`
```typescript
describe('Full Multi-Agent Workflow', () => {
  test('end-to-end task execution with enhancements', async () => {
    // 1. Submit complex task
    const taskId = await submitTask('Implement user authentication with JWT');

    // 2. Verify routing cache was consulted
    expect(getRoutingMetrics().cacheChecked).toBe(true);

    // 3. Verify predictive spawning considered
    expect(getSpawnMetrics().predictiveEvaluated).toBe(true);

    // 4. Wait for completion
    await waitForTaskCompletion(taskId, { timeout: 60000 });

    // 5. Verify learning was captured
    const learnings = await getLearningsForTask(taskId);
    expect(learnings.length).toBeGreaterThan(0);

    // 6. Verify model selection followed hierarchy
    const taskLog = await getTaskLog(taskId);
    expect(taskLog.models).not.toContain('haiku'); // haiku not for implementation
  });
});
```

### Safeguards: Direction Validation Tests

**Critical**: These tests ensure enhancements don't break existing functionality or introduce wrong directions.

**File**: `scripts/tests/safeguards.test.ts`
```typescript
describe('Safeguards: No Regression', () => {
  // CRITICAL: Existing functionality must not break

  test('existing recall still works', async () => {
    const result = await recall('voice system');
    expect(result.sessions.length).toBeGreaterThan(0);
    expect(result.error).toBeUndefined();
  });

  test('existing sync still works', async () => {
    const result = await syncFromPsi({ dryRun: true });
    expect(result.error).toBeUndefined();
  });

  test('existing learning creation still works', async () => {
    const id = await createLearning({
      category: 'testing',
      title: 'Safeguard test',
      confidence: 'medium',
    });
    expect(id).toBeGreaterThan(0);
    // Cleanup
    await deleteLearning(id);
  });

  test('voice bridge still works', async () => {
    const result = await execVoiceBridge('Test message', 'Tank');
    expect(result.exitCode).toBe(0);
  });
});

describe('Safeguards: Philosophy Alignment', () => {
  // CRITICAL: Enhancements must align with Matrix philosophy

  test('mind hierarchy is respected', async () => {
    // Opus tasks should not be routed to haiku
    const opusTask = { type: 'system_design', description: 'design auth' };
    const result = await routeTask(opusTask);
    expect(result.model).not.toBe('haiku');
  });

  test('haiku is never used for implementation', async () => {
    const implTasks = [
      { type: 'implement_feature' },
      { type: 'write_tests' },
      { type: 'fix_bug' },
    ];

    for (const task of implTasks) {
      const result = await routeTask(task);
      expect(result.model).not.toBe('haiku');
    }
  });

  test('learning confidence only increases with validation', async () => {
    const id = await createLearning({ confidence: 'medium' });

    // Without validation, confidence should not change
    await checkPromotionCandidates();
    const learning = await getLearning(id);
    expect(learning.confidence).toBe('medium');
  });

  test('proven learnings are never auto-demoted', async () => {
    const id = await createLearning({
      confidence: 'proven',
      times_validated: 10,
    });

    // Even if stale, proven = human-validated = protected
    await applyConfidenceDecay();
    const learning = await getLearning(id);
    expect(learning.confidence).toBe('proven');  // Never demote proven
  });
});

describe('Safeguards: Performance Boundaries', () => {
  // CRITICAL: Enhancements must not degrade performance

  test('routing with cache is faster than without', async () => {
    // Warm cache
    await routeTask({ type: 'fix bug' });

    // Measure cached routing
    const cachedStart = performance.now();
    await routeTask({ type: 'fix bug' });
    const cachedTime = performance.now() - cachedStart;

    // Cache hit should be faster
    expect(cachedTime).toBeLessThan(200); // Hard limit
  });

  test('spawn prediction does not block task queue', async () => {
    const start = performance.now();
    await submitTask('Simple task');
    const submitTime = performance.now() - start;

    // Prediction should be async, not blocking
    expect(submitTime).toBeLessThan(100);
  });

  test('embedding cache reduces compute', async () => {
    const query = 'test query for embedding';

    // First call - compute
    const t1Start = performance.now();
    await getEmbedding(query);
    const t1 = performance.now() - t1Start;

    // Second call - cached
    const t2Start = performance.now();
    await getEmbedding(query);
    const t2 = performance.now() - t2Start;

    expect(t2).toBeLessThan(t1 / 5); // 5x faster from cache
  });
});

describe('Safeguards: Data Integrity', () => {
  // CRITICAL: Enhancements must not corrupt data

  test('learning sync does not duplicate', async () => {
    const before = await getLearningCount();
    await syncFromPsi();
    await syncFromPsi(); // Run twice
    const after = await getLearningCount();

    // Should not create duplicates
    expect(after).toBe(before);
  });

  test('auto-validation does not create phantom learnings', async () => {
    const before = await getLearningCount();
    await checkPromotionCandidates();
    const after = await getLearningCount();

    expect(after).toBe(before); // No new learnings created
  });

  test('confidence decay is reversible', async () => {
    const id = await createLearning({ confidence: 'high' });
    await applyConfidenceDecay(); // Decays to medium

    // Validate it
    await validateLearning(id);
    await validateLearning(id);
    await validateLearning(id);
    await checkPromotionCandidates();

    const learning = await getLearning(id);
    expect(learning.confidence).toBe('high'); // Restored
  });
});

describe('Safeguards: Rollback Capability', () => {
  // CRITICAL: Must be able to rollback if enhancement fails

  test('can disable routing cache', async () => {
    setConfig({ routingCache: false });
    const result = await routeTask({ type: 'fix bug' });
    expect(result.cacheHit).toBe(false);
    expect(result.role).toBeDefined(); // Still routes via LLM
  });

  test('can disable predictive spawning', async () => {
    setConfig({ predictiveSpawning: false });
    const pool = createTestPool({ pendingTasks: 10 });

    // Should not spawn predictively
    expect(pool.getSpawnReason()).not.toContain('predictive');
  });

  test('can force specific model', async () => {
    setConfig({ forceModel: 'sonnet' });
    const result = await selectModel({ type: 'system_design' });
    expect(result.model).toBe('sonnet'); // Overrides opus
  });
});
```

### Pre-Implementation Checklist

Before implementing each phase, verify:

- [ ] Existing tests pass (`bun test`)
- [ ] Baseline metrics captured
- [ ] Rollback mechanism defined
- [ ] Feature flag added (disabled by default)
- [ ] Safeguard tests written

### Post-Implementation Checklist

After implementing each phase, verify:

- [ ] All existing tests still pass
- [ ] New feature tests pass
- [ ] Safeguard tests pass
- [ ] Performance not degraded
- [ ] Feature flag works (enable/disable)
- [ ] Documentation updated

### Running Tests

```bash
# Run all enhancement tests
bun test scripts/tests/*.test.ts

# Run specific phase tests
bun test scripts/tests/routing-cache.test.ts
bun test scripts/tests/model-selection.test.ts

# CRITICAL: Run safeguard tests before AND after changes
bun test scripts/tests/safeguards.test.ts

# Run with coverage
bun test --coverage scripts/tests/

# Run benchmark comparison (before/after)
bun run scripts/tests/benchmark-comparison.ts
```

### Feature Flags (Gradual Rollout)

```typescript
// config/features.ts
export const FEATURES = {
  routingCache: false,        // Phase 1
  predictiveSpawning: false,  // Phase 2
  autoValidation: false,      // Phase 3
  taskParallelization: false, // Phase 4
  crossMatrixSync: false,     // Phase 5
  embeddingCache: false,      // Phase 6
  modelHierarchy: false,      // Phase 7
};

// Enable one at a time, test thoroughly
```

### Expected Results After Enhancement

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| Routing latency (cache hit) | 500ms | <100ms | 5x faster |
| Routing latency (cache miss) | 500ms | 500ms | Same |
| Cache hit rate | 0% | >60% | New capability |
| Spawn trigger | Reactive | Predictive | Proactive |
| Learning promotion | Manual | Auto | Automated |
| Model selection accuracy | Basic | Learning-informed | Adaptive |
| Regression tests | N/A | 100% pass | Safeguarded |

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                    ENHANCED AGENT ORCHESTRA                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                    ORACLE (Enhanced)                         │    │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │    │
│  │  │ Routing      │  │ Predictive   │  │ Cost-Aware   │       │    │
│  │  │ Cache        │  │ Spawner      │  │ Router       │       │    │
│  │  │ (<100ms)     │  │ (Proactive)  │  │ (Budget)     │       │    │
│  │  └──────────────┘  └──────────────┘  └──────────────┘       │    │
│  │                          │                                   │    │
│  │                    ┌─────▼─────┐                             │    │
│  │                    │ Task      │                             │    │
│  │                    │ Decomposer│ → Parallel Waves            │    │
│  │                    └───────────┘                             │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                                │                                     │
│           ┌────────────────────┼────────────────────┐               │
│           ▼                    ▼                    ▼               │
│     ┌──────────┐        ┌──────────┐        ┌──────────┐           │
│     │ Agent 1  │        │ Agent 2  │        │ Agent N  │           │
│     │ (coder)  │        │ (tester) │        │ (...)    │           │
│     └──────────┘        └──────────┘        └──────────┘           │
│           │                    │                    │               │
│           └────────────────────┼────────────────────┘               │
│                                ▼                                     │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                    LEARNING LOOP                             │    │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │    │
│  │  │ Auto         │  │ Confidence   │  │ Cross-Matrix │       │    │
│  │  │ Validator    │  │ Decay        │  │ Sync         │       │    │
│  │  │ (Promote)    │  │ (Demote)     │  │ (Broadcast)  │       │    │
│  │  └──────────────┘  └──────────────┘  └──────────────┘       │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                                │                                     │
│                    ┌───────────┴───────────┐                        │
│                    ▼                       ▼                        │
│              SQLite + ChromaDB        psi/ Files                    │
│              (Operational)            (Philosophical)               │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Summary

This plan enhances Agent Orchestra with:

1. **Speed**: Routing cache reduces decision latency from 500ms → <100ms
2. **Intelligence**: Learning-informed routing improves accuracy over time
3. **Efficiency**: Predictive spawning prevents queue bottlenecks
4. **Learning**: Auto-validation promotes proven knowledge automatically
5. **Parallelism**: Task decomposition maximizes concurrent execution
6. **Scalability**: Cross-matrix sync shares learnings across instances
7. **Cost**: Budget-aware model selection optimizes spend

**Result**: The Matrix gains a self-optimizing multi-agent system that gets faster, smarter, and more efficient with every task.
