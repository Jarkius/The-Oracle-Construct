# /tokens - Design Token System

> *Trinity - "The Woman in Red knows the colors."*

Define the visual DNA - colors, spacing, typography, shadows.

## Usage

```
/tokens init              # Create initial token system
/tokens colors            # Define/update color palette
/tokens spacing           # Define spacing scale
/tokens typography        # Define font system
/tokens status            # Show current token coverage
```

## Token Categories

### Colors
```css
--color-primary: #86BC25;        /* Deloitte Green */
--color-background: #FFFFFF;
--color-text: #333333;
```

### Spacing
```css
--space-xs: 4px;
--space-sm: 8px;
--space-md: 16px;
--space-lg: 24px;
```

### Typography
```css
--font-family: 'Inter', sans-serif;
--font-size-base: 16px;
```

## Output

`psi/specs/tokens/` directory

## Philosophy

> "Design before code. Tokens before components."

ARGUMENTS: $ARGUMENTS
