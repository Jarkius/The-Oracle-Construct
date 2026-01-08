---
description: Define design tokens - colors, spacing, typography, shadows
---

# /tokens - Design Token System

> Trinity's skill: Define the visual DNA before any component is built

## Purpose

Design tokens are the atomic values that define your visual language. They ensure consistency across all components and make global changes trivial.

## Usage

```
/tokens init              # Create initial token system
/tokens colors            # Define/update color palette
/tokens spacing           # Define spacing scale
/tokens typography        # Define font system
/tokens status            # Show current token coverage
```

## Token Categories

### 1. Colors
```css
/* Primary */
--color-primary: #86BC25;        /* Deloitte Green */
--color-primary-dark: #6B9A1E;
--color-primary-light: #A5D94A;

/* Neutral */
--color-background: #FFFFFF;
--color-surface: #F5F5F5;
--color-text: #333333;
--color-text-muted: #666666;

/* Semantic */
--color-success: #28A745;
--color-warning: #FFC107;
--color-error: #DC3545;
--color-info: #17A2B8;
```

### 2. Spacing
```css
--space-xs: 4px;
--space-sm: 8px;
--space-md: 16px;
--space-lg: 24px;
--space-xl: 32px;
--space-2xl: 48px;
```

### 3. Typography
```css
--font-family: 'Inter', -apple-system, sans-serif;
--font-size-xs: 12px;
--font-size-sm: 14px;
--font-size-base: 16px;
--font-size-lg: 18px;
--font-size-xl: 24px;
--font-size-2xl: 32px;

--font-weight-normal: 400;
--font-weight-medium: 500;
--font-weight-bold: 700;
```

### 4. Shadows
```css
--shadow-sm: 0 1px 2px rgba(0,0,0,0.05);
--shadow-md: 0 4px 6px rgba(0,0,0,0.1);
--shadow-lg: 0 10px 15px rgba(0,0,0,0.1);
```

### 5. Border Radius
```css
--radius-sm: 4px;
--radius-md: 8px;
--radius-lg: 12px;
--radius-full: 9999px;
```

## Workflow

<workflow>

<step n="1" goal="Audit Current State">
  <action>Check existing token definitions:</action>
  ```bash
  cat psi/specs/design_system.md
  ls psi/specs/tokens/
  ```
  <action>Identify missing or inconsistent tokens</action>
</step>

<step n="2" goal="Define or Update Tokens">
  <action>For each category, define values based on:</action>
  - Brand guidelines (if available)
  - Legacy system analysis (for modernization)
  - Industry standards (8px grid, etc.)
</step>

<step n="3" goal="Save Token File">
  <action>Save to `psi/specs/tokens/[category].json`:</action>
  ```json
  {
    "colors": {
      "primary": "#86BC25",
      "primaryDark": "#6B9A1E"
    }
  }
  ```
</step>

<step n="4" goal="Generate Implementation">
  <action>Output format for Neo:</action>
  - CSS custom properties (for React)
  - Tailwind config (if using Tailwind)
  - SCSS variables (if needed)
</step>

</workflow>

## Output Location

`psi/specs/tokens/` directory:
```
tokens/
├── colors.json
├── spacing.json
├── typography.json
├── shadows.json
└── index.json       # Combined export
```

## Integration

After defining tokens, Neo uses them:
```jsx
// React component using tokens
<button style={{
  backgroundColor: 'var(--color-primary)',
  padding: 'var(--space-md)',
  borderRadius: 'var(--radius-md)'
}}>
  Click me
</button>
```

## Philosophy

> "Design before code. Tokens before components."

Tokens are the contract between Trinity and Neo. Define them first, implement them always.

ARGUMENTS: $ARGUMENTS
