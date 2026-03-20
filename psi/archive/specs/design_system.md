# Design System Spec (Modern CIS)

**Theme**: "Corporate Fidelity" (Clean, Professional, Legacy-Compatible)
**Tech**: Tailwind CSS + CSS Variables

## 1. Color Palette (Semantic Tokens)

The system uses HSL values defined in `index.css`.

| Token | Usage | Value (Light) | Value (Dark) |
|-------|-------|---------------|--------------|
| `primary` | Main actions, active states | Corporate Green (81 68% 44%) | Same |
| `background` | Page background | Pure White | Dark Gray |
| `foreground` | Body text | Dark Gray | Off-white |
| `card` | Surfaces, panels | Light Gray | Dark Gray |
| `border` | Dividers, inputs | Light Gray (90%) | Darker Gray |
| `destructive`| Error states, delete | Red | Red |

## 2. Typography

**Font Family**: `Inter`, system-ui.

| Scale | Class | Size | Weight |
|-------|-------|------|--------|
| h1 | `text-3xl` | 30px | 600 |
| h2 | `text-2xl` | 24px | 600 |
| h3 | `text-xl` | 20px | 600 |
| body | `text-base` | 16px | 400 |
| small | `text-sm` | 14px | 400 |

## 3. Tailwind Configuration Strategy

To bridge CSS variables -> Tailwind, we will use `tailwind.config.js`:

```javascript
theme: {
  extend: {
    colors: {
      border: "hsl(var(--border))",
      background: "hsl(var(--background))",
      foreground: "hsl(var(--foreground))",
      primary: {
        DEFAULT: "hsl(var(--primary))",
        foreground: "hsl(var(--primary-foreground))",
      },
      // ... map all tokens
    }
  }
}
```

## 4. Animation

- `fade-in-up`: Entrance for cards/content.
