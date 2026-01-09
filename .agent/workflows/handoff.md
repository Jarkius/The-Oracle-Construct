---
description: Create complete design handoff package for implementation
---

# /handoff - Design Handoff Package

> Trinity's skill: Package everything Neo needs to implement a feature

## Purpose

A handoff is the complete package Trinity gives Neo before implementation begins. It contains tokens, component specs, screen layouts, sample data, and acceptance criteria. Neo should have ZERO design questions after receiving a handoff.

## Usage

```
/handoff [feature]            # Create handoff for feature
/handoff dashboard            # Example: Dashboard feature
/handoff status               # Show pending handoffs
```

## Handoff Package Contents

```
psi/specs/handoffs/[feature]/
├── README.md                 # Overview and instructions
├── tokens.json               # Relevant design tokens
├── components/               # Component specs needed
│   ├── FeatureCard.md
│   └── StatWidget.md
├── screens/                  # Screen layouts
│   ├── desktop.md
│   ├── mobile.md
│   └── wireframes/
├── data/                     # Sample data for development
│   └── mock-data.json
├── assets/                   # Images, icons needed
└── acceptance.md             # Definition of done
```

## Handoff Template

```markdown
# Handoff: [Feature Name]

**Created by**: Trinity
**Date**: [date]
**Status**: Ready for Implementation

---

## Overview

[Brief description of the feature]

### User Story
As a [user], I want to [action] so that [benefit].

### Scope
- [What's included]
- [What's NOT included]

---

## Design Tokens Required

Reference these from `psi/specs/tokens/`:
- Colors: primary, background, text
- Spacing: md, lg
- Typography: heading, body

---

## Components Required

| Component | Status | Spec |
|-----------|--------|------|
| FeatureCard | New | [link to spec] |
| StatWidget | Exists | [link to spec] |

---

## Screen Layout

### Desktop (1280px+)
[Description or wireframe reference]

### Mobile (< 768px)
[Description or wireframe reference]

---

## Sample Data

```json
{
  "items": [
    {"id": 1, "name": "Example", "value": 100}
  ]
}
```

---

## Acceptance Criteria

- [ ] Displays list of [items]
- [ ] Clicking item opens detail view
- [ ] Works on mobile and desktop
- [ ] Loading state shown during fetch
- [ ] Error state if API fails

---

## Notes for Neo

- Use existing `Card` component as base
- API endpoint: `/api/items`
- Follow existing patterns in `src/components/`

---

## Estimated Effort

| Task | Estimate |
|------|----------|
| Components | 2 features |
| Integration | 1 feature |
| Testing | 1 feature |
| **Total** | 4 features |
```

## Workflow

<workflow>

<step n="1" goal="Gather Requirements">
  <action>Understand what feature is needed</action>
  <action>Check existing specs:</action>
  ```bash
  ls psi/specs/
  ./psi/active/get_focus.sh
  ```
</step>

<step n="2" goal="Define Components">
  <action>For each new component needed, run:</action>
  `/component-spec [ComponentName]`
</step>

<step n="3" goal="Create Screen Layouts">
  <action>Define layout for each viewport:</action>
  - Desktop layout
  - Tablet layout (if different)
  - Mobile layout
</step>

<step n="4" goal="Prepare Sample Data">
  <action>Create realistic mock data for development</action>
  <action>Save to `handoffs/[feature]/data/mock-data.json`</action>
</step>

<step n="5" goal="Write Acceptance Criteria">
  <action>Define "done" clearly:</action>
  - What must work?
  - What states must be handled?
  - What edge cases?
</step>

<step n="6" goal="Package and Deliver">
  <action>Create handoff directory structure</action>
  <action>Write README.md with overview</action>
  <action>Report: "Handoff ready. Neo can begin."</action>
</step>

</workflow>

## Quality Checklist

- [ ] All components have specs?
- [ ] Screen layouts for all viewports?
- [ ] Sample data provided?
- [ ] Acceptance criteria testable?
- [ ] No design decisions left for Neo?

## Philosophy

> "A complete handoff means zero design questions during implementation."

Neo should never have to ask "what should this look like?" If he does, the handoff was incomplete.

ARGUMENTS: $ARGUMENTS
