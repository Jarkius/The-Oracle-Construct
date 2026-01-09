---
description: Course correction - navigate when things go off-track
---

# /correct - Course Correction

> Smith/Oracle skill: Navigate when things go off-track

## Usage

```
/correct [issue description]
```

## When to Use
- Implementation is off-track
- Requirements changed mid-sprint
- Bug discovered that affects plan
- User says: "this isn't working", "wrong approach", "need to change"

## Action

<workflow>

<step n="1" goal="Identify the Issue">
  <action>Ask: "What specific issue has been identified?"</action>
  <action>Gather context about what went wrong</action>
  <action>Check current focus: `./psi/active/get_focus.sh`</action>
</step>

<step n="2" goal="Impact Analysis">
  <action>Analyze what's affected:</action>
  - Which files were changed?
  - What was the original goal?
  - What broke or diverged?
  <action>Run: `git diff --stat` to see scope</action>
</step>

<step n="3" goal="Propose Correction">
  <action>Present options:</action>

  **Option A: Direct Fix**
  - Small adjustment, continue current path

  **Option B: Rollback + Retry**
  - Undo recent changes, try different approach

  **Option C: Pivot**
  - Change requirements/goals based on learnings

  <ask>Which approach? [A/B/C]</ask>
</step>

<step n="4" goal="Execute Correction">
  <action>Based on choice:</action>
  - A → Smith fixes, Neo continues
  - B → `git stash` or `git reset`, restart
  - C → Create new plan/retrospective with Architect
  
  <action>Add correction notes to next retrospective</action>
</step>

<step n="5" goal="Verify">
  <action>Confirm correction applied</action>
  <action>Run tests if applicable</action>
  <action>Report: "Course corrected. Ready to continue."</action>
</step>

</workflow>

## Halt Conditions
- HALT if issue is unclear - ask for specifics
- HALT if correction requires user decision - present options

ARGUMENTS: $ARGUMENTS
