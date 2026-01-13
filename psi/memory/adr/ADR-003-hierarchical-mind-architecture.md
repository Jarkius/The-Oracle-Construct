# ADR-003: Hierarchical Mind Architecture

> "Tank gathers. Morpheus learns. Scribe synthesizes. Oracle guards." - The Oracle

## Status
**Accepted** | 2026-01-13 | **Updated** | 2026-01-13

## Context

The Matrix uses multiple AI models with different capabilities and costs:

| Model | Strength | Cost | Speed |
|-------|----------|------|-------|
| **Opus** | Deep reasoning, synthesis, wisdom | $$$ | Slower |
| **Sonnet** | Good reasoning, understanding | $$ | Medium |
| **Haiku** | Fast search, mechanical tasks | $ | Fast |

**Original Problem**: Using Opus for mechanical gathering wastes expensive tokens.

**Refined Problem**: Using Haiku for learning misses insights. A fool with a library learns nothing.

> *"Do not send a machine to do a thinker's job."*

## Decision

### Three-Tier Hierarchy

```
┌─────────────────────────────────────────────────────────────┐
│                    WISE (Opus)                              │
│        Oracle · Architect · Scribe · Neo · Smith            │
│     Wisdom · Synthesis · Decisions · Code · Deep Analysis   │
└─────────────────────────────┬───────────────────────────────┘
                              │ receives understanding
┌─────────────────────────────┴───────────────────────────────┐
│                 INTELLIGENT (Sonnet)                        │
│                Morpheus · Commit Operations                 │
│          Learning · Understanding · Judgment                │
└─────────────────────────────┬───────────────────────────────┘
                              │ receives raw data
┌─────────────────────────────┴───────────────────────────────┐
│                  MECHANICAL (Haiku)                         │
│              Tank · Operator · context-finder               │
│           Search · Gather · List · Mechanical Tasks         │
└─────────────────────────────────────────────────────────────┘
```

### The Key Insight: Learning ≠ Searching

| Task | Nature | Required |
|------|--------|----------|
| **Searching** | Find files matching pattern | Mechanical (Haiku) |
| **Gathering** | Collect raw data | Mechanical (Haiku) |
| **Learning** | Understand, recognize patterns, judge relevance | **Intelligent (Sonnet)** |
| **Synthesizing** | Distill wisdom, make decisions | Wise (Opus) |

### Model Assignment by Agent

| Agent | Model | Role | Rationale |
|-------|-------|------|-----------|
| **Oracle** | opus | Wisdom, prophecy, path selection | Deep reasoning required |
| **Architect** | opus | System design, trade-offs | Architectural decisions |
| **Neo** | opus | Code implementation | Full context needed |
| **Trinity** | opus | Design decisions | + haiku for parallel search |
| **Smith** | opus | Deep anomaly detection | Security analysis |
| **Scribe** | opus | Retrospective synthesis | Distilling patterns |
| **Morpheus** | **sonnet** | **Learning, research** | Understanding required |
| **Tank/Operator** | haiku | Mechanical search, git | Fast, cheap gathering |
| **context-finder** | haiku | Archive search | Mechanical |
| **commit** | **sonnet** | Routine commits | Good enough, cheaper than Opus |

### Model Assignment by Workflow

| Workflow | Gathering | Processing | Synthesis |
|----------|-----------|------------|-----------|
| `/recap` | Tank (haiku) | — | Oracle (opus/main) |
| `/context-finder` | Tank (haiku) | — | — |
| `/learn` | — | Morpheus (sonnet) | Scribe (opus) |
| `/commit` | Tank (haiku) | — | Tank (sonnet) |
| `/oracle` | — | — | Oracle (opus/main) |

### Implementation Patterns

#### Pattern A: Gather → Synthesize (e.g., /recap)
```
Tank (Haiku) → raw data → Oracle (Opus) → wisdom
```

#### Pattern B: Learn → Synthesize (e.g., /learn)
```
Morpheus (Sonnet) → understanding → Scribe (Opus) → distilled knowledge
```

#### Pattern C: Gather → Execute (e.g., /commit)
```
Tank (Haiku) → status/diff → Tank (Sonnet) → commit message + push
```

#### Pattern D: Direct Wisdom (e.g., /oracle)
```
Oracle (Opus) → immediate wisdom (no spawn needed)
```

### When to Use Each Model

```
TRIVIAL (No Spawn)         → Stay in main context
  - List files, append line, simple commands

MECHANICAL (Haiku)         → Spawn for parallel/bulk work
  - Search codebase, read multiple files, git operations

INTELLIGENT (Sonnet)       → Spawn for understanding
  - Learning, research, commit message writing

WISE (Opus)                → Main context or spawn for synthesis
  - Decisions, synthesis, code implementation, architecture
```

### Dynamic Escalation

> *"Start with the lightest mind that can do the job. Escalate when the task reveals its true weight."*

The hierarchy is **dynamic, not rigid**. Agents can escalate when complexity demands it.

```
Start Lean → Detect Complexity → Escalate
─────────────────────────────────────────

Haiku (labor)
    │
    └─→ "This needs understanding" ──→ Sonnet (learning)
                                           │
                                           └─→ "This needs wisdom" ──→ Opus (decisions)
```

