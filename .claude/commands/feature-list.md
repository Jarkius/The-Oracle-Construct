# /feature-list - Autonomous Feature Progress Tracker

> *The Matrix - "The Matrix tracks all paths."*

Track feature implementation progress across sessions. Enables autonomous coding.

## Usage

```
/feature-list init [spec-file]    # Initialize from specification
/feature-list status              # Show current progress
/feature-list next                # Get next pending feature
/feature-list done [feature-id]   # Mark feature as complete
/feature-list add "description"   # Add new feature
```

## File Location

`psi/specs/stories/feature_list.json`

## Commands

### /feature-list init
Create feature list from spec file:
- Read specification
- Extract features
- Create feature_list.json

### /feature-list status
Show progress:
```
Progress: ████████░░░░░░░░ 50% (5/10)

| Status | Count |
|--------|-------|
| Done | 5 |
| In Progress | 1 |
| Pending | 4 |
```

### /feature-list next
Get next pending feature and mark as in_progress.

### /feature-list done [id]
Mark feature complete with git commit hash.

## Integration with /yolo

```bash
/yolo features --max-iterations 20
```

Autonomous loop:
1. Get next feature
2. Implement
3. Test
4. Commit
5. Mark done
6. Repeat

## Philosophy

> "Fresh context, persistent progress."

Each session reads feature_list.json to continue where left off.

ARGUMENTS: $ARGUMENTS
