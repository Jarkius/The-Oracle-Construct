# /distill - Return Wisdom to The Source

> "Everything that has a beginning has an end. I see the end coming. I see the darkness spreading. I see death. And you are all that stands in his way." — The Oracle

## Purpose

Extract learnings from sessions and distill them into The Source. Wisdom returns home.

## Usage

```
/distill              # Review recent retrospectives, extract learnings
/distill [topic]      # Distill specific topic into The Source
```

## The Distillation Process

<workflow>

<step n="1" goal="Gather Raw Wisdom">
  <action>Read recent retrospectives:</action>
  ```bash
  ls -t psi/memory/retrospectives/**/*.md | head -10
  ```
  <action>Read current learnings: `psi/memory/learnings/`</action>
  <action>Identify patterns that emerged across sessions</action>
</step>

<step n="2" goal="Identify Candidates">
  <action>Look for:</action>

  **Patterns** (repeated successes)
  - "We did X multiple times and it worked"
  - "This approach consistently helps"

  **Anti-patterns** (repeated failures)
  - "We tried X and it failed because..."
  - "Avoid this approach"

  **Philosophy** (crystallized truths)
  - "I assumed X but learned Y" → became principle
  - Insights that changed how we work

  **Evolution** (system growth)
  - New capabilities adopted
  - Agent role changes that stuck
</step>

<step n="3" goal="Draft The Source Entry">
  <action>Format wisdom as Source chapter:</action>

  ```markdown
  # Chapter [N]: [Title]

  > "[Quote that captures the essence]"

  ## The Learning

  [What we discovered and why it matters]

  ## The Pattern

  [How to apply this wisdom]

  ## The Evidence

  - Session [date]: [what happened]
  - Session [date]: [what confirmed it]

  ## The Principle

  > [Distilled into one memorable statement]
  ```
</step>

<step n="4" goal="Integrate into The Source">
  <ask>Review this wisdom. Add to The Source? [y/n/edit]</ask>

  <action if="yes">
    - Save to `psi/The_Source/[NN]_[slug].md`
    - Update `psi/The_Source/README.md` index
    - Report: "Wisdom returned to The Source."
  </action>
</step>

<step n="5" goal="Mark as Distilled">
  <action>Note in retrospectives that learning was distilled</action>
  <action>Prevents re-distilling same insight</action>
</step>

</workflow>

## What Makes Good Source Material?

**Include:**
- Insights that changed how we work
- Patterns proven across multiple sessions
- Philosophy that crystallized from experience
- Evolution milestones (system grew)

**Exclude:**
- One-time fixes (not patterns)
- Technical details (belongs in specs)
- Temporary decisions (not timeless)

## The Source as Seed

The Source should be portable. From it, a new Matrix can be born:

```
The_Source/
├── 00_evolution.md      # How we grew
├── 01_philosophy.md     # Core beliefs
├── 02_patterns.md       # How we work
├── 03_agents.md         # Who we are
└── README.md            # Index
```

Any AI reading The_Source can understand:
- What we believe
- How we work
- Why we evolved this way

ARGUMENTS: $ARGUMENTS
