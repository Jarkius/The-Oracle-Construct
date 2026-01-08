# /component-spec - Component Specification

> *Trinity - "I see what it should be."*

Specify UI components before implementation - props, states, variants.

## Usage

```
/component-spec [ComponentName]     # Create spec for component
/component-spec Button              # Example: Button component
/component-spec list                # List all component specs
```

## Spec Contents

- **Props**: Type, default, required, description
- **States**: Default, hover, active, disabled, loading
- **Variants**: Primary, secondary, ghost
- **Accessibility**: Keyboard, focus, ARIA

## Output

`psi/specs/components/[ComponentName].md`

## Philosophy

> "Spec before code. Design intent preserved."

Neo should never guess what something looks like.

ARGUMENTS: $ARGUMENTS
