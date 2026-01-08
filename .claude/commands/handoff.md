# /handoff - Design Handoff Package

> *Trinity - "Everything Neo needs, nothing more."*

Create complete design handoff package for implementation.

## Usage

```
/handoff [feature]            # Create handoff for feature
/handoff dashboard            # Example: Dashboard feature
/handoff status               # Show pending handoffs
```

## Package Contents

```
psi/specs/handoffs/[feature]/
├── README.md                 # Overview
├── tokens.json               # Design tokens
├── components/               # Component specs
├── screens/                  # Layouts
├── data/                     # Mock data
└── acceptance.md             # Done criteria
```

## Philosophy

> "A complete handoff means zero design questions."

Neo should never ask "what should this look like?"

ARGUMENTS: $ARGUMENTS
