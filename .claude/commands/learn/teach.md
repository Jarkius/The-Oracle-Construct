---
description: Explain anything using the Feynman technique (ELI5 + analogies + diagrams)
---

# /learn:teach — Feynman Technique Explanations

> *"I know Kung Fu." — Neo. "Show me." — Morpheus*

## Purpose

Explain any concept using the **Feynman Technique**: if you can't explain it simply, you don't understand it well enough. Produces explanations that build understanding from ground zero.

## Usage

```
/learn:teach <topic>
/learn:teach "how DNS works"
/learn:teach "React hooks"
/learn:teach "database indexing"
```

## The Feynman Method

### Step 1: Identify the Concept

State what we're explaining in one line.

### Step 2: Explain Like I'm 5 (ELI5)

Write the explanation as if teaching a child. No jargon, no assumptions.

### Step 3: Find the Analogy

Connect the concept to something from everyday life:
- Technical → Physical (e.g., "DNS is like a phone book for the internet")
- Abstract → Concrete (e.g., "A promise is like ordering food — you get a receipt now, food later")
- Complex → Simple (e.g., "A database index is like a book's table of contents")

### Step 4: Draw It

Create an ASCII art diagram showing the concept:

```
┌──────────┐    request    ┌──────────┐    lookup    ┌──────────┐
│  Browser │ ──────────── │   DNS    │ ──────────── │  Server  │
│          │ ◄──────────── │ Resolver │ ◄──────────── │  IP DB   │
└──────────┘   IP address  └──────────┘   response   └──────────┘
```

### Step 5: Walk Through Step by Step

Numbered steps showing what happens in order. Each step is one sentence.

### Step 6: The Gotcha

What's the thing most people get wrong about this? What's the common misconception?

### Step 7: Practice Problem

Give a concrete question or mini-exercise to test understanding.

## Output Format

```markdown
# Teach Me: <Topic>

## The One-Liner
<What is this in one sentence?>

## ELI5 (Explain Like I'm 5)
<Simple explanation with no jargon>

## The Analogy
<Connect to everyday experience>

## The Diagram
<ASCII art showing the concept>

## Step by Step
1. First, ...
2. Then, ...
3. Next, ...
4. Finally, ...

## The Gotcha
<What most people get wrong>

## Try This
<Practice problem or thought experiment>

## Go Deeper
<One resource if they want to learn more>
```

## Behavior

1. **Search first**: If the topic exists in `psi/learn/active/` or `psi/memory/learnings/`, read it to inform the explanation.
2. **Adapt level**: If the user says "advanced" or "deep", skip ELI5 and go straight to technical depth.
3. **Voice**: Announce completion:
   ```bash
   sh psi/matrix/voice.sh "Knowledge transferred. The path is clear." "Morpheus"
   ```
4. **No saving by default**: This is an in-session explanation. If the user wants to save, suggest `/learn:concept` or `/snapshot`.

## Quality Gates

- [ ] Analogy actually maps correctly (not forced)
- [ ] Diagram adds understanding (not decoration)
- [ ] Gotcha is genuine (not obvious)
- [ ] Practice problem is solvable with just the explanation

ARGUMENTS: $ARGUMENTS
