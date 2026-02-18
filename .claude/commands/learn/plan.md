---
description: Create a structured study plan for any topic or certification
---

# /learn:plan — Study Planner

> *"I can only show you the door." — Morpheus*

## Purpose

Create a structured study plan for any topic, technology, or certification. Breaks complex subjects into daily/weekly modules with milestones and progress tracking.

## Usage

```
/learn:plan <topic>
/learn:plan "AWS Solutions Architect certification"
/learn:plan "TypeScript advanced patterns" --weeks 4
/learn:plan "Laravel from scratch" --hours-per-day 2
```

## Process

### 1. Scope Assessment (Morpheus — Sonnet)

Research the topic to determine:
- **Depth**: Beginner → Intermediate → Advanced → Expert
- **Breadth**: How many sub-topics?
- **Prerequisites**: What should you already know?
- **Time estimate**: Realistic hours to competency

### 2. Generate Study Plan

Create a structured plan with milestones:

```markdown
# Study Plan: <Topic>

**Created**: YYYY-MM-DD
**Target**: <what competency looks like>
**Duration**: <N weeks>
**Pace**: <hours per day/week>
**Prerequisites**: <what you should know first>

## Roadmap

```
Week 1: Foundation ████░░░░░░
Week 2: Core       ░░░░░░░░░░
Week 3: Practice   ░░░░░░░░░░
Week 4: Mastery    ░░░░░░░░░░
```

## Week 1: <Foundation Topic>

### Goals
- [ ] Understand X
- [ ] Build Y
- [ ] Practice Z

### Daily Breakdown

| Day | Topic | Activity | Time | Resource |
|-----|-------|----------|------|----------|
| Mon | Basics | Read docs + notes | 1.5h | [link] |
| Tue | Setup | Hands-on lab | 2h | [link] |
| Wed | Core Concept A | Tutorial + practice | 1.5h | [link] |
| Thu | Core Concept B | Build mini-project | 2h | — |
| Fri | Review | Flashcards + quiz | 1h | /learn:flash |

### Milestone
**Can you...?** <concrete test of understanding>

### Resources
- [Primary] <best single resource for this week>
- [Supplement] <backup resource>
- [Practice] <exercises or project>

## Week 2: <Core Topic>
...

## Final Project
<Capstone project that proves competency>

## Review Schedule (Spaced Repetition)
- After Week 1: Review Week 1 (30 min)
- After Week 2: Review Week 1+2 (45 min)
- After Week 3: Review all (1 hour)
- After completion: Weekly review for 1 month
```

### 3. Save and Track

Save to `psi/learn/active/<topic>-study-plan.md`

Register as a task in `psi/memory/tasks/active.json`:
```json
{
  "id": "learn-<topic-slug>",
  "task": "Study plan: <topic>",
  "status": "in_progress",
  "assignee": "Morpheus",
  "context": "Study plan created YYYY-MM-DD, <N> weeks, <M> hours/week"
}
```

```bash
sh psi/matrix/voice.sh "Study plan created. The path is mapped." "Morpheus"
bash .claude/hooks/pulse-event-writer.sh "learning:new" "Morpheus" "{\"topic\":\"<topic>-study-plan\"}"
```

### 4. Progress Check

When invoked with an existing plan topic:
- Read the study plan
- Show progress bar per week
- Highlight current position
- Suggest next action
- Suggest `/learn:concept` for any concept that needs deeper understanding

## Defaults

- **Duration**: 4 weeks (adjustable with --weeks)
- **Pace**: 1.5 hours/day (adjustable with --hours-per-day)
- **Style**: Mix of reading, building, and reviewing

## Quality Gates

- [ ] Milestones are concrete ("Can you build X?") not vague ("Understand X")
- [ ] Resources are real and current (searched, not hallucinated)
- [ ] Daily time estimates are realistic
- [ ] Final project actually tests the stated goal
- [ ] Review schedule follows spaced repetition principles

ARGUMENTS: $ARGUMENTS
