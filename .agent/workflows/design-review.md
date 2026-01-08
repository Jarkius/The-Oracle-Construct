---
description: Review implementation against design spec - visual QA
---

# /design-review - Design Implementation Review

> Trinity's skill: Verify Neo's implementation matches the design intent

## Purpose

After Neo implements a component or feature, Trinity reviews it against the original spec. This catches visual bugs, accessibility issues, and design drift before they reach production.

## Usage

```
/design-review [component]     # Review specific component
/design-review page [name]     # Review entire page
/design-review pr [number]     # Review changes in PR
```

## Review Checklist

### 1. Token Compliance
- [ ] Uses design tokens (not hardcoded colors/spacing)?
- [ ] Consistent with token definitions?
- [ ] No magic numbers?

### 2. Visual Accuracy
- [ ] Matches spec layout?
- [ ] Correct spacing between elements?
- [ ] Typography matches spec?
- [ ] Colors are correct?
- [ ] Shadows/borders as specified?

### 3. State Coverage
- [ ] Default state correct?
- [ ] Hover state implemented?
- [ ] Active/pressed state?
- [ ] Disabled state?
- [ ] Loading state (if applicable)?
- [ ] Error state (if applicable)?

### 4. Responsive Behavior
- [ ] Works on mobile (< 768px)?
- [ ] Works on tablet (768-1024px)?
- [ ] Works on desktop (> 1024px)?
- [ ] No horizontal scroll issues?

### 5. Accessibility
- [ ] Keyboard navigable?
- [ ] Focus states visible?
- [ ] Screen reader friendly?
- [ ] Sufficient color contrast?
- [ ] ARIA attributes present?

### 6. Consistency
- [ ] Matches existing components?
- [ ] Follows established patterns?
- [ ] No visual inconsistencies?

## Workflow

<workflow>

<step n="1" goal="Load Spec">
  <action>Read the original component spec:</action>
  ```bash
  cat psi/specs/components/[ComponentName].md
  ```
</step>

<step n="2" goal="Examine Implementation">
  <action>Read the implemented code:</action>
  ```bash
  cat [path-to-component]
  ```
  <action>Check for token usage</action>
  <action>Verify props match spec</action>
</step>

<step n="3" goal="Visual Inspection">
  <ask>Can you show me a screenshot of the component?</ask>
  <action>Compare against spec requirements</action>
  <action>Note any discrepancies</action>
</step>

<step n="4" goal="Generate Review">
  <action>Create review report:</action>

  ```markdown
  ## Design Review: [Component]

  **Reviewer**: Trinity
  **Date**: [date]
  **Status**: APPROVED / NEEDS CHANGES

  ### Summary
  [Brief assessment]

  ### Findings

  #### Passes
  - [x] Token compliance
  - [x] Visual accuracy
  - [x] State coverage

  #### Issues Found
  1. **[Issue]**: [Description]
     - Spec says: [expected]
     - Implementation: [actual]
     - Fix: [recommendation]

  ### Recommendation
  [Approve / Request changes]
  ```
</step>

<step n="5" goal="Save Review">
  <action>Save to `psi/specs/reviews/[component]_[date].md`</action>
</step>

</workflow>

## Severity Levels

| Level | Description | Action |
|-------|-------------|--------|
| **Critical** | Breaks functionality or accessibility | Must fix before merge |
| **Major** | Significant visual deviation | Should fix before merge |
| **Minor** | Small visual tweaks | Can fix in follow-up |
| **Nitpick** | Preference, not requirement | Optional |

## Output Location

```
psi/specs/reviews/
├── Button_2026-01-08.md
├── LoginPage_2026-01-08.md
└── ...
```

## Philosophy

> "Design is in the details. Review catches the drift."

Every implementation should be reviewed against its spec. This is how quality is maintained.

ARGUMENTS: $ARGUMENTS
