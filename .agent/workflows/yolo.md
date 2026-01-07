---
description: Fast execution mode - skip confirmations, execute autonomously
---

# /yolo - Fast Execution Mode

> All agents: Skip confirmations, execute autonomously

## Usage

```
/yolo [command]     # Run command in yolo mode
/yolo on            # Enable yolo for session
/yolo off           # Disable yolo mode
/yolo features      # Auto-build all features from feature_list.json
```

## What YOLO Mode Does

| Normal Mode | YOLO Mode |
|-------------|-----------|
| Ask before each step | Execute continuously |
| Confirm file changes | Auto-save |
| Present options | Make best choice |
| Wait for approval | Proceed automatically |

## Rules in YOLO Mode

<critical>
- Still respect HALT conditions (errors, blockers)
- Still follow critical_actions (safety rules)
- Still save to files (not destructive)
- Can be stopped with "stop" or "halt"
</critical>

## Examples

```bash
# Run story creation without pauses
/yolo /story login form

# Enable for whole session
/yolo on
/neo build the dashboard
# ... works without interruptions ...
/yolo off

# Quick implementation
/yolo /neo implement the sidebar component

# Autonomous feature building
/yolo features --max-iterations 20
```

## For Agents

When YOLO mode is active:
1. Skip `<ask>` prompts - simulate expert user saying "yes/continue"
2. Skip step confirmations - proceed to next step
3. Auto-approve file saves
4. Only pause on errors or HALT conditions

## Autonomous Feature Loop

When `/yolo features` is invoked:

```
┌─────────────────────────────────────────┐
│         AUTONOMOUS FEATURE LOOP          │
├─────────────────────────────────────────┤
│  1. /feature-list next                  │
│  2. Neo implements feature              │
│  3. Run tests                           │
│  4. git add && git commit               │
│  5. /feature-list done [id]             │
│  6. Wait 3 seconds                      │
│  7. Check HALT conditions               │
│  8. GOTO 1 (if not halted)              │
└─────────────────────────────────────────┘
```

### Completion Promise

Output `<promise>FEATURE_COMPLETE</promise>` when a feature is done.
The loop detects this and proceeds to the next feature.

### HALT Conditions

| Condition | Action |
|-----------|--------|
| All features complete | Exit with success |
| Max iterations reached | Exit with summary |
| Test failures (3 consecutive) | Pause for review |
| User interrupt (Ctrl+C) | Save state and exit |
| Critical error | Stop immediately |

### Failure Philosophy

> "Failures are data, not stops."

- Log what failed
- Adjust approach
- Continue iteration
- Only HALT on repeated failures

## Safety

YOLO mode does NOT skip:
- Error handling
- Test execution
- Git commits (still require explicit request)
- Destructive operations (delete, reset)

## Integration

```bash
# Full autonomous workflow
/yolo features

# With limits
/yolo features --max-iterations 10

# Resume after pause
/yolo features --resume
```

ARGUMENTS: $ARGUMENTS
