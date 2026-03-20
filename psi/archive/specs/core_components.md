# Core Components Spec (Modern CIS)

**Component Library**: Reusable UI Atoms
**Tech**: React + Tailwind CSS + CVA (Class Variance Authority)

## 1. Button

**Variants**:
| Variant | Background | Text | Border | Use Case |
|---------|------------|------|--------|----------|
| `default` | `bg-primary` | `text-primary-foreground` | None | Primary actions |
| `destructive` | `bg-destructive` | `text-destructive-foreground` | None | Delete, Logout |
| `outline` | Transparent | `text-foreground` | `border-border` | Secondary actions |
| `ghost` | Transparent | `text-foreground` | None | Tertiary, inline |
| `link` | Transparent | `text-primary` (underline) | None | Navigation |

**Sizes**: `sm`, `default`, `lg`, `icon`

**States**: Hover, Focus (ring), Disabled (opacity), Loading (spinner)

## 2. Input

**Structure**: Label (optional) + Input Field + Error Message (optional)

**Styles**:
- Background: `bg-input`
- Border: `border-border`, focus: `ring-ring`
- Text: `text-foreground`, placeholder: `text-muted-foreground`

**States**: Default, Focus, Error (red border), Disabled

## 3. Card

**Structure**: CardHeader, CardTitle, CardDescription, CardContent, CardFooter

**Styles**:
- Background: `bg-card`
- Border: `border-border`
- Shadow: `shadow-sm` or `shadow`
- Radius: `rounded-lg`

## 4. Modal (Dialog)

**Structure**: Overlay (backdrop) + Content Panel

**Styles**:
- Overlay: `bg-black/80`
- Panel: `bg-background`, centered, `rounded-lg`, `shadow-lg`
- Animations: Fade in overlay, Scale in content.

**Accessibility**: Focus trap, Escape to close.
