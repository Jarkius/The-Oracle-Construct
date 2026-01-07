---
description: Technical Specification - create implementation-ready specs
---

# /tech-spec - Technical Specification

> Architect's skill: Create implementation-ready technical specs

## Usage

```
/tech-spec [feature name]
/tech-spec user authentication
/tech-spec dashboard widgets
```

## Auto-Trigger When User Says:
- "how do we implement"
- "what's the technical approach"
- "spec out"
- "plan the implementation"
- "before Neo starts"

## Action

<workflow>

<step n="1" goal="Identify Scope">
  <action>If feature specified → Use as title</action>
  <action>If not → Ask: "What feature needs a technical specification?"</action>
  <action>Check for related:</action>
  - Stories: `psi/specs/stories/`
  - ADRs: `psi/specs/adrs/`
  - Design specs: `psi/specs/`
</step>

<step n="2" goal="Problem & Solution">
  <action>Define clearly:</action>

  **Problem Statement**
  - What problem does this solve?
  - Who has this problem?
  - What happens if we don't solve it?

  **Proposed Solution**
  - High-level approach
  - Key components involved
</step>

<step n="3" goal="Scope Definition">
  <action>Define boundaries:</action>

  **In Scope**
  - [What WILL be implemented]

  **Out of Scope**
  - [What will NOT be implemented]
  - [Future considerations]
</step>

<step n="4" goal="Technical Details">
  <action>Specify implementation:</action>

  ```markdown
  ## Files to Modify/Create

  | File | Action | Purpose |
  |------|--------|---------|
  | src/components/X.jsx | Create | New component |
  | src/api/Y.php | Modify | Add endpoint |

  ## Codebase Patterns to Follow

  - [Pattern 1 from existing code]
  - [Pattern 2]

  ## Technical Decisions

  - [Decision 1 and why]
  - [Decision 2 and why]

  ## Dependencies

  - [Package/library needed]
  - [API dependency]
  ```
</step>

<step n="5" goal="Implementation Plan">
  <action>Break into tasks:</action>

  ```markdown
  ## Tasks

  - [ ] Task 1: [Specific, actionable]
  - [ ] Task 2: ...
  - [ ] Task 3: ...

  ## Acceptance Criteria

  - [ ] AC1: [Testable criterion]
  - [ ] AC2: ...

  ## Testing Strategy

  - Unit tests: [what to test]
  - Integration tests: [what to test]
  - E2E tests: [what to test]
  ```
</step>

<step n="6" goal="Save & Handoff">
  <ask>Review spec. Approve [a], Edit [e], or Cancel [c]?</ask>
  <action>Save to `psi/specs/tech-specs/[feature-slug].md`</action>
  <action>Report: "Tech spec ready. Neo can begin implementation."</action>
  <action>Suggest: "Run /ready to verify implementation readiness."</action>
</step>

</workflow>

## Quality Checklist

- [ ] Problem clearly stated?
- [ ] Solution is specific, not vague?
- [ ] Files to modify listed?
- [ ] Tasks are actionable?
- [ ] Acceptance criteria testable?

ARGUMENTS: $ARGUMENTS
