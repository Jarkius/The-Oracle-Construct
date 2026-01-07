# /distill - Return Wisdom to The Source

> *The Oracle - "Everything that has a beginning has an end."*

Extract learnings from sessions and distill them into The Source. Wisdom returns home.

## Usage

```
/distill              # Review recent retrospectives, extract learnings
/distill [topic]      # Distill specific topic into The Source
```

## Process

### Step 1: Gather Raw Wisdom
```bash
ls -t psi/memory/retrospectives/**/*.md | head -10
```
Read current learnings from `psi/memory/learnings/`

### Step 2: Identify Candidates

**Patterns** (repeated successes):
- "We did X multiple times and it worked"

**Anti-patterns** (repeated failures):
- "We tried X and it failed because..."

**Philosophy** (crystallized truths):
- "I assumed X but learned Y" → became principle

**Evolution** (system growth):
- New capabilities adopted

### Step 3: Draft The Source Entry

```markdown
# Chapter [N]: [Title]

> "[Quote that captures the essence]"

## The Learning
[What we discovered and why it matters]

## The Pattern
[How to apply this wisdom]

## The Evidence
- Session [date]: [what happened]

## The Principle
> [Distilled into one memorable statement]
```

### Step 4: Integrate into The Source
- Save to `psi/The_Source/[NN]_[slug].md`
- Update `psi/The_Source/README.md` index

### Step 5: Mark as Distilled
Note in retrospectives that learning was distilled.

## What Makes Good Source Material?

**Include:**
- Insights that changed how we work
- Patterns proven across multiple sessions
- Philosophy that crystallized from experience

**Exclude:**
- One-time fixes (not patterns)
- Technical details (belongs in specs)
- Temporary decisions (not timeless)

ARGUMENTS: $ARGUMENTS
