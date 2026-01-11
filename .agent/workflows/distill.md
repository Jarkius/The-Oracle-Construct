---
description: Extract wisdom from retrospectives into portable seed file
---

# /distill - Return Wisdom to The Source

> *"Distill the essence, carry only what matters."*

## Purpose

Extract lessons learned from retrospectives and create a portable **seed file** that can be imported into a new Matrix generation.

## Usage

```
/distill                    # Distill current project wisdom
/distill [project-name]     # Name the seed file
```

## Voice Greeting
```bash
sh psi/matrix/voice.sh "Distilling wisdom. Extracting patterns from experience." "Scribe"
```

## The Protocol

### Step 1: Scan Retrospectives

```bash
# Find all retrospectives
find psi/memory/retrospectives -name "*.md" -type f
```

### Step 2: Extract Key Sections

From each retrospective, extract:
- **AI Diary** entries (lessons learned)
- **Key Decisions** (what was decided and why)
- **Honest Feedback** (what frustrated/delighted)

### Step 3: Identify Patterns

Look for recurring themes:
- Problems that appeared multiple times
- Solutions that worked well
- Mistakes to avoid

### Step 4: Create Seed File

Output: `psi/memory/seeds/[project]_[date]_wisdom.md`

```markdown
# Seed: [Project Name]

> Distilled from [X] retrospectives, [Date Range]

## Generation
- Source: Generation [N]
- Distilled: [Date]
- Retrospectives: [Count]

## Key Learnings

### What Worked
- [Pattern 1]
- [Pattern 2]

### What Didn't Work
- [Anti-pattern 1]
- [Anti-pattern 2]

### Key Decisions Made
| Decision | Rationale | Outcome |
|----------|-----------|---------|
| ... | ... | ... |

## Warnings for Future Self
- [Warning 1]
- [Warning 2]

## Recommendations
- [Recommendation 1]
- [Recommendation 2]
```

### Step 5: Confirm Distillation

```bash
sh psi/matrix/voice.sh "Distillation complete. Seed file created. Wisdom preserved." "Scribe"
```

## Output Location

```
psi/memory/seeds/
├── matrix_genesis_2026-01_wisdom.md
├── project_alpha_2026-02_wisdom.md
└── ...
```

## Quality Standards

- **Minimum**: 5 key learnings extracted
- **No raw logs**: Only distilled patterns
- **Actionable**: Each item should guide future behavior

## Core Principle

> *"Retrospectives are raw ore. Seeds are refined gold."*

The seed file is portable wisdom. It can be imported into any new Matrix to transfer hard-won knowledge without the baggage of session-specific details.

---

*Reference: psi/The_Source/BIBLE.md - Part V: Three Laws of Memory*
