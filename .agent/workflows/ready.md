---
description: Implementation readiness check before coding starts
---

# /ready - Implementation Readiness Check

> Architect's skill: Verify everything is ready before coding starts

## Usage

```
/ready [feature name]
/ready              # Check overall readiness
```

## Auto-Trigger When:
- Before Neo starts implementation
- User says "are we ready to build"
- User says "can we start coding"
- After /tech-spec is created

## Action

<workflow>

<step n="1" goal="Gather Artifacts">
  <action>Locate all planning documents:</action>

  ```bash
  ls psi/specs/adrs/
  ls psi/specs/tech-specs/
  ls psi/specs/stories/
  ls psi/specs/design_system.md
  ```

  <action>Note what exists and what's missing</action>
</step>

<step n="2" goal="Run Readiness Checklist">
  <action>Evaluate each criterion:</action>

  ```markdown
  ## Implementation Readiness Checklist

  ### Architecture
  - [ ] ADR exists for major decisions?
  - [ ] Tech stack confirmed?
  - [ ] No blocking unknowns?

  ### Design (Trinity)
  - [ ] Design tokens defined?
  - [ ] Component specs available?
  - [ ] UI/UX reviewed?

  ### Specification
  - [ ] Tech spec complete?
  - [ ] Files to modify listed?
  - [ ] Tasks broken down?
  - [ ] Acceptance criteria defined?

  ### Stories (Neo)
  - [ ] User stories created?
  - [ ] Stories meet INVEST criteria?
  - [ ] Dependencies identified?

  ### Testing
  - [ ] Test strategy defined?
  - [ ] Test data available?
  - [ ] E2E scenarios documented?

  ### Environment
  - [ ] Dev environment working?
  - [ ] Dependencies installed?
  - [ ] Database accessible?
  ```
</step>

<step n="3" goal="Report Findings">
  <action>Generate readiness report:</action>

  ```markdown
  ## Readiness Report

  **Feature**: [name]
  **Date**: [date]
  **Status**: READY | NOT READY | BLOCKED

  ### Summary
  - ✅ Ready: [count] items
  - ⚠️ Warning: [count] items
  - ❌ Blocking: [count] items

  ### Blocking Issues
  1. [Issue] - [What's needed]

  ### Warnings
  1. [Issue] - [Recommendation]

  ### Ready Items
  - [List of completed items]

  ### Recommendation
  [GO / NO-GO with reasoning]
  ```
</step>

<step n="4" goal="Decision">
  <action>Based on findings:</action>

  **If READY:**
  - Report: "Implementation ready. Neo can begin."
  - Suggest: `/neo` or `/story` to start

  **If NOT READY:**
  - List blocking items
  - Suggest which agent to invoke:
    - Missing ADR → `/adr`
    - Missing design → `/trinity`
    - Missing spec → `/tech-spec`
    - Missing story → `/story`

  **If BLOCKED:**
  - HALT with clear blocker description
  - Require user decision to proceed
</step>

</workflow>

## HALT Conditions
- HALT if critical artifacts missing
- HALT if blocking decisions not made
- HALT if environment not working

ARGUMENTS: $ARGUMENTS
