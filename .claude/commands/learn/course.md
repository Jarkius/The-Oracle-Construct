---
description: Track progress through an online course or tutorial
---

# /learn:course — Course Tracker

> *"You've been down that road. You know exactly where it ends." — Trinity*

## Purpose

Track progress through online courses, tutorials, documentation, or any structured learning path. Maintains state between sessions, identifies gaps, and suggests review.

## Usage

```
/learn:course start <course-name> <url>       # Start tracking a course
/learn:course progress <course-name>           # Check progress
/learn:course complete <course-name> <section> # Mark section complete
/learn:course quiz <course-name>               # Test retention
/learn:course list                             # List all tracked courses
```

## Process

### Start a Course (`/learn:course start`)

1. **Fetch course structure** (if URL provided):
   - WebFetch the course page
   - Extract sections/modules/chapters
   - Estimate time per section

2. **Create tracker** at `psi/knowledge/active/course-<name>.md`:

```markdown
# Course: <Name>

**URL**: <url>
**Started**: YYYY-MM-DD
**Status**: In Progress
**Progress**: 0/<total> sections (0%)

## Sections

| # | Section | Status | Completed | Notes |
|---|---------|--------|-----------|-------|
| 1 | Introduction | pending | — | |
| 2 | Setup & Basics | pending | — | |
| 3 | Core Concepts | pending | — | |
| 4 | Advanced Topics | pending | — | |
| 5 | Final Project | pending | — | |

## Learning Log

### YYYY-MM-DD
- Started course
- Goals: ...

## Key Takeaways
<Updated as sections are completed>

## Questions
<Things to research further>
```

3. **Register as task**:
```json
{
  "id": "course-<name>",
  "task": "Course: <name>",
  "status": "in_progress",
  "assignee": "Morpheus",
  "context": "Started YYYY-MM-DD, N sections"
}
```

### Check Progress (`/learn:course progress`)

1. Read the course tracker file
2. Display progress bar and stats:

```
## Course: <Name>
Progress: ████████░░░░░░░░░░░░ 8/20 (40%)
Last activity: 2 days ago
Current section: Core Concepts (Section 9)

Pace: 2.7 sections/week
Estimated completion: YYYY-MM-DD

Next up: Section 9 — Event Handling
```

### Complete a Section (`/learn:course complete`)

1. Update tracker: mark section as `done`, add completion date
2. Prompt for notes:
   - What did you learn?
   - Any questions?
   - Connection to other knowledge?
3. Update progress percentage
4. If milestone reached (25%, 50%, 75%, 100%), announce:
   ```bash
   sh psi/matrix/voice.sh "Milestone reached. Fifty percent complete." "Morpheus"
   ```

### Quiz (`/learn:course quiz`)

1. Read completed sections from tracker
2. Generate 5-10 questions covering completed material
3. Present as interactive Q&A
4. Score and identify weak areas
5. Suggest re-review for sections with low scores

### List Courses (`/learn:course list`)

```markdown
## Active Courses

| Course | Progress | Last Activity | Pace |
|--------|----------|---------------|------|
| Laravel 11 | 12/20 (60%) | Yesterday | 3/week |
| AWS SA | 4/15 (27%) | 5 days ago | 1/week |

## Completed Courses

| Course | Completed | Duration | Sections |
|--------|-----------|----------|----------|
| React Basics | 2026-01-15 | 2 weeks | 10 |
```

## Progress Persistence

- Course files persist in `psi/knowledge/active/course-*.md`
- Completed courses move to `psi/learn/archive/YYYY-MM/course-*.md`
- Task registry tracks active courses
- Events logged: `learning:course-progress`, `learning:course-complete`

## Integration with Other Learn Skills

- `/learn:concept <section-topic>` — deep-dive a section you're struggling with
- `/learn:teach <section-topic>` — test your understanding by explaining it
- `/learn:flash <course-name>` — generate flashcards from completed sections
- `/learn done <course-name>` — full synthesis when course is complete

## Quality Gates

- [ ] Course structure accurately reflects the source
- [ ] Progress percentages are correct
- [ ] Quiz questions test actual understanding
- [ ] Time estimates are realistic
- [ ] Learning log captures genuine insights

ARGUMENTS: $ARGUMENTS
