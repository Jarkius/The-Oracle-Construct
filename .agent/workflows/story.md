---
description: Create developer-ready user stories with acceptance criteria
---

# /story - Create Dev Story

> Neo's skill: Generate developer-ready user stories

## Usage

```
/story [feature name]
/story login form
/story dark mode toggle
```

## Action

<workflow>

<step n="1" goal="Gather Requirements">
  <action>If feature specified → Use as starting point</action>
  <action>If not specified → Ask: "What feature should I create a story for?"</action>
  <action>Check existing specs:</action>
  - `psi/specs/*.md` for design specs
  - `./psi/active/get_focus.sh` for current priorities
</step>

<step n="2" goal="Generate Story Structure">
  <action>Create story with this format:</action>

  ```markdown
  # Story: [Feature Name]

  ## User Story
  As a [user type]
  I want to [action]
  So that [benefit]

  ## Acceptance Criteria
  - [ ] AC1: [Specific, testable criterion]
  - [ ] AC2: ...
  - [ ] AC3: ...

  ## Tasks
  - [ ] Task 1: [Implementation step]
  - [ ] Task 2: ...
  - [ ] Task 3: ...

  ## Technical Notes
  - Files to modify: [list]
  - Dependencies: [list]
  - API endpoints: [if applicable]

  ## Design Reference
  - See: [link to Trinity's specs if available]

  ## Definition of Done
  - [ ] All AC met
  - [ ] Tests written and passing
  - [ ] Code reviewed
  - [ ] Documentation updated
  ```
</step>

<step n="3" goal="Validate Story">
  <action>Check story against INVEST criteria:</action>
  - **I**ndependent - Can be built separately?
  - **N**egotiable - Flexible on implementation?
  - **V**aluable - Delivers user value?
  - **E**stimable - Can estimate effort?
  - **S**mall - Fits in one session?
  - **T**estable - Can verify completion?

  <ask>Save this story? [y/n/edit]</ask>
</step>

<step n="4" goal="Save Story">
  <action>Save to `psi/specs/stories/[feature-name].md`</action>
  <action>Log to `psi/inbox/backlog.md` (if exists)</action>
  <action>Report: "Story ready for implementation."</action>
</step>

</workflow>

## Quick Mode
Add `--yolo` to skip confirmations:
```
/story login form --yolo
```

ARGUMENTS: $ARGUMENTS
