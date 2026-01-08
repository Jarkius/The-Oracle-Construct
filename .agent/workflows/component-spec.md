---
description: Specify UI components before implementation - props, states, variants
---

# /component-spec - Component Specification

> Trinity's skill: Define what a component IS before Neo builds it

## Purpose

A component spec is the blueprint Neo needs. It defines props, states, variants, and behavior BEFORE any code is written. This prevents rework and ensures design intent is preserved.

## Usage

```
/component-spec [ComponentName]     # Create spec for component
/component-spec Button              # Example: Button component
/component-spec list                # List all component specs
```

## Component Spec Template

```markdown
# Component: [Name]

## Purpose
[What problem does this component solve?]

## Visual Reference
[Screenshot or description of how it should look]

## Props

| Prop | Type | Default | Required | Description |
|------|------|---------|----------|-------------|
| variant | 'primary' \| 'secondary' \| 'ghost' | 'primary' | No | Visual style |
| size | 'sm' \| 'md' \| 'lg' | 'md' | No | Size variant |
| disabled | boolean | false | No | Disabled state |
| onClick | () => void | - | Yes | Click handler |
| children | ReactNode | - | Yes | Button content |

## States

| State | Description | Visual Change |
|-------|-------------|---------------|
| Default | Normal state | Base styling |
| Hover | Mouse over | Darker background |
| Active | Being clicked | Even darker, slight scale |
| Disabled | Not interactive | Muted colors, no cursor |
| Loading | Async operation | Spinner, disabled |

## Variants

### Primary (default)
- Background: var(--color-primary)
- Text: white
- Use for: Main actions

### Secondary
- Background: transparent
- Border: var(--color-primary)
- Text: var(--color-primary)
- Use for: Secondary actions

### Ghost
- Background: transparent
- Text: var(--color-text)
- Use for: Tertiary actions

## Spacing (using tokens)
- Padding: var(--space-sm) var(--space-md)
- Gap (icon + text): var(--space-xs)

## Accessibility
- [ ] Keyboard focusable
- [ ] Focus ring visible
- [ ] aria-disabled when disabled
- [ ] aria-busy when loading

## Usage Examples

```jsx
// Primary action
<Button variant="primary" onClick={handleSave}>
  Save Changes
</Button>

// With icon
<Button variant="secondary" icon={<PlusIcon />}>
  Add Item
</Button>

// Loading state
<Button loading disabled>
  Saving...
</Button>
```

## Related Components
- IconButton (icon-only variant)
- ButtonGroup (grouped buttons)
- LinkButton (looks like link)
```

## Workflow

<workflow>

<step n="1" goal="Identify Component Need">
  <action>User says "we need a [component]" or feature requires new UI</action>
  <action>Check if spec already exists:</action>
  ```bash
  ls psi/specs/components/
  ```
</step>

<step n="2" goal="Define Component">
  <ask>What is the primary purpose of this component?</ask>
  <action>List all props needed</action>
  <action>Identify all states (hover, active, disabled, etc.)</action>
  <action>Define variants if needed</action>
</step>

<step n="3" goal="Reference Tokens">
  <action>Map component styling to design tokens:</action>
  ```bash
  cat psi/specs/tokens/colors.json
  cat psi/specs/tokens/spacing.json
  ```
  <action>Use token variables, never hardcoded values</action>
</step>

<step n="4" goal="Save Spec">
  <action>Save to `psi/specs/components/[ComponentName].md`</action>
  <action>Report: "Component spec ready for Neo"</action>
</step>

</workflow>

## Output Location

```
psi/specs/components/
├── Button.md
├── Input.md
├── Card.md
├── Modal.md
├── Table.md
└── ...
```

## Quality Checklist

- [ ] Purpose clearly stated?
- [ ] All props documented with types?
- [ ] All states defined?
- [ ] Uses design tokens (not hardcoded values)?
- [ ] Accessibility requirements listed?
- [ ] Usage examples provided?

## Philosophy

> "Spec before code. Design intent preserved."

A well-written component spec saves hours of back-and-forth between Trinity and Neo.

ARGUMENTS: $ARGUMENTS
