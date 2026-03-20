---
description: Multi-source deep research with parallel web searches
---

# /learn:research — Deep Research

> *"Morpheus will navigate." — Oracle*

## Purpose

Conduct deep, multi-source research on any topic using parallel web searches, source cross-referencing, and structured synthesis. More thorough than `/learn:concept` — this is for when you need to REALLY understand something.

## Usage

```
/learn:research <topic>
/learn:research "MQTT vs WebSocket for multi-agent systems"
/learn:research "best practices for browser anti-detection 2026"
/learn:research "React Server Components vs Next.js App Router"
```

## Process

### 1. Research Strategy (Oracle — plan the approach)

Before searching, define:
- **3-5 research questions** to answer
- **Source types** needed (docs, blogs, papers, repos, forums)
- **Comparison axes** if comparing technologies

### 2. Parallel Research (Morpheus — Sonnet, 3-4 agents)

Spawn multiple research agents in parallel:

```
Agent 1: Official documentation + primary sources
Agent 2: Community perspectives (blogs, HN, Reddit, forums)
Agent 3: Code examples + real-world usage (GitHub repos, tutorials)
Agent 4: Benchmarks + comparisons (if applicable)
```

Each agent uses WebSearch + WebFetch to gather information.

### 3. Cross-Reference and Validate

After all agents return:
- **Find consensus** — what do multiple sources agree on?
- **Find conflicts** — where do sources disagree? Why?
- **Find gaps** — what questions remain unanswered?
- **Assess recency** — is this info current or outdated?

### 4. Synthesize

Create research document at `psi/knowledge/active/<topic>-research.md`:

```markdown
# Deep Research: <Topic>

**Date**: YYYY-MM-DD
**Researcher**: Morpheus
**Sources**: N sources consulted
**Confidence**: High/Medium/Low

## Executive Summary
<3-5 sentences: what did we learn?>

## Research Questions
1. Q: <question>
   A: <answer with source citations>

2. Q: <question>
   A: <answer with source citations>

## Key Findings

### Finding 1: <title>
<Explanation with evidence from multiple sources>
**Sources**: [Source A], [Source B]
**Confidence**: High — multiple independent sources agree

### Finding 2: <title>
...

## Comparison Matrix (if applicable)
| Criterion | Option A | Option B | Winner |
|-----------|----------|----------|--------|
| Performance | ... | ... | B |
| Complexity | ... | ... | A |
| Community | ... | ... | B |

## Conflicts
<Where sources disagree and why>

## Open Questions
<What we still don't know>

## Recommendation
<If the research was to inform a decision, what's the verdict?>

## Sources
1. [Title](URL) — relevance, date, credibility
2. [Title](URL) — relevance, date, credibility
...
```

### 5. Persistence

```bash
sh psi/matrix/voice.sh "Research complete. Multiple perspectives synthesized." "Morpheus"

# Ingest into semantic memory
cd lib/matrix-memory-agents && bun memory learn "$PROJECT_ROOT/psi/knowledge/active/<topic>-research.md" 2>/dev/null

# Log event
bash .claude/hooks/pulse-event-writer.sh "learning:new" "Morpheus" "{\"topic\":\"<topic>-research\",\"sources\":N}"
```

### 6. Follow-Up

Suggest:
- `/learn:concept <topic>` — to create a structured learning from the research
- `/learn:flash <topic>` — to create flashcards from key findings
- `/architect` — if research should inform an ADR

## Depth Levels

| Flag | Depth | Time | Sources |
|------|-------|------|---------|
| (default) | Standard | 5 min | 4-8 sources |
| `--deep` | Deep | 10-15 min | 10-15 sources |
| `--quick` | Quick scan | 2 min | 2-3 sources |

## Quality Gates

- [ ] At least 3 independent sources consulted
- [ ] Conflicts between sources acknowledged
- [ ] Recency of information noted
- [ ] Confidence levels assigned to findings
- [ ] Sources are real URLs (not hallucinated)
- [ ] Executive summary is actionable

ARGUMENTS: $ARGUMENTS
