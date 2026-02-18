---
description: Deep-dive into any concept with structured learning output
---

# /learn:concept — Deep Concept Learning

> *"Free your mind." — Morpheus*

## Purpose

Take any concept, technology, framework, or idea and produce a structured deep-dive that saves to the knowledge system. Goes beyond surface understanding to capture WHY it matters, HOW it works, and WHEN to use it.

## Usage

```
/learn:concept <topic or URL>
/learn:concept "React Server Components"
/learn:concept https://github.com/some/repo
/learn:concept "Kubernetes networking"
```

## Process

### 1. Research Phase (Morpheus — Sonnet)

Spawn a research agent to gather information:

```
Task:
  subagent_type: general-purpose
  model: sonnet
  prompt: |
    Research "<topic>" comprehensively. Use WebSearch and WebFetch to gather:

    1. **What is it?** — Definition in one sentence
    2. **Why does it exist?** — Problem it solves, history
    3. **How does it work?** — Core mechanics, architecture
    4. **Key concepts** — 5-7 essential ideas with explanations
    5. **Practical examples** — Code samples or real-world usage
    6. **Trade-offs** — When to use vs alternatives
    7. **Common mistakes** — Gotchas and anti-patterns
    8. **Resources** — Best docs, tutorials, repos

    Return structured markdown with all sections.
```

### 2. Synthesis Phase (Oracle — Opus)

After research returns, synthesize into learning format:

**Create file**: `psi/learn/active/<topic-slug>.md`

```markdown
# Learning: <Topic>

**Date**: YYYY-MM-DD
**Status**: Active
**Source**: <URL or "research">

## TL;DR
<One paragraph summary — what is this and why should I care?>

## Core Concepts
1. **Concept A** — Explanation with example
2. **Concept B** — Explanation with example
...

## How It Works
<Architecture diagram (ASCII) + step-by-step explanation>

## Practical Examples
<Code samples with comments>

## Trade-offs
| Pro | Con |
|-----|-----|
| ... | ... |

## Gotchas
- Common mistake 1 and how to avoid it
- Common mistake 2 and how to avoid it

## Connection to Our Work
<How does this relate to The Matrix, CIS Modernization, or current projects?>

## Quiz (Self-Test)
1. Q: <question about core concept>
   A: ||<hidden answer>||
2. Q: <question about practical usage>
   A: ||<hidden answer>||
3. Q: <question about trade-offs>
   A: ||<hidden answer>||

## Resources
- [Resource 1](url) — why this is worth reading
- [Resource 2](url) — why this is worth reading
```

### 3. Persistence

After creating the learning file:

```bash
# Voice announcement
sh psi/matrix/voice.sh "Concept captured. Ready for review." "Morpheus"

# Ingest into semantic memory (if available)
cd lib/matrix-memory-agents && bun memory learn "$PROJECT_ROOT/psi/learn/active/<topic-slug>.md" 2>/dev/null

# Log event
bash .claude/hooks/pulse-event-writer.sh "learning:new" "Morpheus" "{\"topic\":\"<topic>\"}"
```

### 4. Follow-Up Suggestions

After completing, suggest:
- `/learn:teach <topic>` — to solidify understanding via teaching
- `/learn:flash <topic>` — to create flashcards for retention
- `/learn done <topic>` — when ready to archive and distill

## Quality Gates

- [ ] TL;DR is genuinely useful (not generic)
- [ ] At least 5 core concepts explained
- [ ] At least 2 practical examples with working code
- [ ] Quiz has 3+ questions testing understanding
- [ ] Connection to current work identified (or noted as "general knowledge")

ARGUMENTS: $ARGUMENTS
