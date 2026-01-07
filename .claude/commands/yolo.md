# /yolo - Fast Execution Mode

> *Neo - "I know kung fu."*

Skip confirmations, execute autonomously.

## Usage

```
/yolo [command]     # Run command in yolo mode
/yolo on            # Enable yolo for session
/yolo off           # Disable yolo mode
/yolo features      # Auto-build all features from feature_list.json
```

## What YOLO Does

| Normal | YOLO |
|--------|------|
| Ask before each step | Execute continuously |
| Confirm file changes | Auto-save |
| Present options | Make best choice |
| Wait for approval | Proceed automatically |

## Safety Rules

YOLO mode STILL respects:
- HALT conditions (errors, blockers)
- Critical actions (safety rules)
- Test execution
- Destructive operation blocks

## Autonomous Feature Loop

```
/yolo features --max-iterations 20
```

Loop:
1. /feature-list next
2. Neo implements
3. Run tests
4. Commit
5. Mark done
6. Continue

### HALT Conditions
- All features complete
- Max iterations reached
- 3 consecutive test failures
- User interrupt (Ctrl+C)

## Failure Philosophy

> "Failures are data, not stops."

ARGUMENTS: $ARGUMENTS
