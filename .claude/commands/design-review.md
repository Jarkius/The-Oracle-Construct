# /design-review - Design Implementation Review

> *Trinity - "Does it match my vision?"*

Review implementation against design spec - visual QA.

## Usage

```
/design-review [component]     # Review specific component
/design-review page [name]     # Review entire page
/design-review pr [number]     # Review changes in PR
```

## Checklist

- [ ] Token compliance (no hardcoded values)
- [ ] Visual accuracy (matches spec)
- [ ] State coverage (hover, active, disabled)
- [ ] Responsive behavior
- [ ] Accessibility

## Severity Levels

| Level | Action |
|-------|--------|
| Critical | Must fix before merge |
| Major | Should fix before merge |
| Minor | Can fix in follow-up |

## Output

`psi/specs/reviews/[component]_[date].md`

ARGUMENTS: $ARGUMENTS
