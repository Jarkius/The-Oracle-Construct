# /ready - Implementation Readiness Check

> *Architect - "The problem is choice."*

Verify everything is ready before coding starts.

## Usage

```
/ready [feature name]    # Check specific feature
/ready                   # Check overall readiness
```

## Checklist

### Architecture
- [ ] ADR exists for major decisions?
- [ ] Tech stack confirmed?
- [ ] No blocking unknowns?

### Design (Trinity)
- [ ] Design tokens defined?
- [ ] Component specs available?
- [ ] UI/UX reviewed?

### Specification
- [ ] Tech spec complete?
- [ ] Files to modify listed?
- [ ] Tasks broken down?
- [ ] Acceptance criteria defined?

### Stories (Neo)
- [ ] User stories created?
- [ ] INVEST criteria met?
- [ ] Dependencies identified?

### Testing
- [ ] Test strategy defined?
- [ ] Test data available?

### Environment
- [ ] Dev environment working?
- [ ] Dependencies installed?

## Output

```
## Readiness Report

**Feature**: [name]
**Status**: READY | NOT READY | BLOCKED

### Summary
- Ready: [count] items
- Warning: [count] items
- Blocking: [count] items

### Recommendation
[GO / NO-GO with reasoning]
```

## Decision

**If READY**: "Neo can begin."
**If NOT READY**: Suggest which agent to invoke
**If BLOCKED**: HALT with clear blocker

ARGUMENTS: $ARGUMENTS