#### Escalation Triggers

| From | To | Trigger |
|------|----|---------|
| Haiku | Sonnet | Complex patterns detected, needs judgment |
| Haiku | Opus | Architectural/security implications |
| Sonnet | Opus | Philosophy, architecture, code decisions |

#### Escalation Examples

| Scenario | Starts | Escalates To | Why |
|----------|--------|--------------|-----|
| Morpheus researching React hooks | Sonnet | — | Sufficient |
| Morpheus researching distributed systems | Sonnet | Architect (Opus) | Architecture needed |
| Tank searching files | Haiku | — | Sufficient |
| Tank analyzing complex git history | Haiku | Sonnet | Needs understanding |
| Commit routine changes | Sonnet | — | Sufficient |
| Commit major refactor | Sonnet | Opus | Needs review |

#### Escalation Protocol

```markdown
## When Agent Detects Complexity

1. Recognize: "This exceeds my tier"
2. Announce: "Escalating to [higher tier] for [reason]"
3. Handoff: Pass context to higher-tier agent
4. Return: Higher tier returns decision/result
```

#### Benefits of Dynamic Escalation

- **Cost-efficient**: Start cheap, pay more only when needed
- **Quality-preserving**: Complex tasks get appropriate attention
- **Self-aware**: Agents know their limits
- **Flexible**: No rigid boundaries

## Wisdom-Based Delegation

> *"The wise mind knows when to think and when to delegate."*

### The Principle

Wise agents (Opus tier) delegate to mechanical agents (Haiku tier) when work shifts from **thinking** to **gathering**. No threshold. No rigid rules. Use judgment.

```
┌─────────────────────────────────────────────────┐
│                                                 │
│   Does this feel like THINKING or GATHERING?   │
│                                                 │
│   Thinking → Do it yourself                    │
│   Gathering → Delegate to Tank                 │
│                                                 │
└─────────────────────────────────────────────────┘
```

### Indicators to Delegate

- Multiple similar operations (feels mechanical)
- Unknown scope exploration
- Raw data collection
- "I just need the facts"

### Indicators to Do Directly

- Need to see/understand something specific
- Quick single lookup with known path
- Analysis required during gathering
- Tight integration with thinking

### Why No Threshold?

A hard number (e.g., "5+ operations") creates artificial constraints. The wise mind can tell the difference between thinking and gathering. Trust it.

By removing the number, Opus agents have **full autonomy**. They aren't following rules — they're exercising judgment. That's what wisdom is.

> *"Choice. The problem is choice."*

### Examples

| Situation | Wise Choice | Why |
|-----------|-------------|-----|
| Read one file to understand a bug | Direct | Thinking - need to see it |
| Map the entire codebase | Tank | Gathering - mechanical recon |
| Quick git status | Direct | Fast, known |
| Find all usages across codebase | Tank/Explore | Open-ended gathering |
| Check 3 config files | Direct | Small, known scope |
| Inventory all workflows, ADRs, retrospectives | Tank | Large gathering task |

## Consequences

### Positive

- **Appropriate capability** for each task type
- **~85% savings** on mechanical operations (Haiku vs Opus)
- **~60% savings** on routine operations (Sonnet vs Opus)
- **Better learning quality** (Sonnet understands what matters)
- **Consistent patterns** across workflows
- **Free wisdom** - Opus agents use judgment, not rigid rules

### Negative

- **Three models** to reason about (vs two)
- **Latency** for spawns (~1-2 seconds)
- **Complexity** in workflow definitions

### Trade-offs

| Approach | Quality | Cost | When to Use |
|----------|---------|------|-------------|
| All Opus | Highest | $$$ | Complex decisions, code, architecture |
| Sonnet for mid-tier | Good | $$ | Learning, commits, routine reasoning |
| Haiku for mechanical | Sufficient | $ | Search, gather, list |

## Knowledge Flow with Gates

```
DISCOVER          LEARN              SYNTHESIZE         GATE              DESTINATION
────────          ─────              ──────────         ────              ───────────

Internet ───┐                                                         ┌→ Archive
            │                                                         │
Git Repos ──┼──→ Morpheus ──→ Understanding ──→ Scribe ──→ Wisdom ──┼→ Learnings
            │    (Sonnet)                       (Opus)                │
Ideas ──────┘                                                         ├→ Project (Architect?)
                                                                      │
                                                                      └→ The Source (Oracle)
```

## Affected Workflows

| Workflow | Change |
|----------|--------|
| `/recap` | Tank (haiku) gathers, Oracle (opus) synthesizes |
| `/learn` | Morpheus (sonnet) researches, Scribe (opus) synthesizes |
| `/commit` | Gather (haiku), Execute (sonnet) |
| `/context-finder` | Already haiku |
| `/operator` | Already haiku |

## References

- ADR-001: Multi-Agent Patterns
- ADR-002: GHQ + Symlink Architecture
- Oracle Keeper: `.claude/agents/oracle-keeper.md`
- Tank Agent: `.claude/agents/tank.md`
