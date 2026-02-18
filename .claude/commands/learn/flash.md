---
description: Generate flashcards from a topic or existing learnings
---

# /learn:flash — Flashcard Generator

> *"There is no spoon." — But there are cards.*

## Purpose

Generate spaced-repetition flashcards from any topic, existing learning files, or conversation context. Output as CSV (Anki-importable) or markdown for review.

## Usage

```
/learn:flash <topic>                    # Generate from web research
/learn:flash from <file>                # Generate from existing learning file
/learn:flash from-session               # Generate from current conversation
/learn:flash "React hooks" --count 20   # Specify number of cards
```

## Process

### 1. Gather Source Material

**If topic provided**: Research the topic (use WebSearch/WebFetch for current info).
**If `from <file>`**: Read the specified file from psi/learn/ or psi/memory/.
**If `from-session`**: Use the current conversation context.

### 2. Extract Key Facts

Identify facts that are:
- **Memorable** — discrete, testable pieces of knowledge
- **Useful** — practical, not trivia
- **Connected** — relate to each other or to existing knowledge

### 3. Generate Card Types

| Type | Front | Back | When to Use |
|------|-------|------|-------------|
| **Definition** | What is X? | X is... | New terminology |
| **Comparison** | X vs Y? | X does A, Y does B because... | Similar concepts |
| **Application** | When would you use X? | Use X when... because... | Practical knowledge |
| **Gotcha** | What's the common mistake with X? | People often..., but actually... | Anti-patterns |
| **Code** | What does this code do? `snippet` | It does... because... | Programming concepts |
| **Diagram** | Draw/describe the architecture of X | [description] | System understanding |

### 4. Output Formats

**Markdown (default)**:
```markdown
## Flashcards: <Topic>

**Generated**: YYYY-MM-DD | **Cards**: N | **Source**: <topic/file>

---

### Card 1
**Q**: What is a closure in JavaScript?
**A**: A closure is a function that remembers the variables from its outer scope even after the outer function has returned. It "closes over" those variables.

---

### Card 2
**Q**: When would you use `useMemo` vs `useCallback`?
**A**: `useMemo` memoizes a computed value. `useCallback` memoizes a function reference. Use `useMemo` for expensive calculations, `useCallback` for preventing child re-renders.

---
```

**CSV (Anki-importable)**:
```csv
"What is a closure in JavaScript?","A closure is a function that remembers variables from its outer scope even after the outer function returns."
"When use useMemo vs useCallback?","useMemo: memoize computed value. useCallback: memoize function reference."
```

### 5. Save

Save flashcards to `psi/learn/active/<topic>-flashcards.md` (markdown) or `psi/learn/active/<topic>-flashcards.csv` (CSV).

```bash
sh psi/matrix/voice.sh "Flashcards ready. Time to train." "Morpheus"
bash .claude/hooks/pulse-event-writer.sh "learning:new" "Morpheus" "{\"topic\":\"<topic>-flashcards\",\"cards\":N}"
```

## Card Quality Rules

1. **One fact per card** — never cram multiple concepts
2. **Answer first, then explain** — direct answer, then reasoning
3. **No yes/no questions** — they don't build understanding
4. **Include context** — "In React, ..." not just "What is..."
5. **Minimum 10 cards, maximum 30** per topic (adjustable with --count)
6. **Progressive difficulty** — basic → intermediate → advanced

## Quality Gates

- [ ] Every card tests ONE concept
- [ ] No ambiguous questions
- [ ] Answers are complete but concise
- [ ] Mix of card types (not all definitions)
- [ ] Cards build on each other logically

ARGUMENTS: $ARGUMENTS
