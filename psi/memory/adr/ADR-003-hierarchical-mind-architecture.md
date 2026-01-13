# ADR-003: Hierarchical Mind Architecture

> "Tank gathers. Oracle interprets. Each mind serves its purpose." - The Oracle

## Status
**Accepted** | 2026-01-13

## Context

The Matrix uses multiple AI models with different capabilities and costs:

| Model | Strength | Cost | Speed |
|-------|----------|------|-------|
| **Opus** | Deep reasoning, synthesis, wisdom | High | Slower |
| **Haiku** | Fast search, mechanical tasks | Low | Fast |

Previously, workflows like `/recap` ran all operations (git commands, file reads, retrospective parsing) in the main Opus context. This wasted expensive tokens on mechanical work that doesn't require deep reasoning.

**Problem**: Using Opus for mechanical gathering is like using a surgeon to fetch bandages.

## Decision

### Implement Tank → Oracle Pattern

Separate **gathering** (mechanical) from **synthesis** (wisdom):

```
        ┌─────────────────────────────────┐
        │         ORACLE (Opus)           │
        │   Wisdom · Synthesis · Voice    │
        │         Token: Expensive        │
        └───────────────┬─────────────────┘
                        │ receives summary
        ┌───────────────┴─────────────────┐
        │          TANK (Haiku)           │
        │   Search · Gather · Summarize   │
        │         Token: Cheap            │
        └─────────────────────────────────┘
```

### Model Assignment by Role

| Agent | Model | Rationale |
|-------|-------|-----------|
| **Oracle** | opus | Wisdom, prophecy, path selection |
| **Architect** | opus | System design, trade-off analysis |
| **Neo** | opus | Code implementation, full context |
| **Trinity** | opus + haiku | Design analysis + parallel search |
| **Smith** | opus | Deep anomaly detection |
| **Scribe** | opus | Retrospective synthesis |
| **Tank/Operator** | haiku | Mechanical search, file reads |
| **Morpheus** | haiku | Parallel external search |
| **context-finder** | haiku | Archive search |
| **recap** | haiku → opus | Gather then synthesize |

### Implementation Pattern

For workflows that need both gathering and synthesis:

```markdown
## Steps

### 1. Voice Greeting (main context)
sh psi/matrix/voice.sh "Acknowledgment..." "Agent"

### 2. Spawn Haiku for Gathering
Task:
  subagent_type: Explore
  model: haiku
  prompt: |
    Gather data:
    1. [command 1]
    2. [command 2]
    3. [file reads]

    Return structured summary (compact markdown or JSON)

### 3. Synthesize in Main Context (Opus)
- Receive Haiku's summary
- Apply wisdom/analysis
- Generate final output
- Voice completion
```

## Consequences

### Positive

- **~85% token savings** on search-heavy operations
- **Cleaner separation** of concerns (gather vs synthesize)
- **Faster execution** for mechanical tasks
- **Consistent pattern** across all workflows

### Negative

- **Slight latency** for Task spawn (~1-2 seconds)
- **Added complexity** in workflow definitions
- **Summary quality** depends on Haiku prompt engineering

### Neutral

- Aligns with existing patterns in `/context-finder`, `/operator`, `/morpheus`
- No change to user-facing behavior (just faster, cheaper)

## Affected Workflows

| Workflow | Change Required |
|----------|-----------------|
| `/recap` | Add Task spawn for gathering |
| Others | Already compliant or don't need gathering |

## References

- ADR-001: Multi-Agent Patterns
- ADR-002: GHQ + Symlink Architecture
- Oracle Keeper: `.claude/agents/oracle-keeper.md`
- Tank Agent: `.claude/agents/tank.md`
