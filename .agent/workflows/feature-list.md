---
description: Autonomous feature progress tracking across sessions
---

# /feature-list - Autonomous Feature Progress Tracker

> "The Matrix tracks all paths. Every feature, every commit, every step toward completion."

## Purpose

Track feature implementation progress across sessions. Enables autonomous coding by maintaining state in `feature_list.json` - the source of truth that persists beyond context windows.

## Usage

```
/feature-list init [spec-file]    # Initialize from specification
/feature-list status              # Show current progress
/feature-list next                # Get next pending feature
/feature-list done [feature-id]   # Mark feature as complete
/feature-list add "description"   # Add new feature
/feature-list reset               # Reset all to pending (careful!)
```

## The Feature List File

**Location**: `psi/specs/stories/feature_list.json`

```json
{
  "project": "Project Name",
  "created": "2026-01-08",
  "updated": "2026-01-08",
  "total": 10,
  "completed": 3,
  "features": [
    {
      "id": 1,
      "name": "User authentication",
      "description": "Login/logout with session management",
      "status": "done",
      "commit": "abc1234",
      "completed_at": "2026-01-08T10:30:00Z"
    },
    {
      "id": 2,
      "name": "Dashboard layout",
      "description": "Main dashboard with sidebar navigation",
      "status": "in_progress",
      "started_at": "2026-01-08T11:00:00Z"
    },
    {
      "id": 3,
      "name": "User list page",
      "description": "Display all users with search/filter",
      "status": "pending"
    }
  ]
}
```

## Workflow

<workflow>

<step n="1" goal="Initialize or Load">
  <action>Check if `psi/specs/stories/feature_list.json` exists</action>

  <check if="file exists">
    <action>Load existing feature list</action>
    <action>Report current progress</action>
  </check>

  <check if="file does not exist AND spec-file provided">
    <action>Read specification file</action>
    <action>Extract features from spec</action>
    <action>Create feature_list.json</action>
  </check>

  <check if="file does not exist AND no spec-file">
    <ask>No feature list found. Provide a spec file or create manually?</ask>
  </check>
</step>

<step n="2" goal="Show Status">
  <action>Calculate completion percentage</action>
  <action>Display progress bar</action>

  ```markdown
  ## Feature Progress: [Project Name]

  Progress: ████████░░░░░░░░ 50% (5/10)

  | Status | Count |
  |--------|-------|
  | Done | 5 |
  | In Progress | 1 |
  | Pending | 4 |

  ### In Progress
  - [2] Dashboard layout (started 2h ago)

  ### Next Up
  - [3] User list page
  - [4] Settings panel
  ```
</step>

<step n="3" goal="Get Next Feature">
  <action>Find first feature with status "pending"</action>
  <action>Mark it as "in_progress"</action>
  <action>Update started_at timestamp</action>
  <action>Save feature_list.json</action>

  <output>
  ```markdown
  ## Next Feature: #3 - User list page

  **Description**: Display all users with search/filter

  ### Acceptance Criteria
  - [ ] List displays all users
  - [ ] Search by name/email works
  - [ ] Filter by role works
  - [ ] Pagination for large lists

  Ready for Neo to implement.
  ```
  </output>
</step>

<step n="4" goal="Mark Done">
  <action>Find feature by ID</action>
  <action>Set status to "done"</action>
  <action>Get latest git commit hash</action>
  <action>Set commit field</action>
  <action>Set completed_at timestamp</action>
  <action>Update total completed count</action>
  <action>Save feature_list.json</action>

  <output>
  ```markdown
  ## Feature #3 Complete!

  **Name**: User list page
  **Commit**: def5678
  **Duration**: 45 minutes

  Progress: █████████░░░░░░░ 60% (6/10)

  Next: #4 - Settings panel
  ```
  </output>
</step>

</workflow>

## Integration with /yolo

When `/yolo` mode is active with feature-list:

```markdown
## Autonomous Feature Loop

1. /feature-list next       # Get next feature
2. Neo implements feature   # Code it
3. Run tests               # Verify
4. git commit              # Save progress
5. /feature-list done [id] # Mark complete
6. Wait 3 seconds          # Brief pause
7. GOTO 1                  # Continue

## HALT Conditions
- All features complete
- Max iterations reached
- Test failures
- User interrupt (Ctrl+C)
```

## Agent Integration

| Command | Agent | Action |
|---------|-------|--------|
| `/feature-list init` | Architect | Create from spec |
| `/feature-list next` | Neo | Start implementation |
| `/feature-list done` | Neo | After commit |
| `/feature-list status` | Any | Progress check |

## Auto-Trigger When User Says:
- "what's next" → `/feature-list next`
- "mark done" → `/feature-list done`
- "show progress" → `/feature-list status`
- "create feature list from" → `/feature-list init`

## File Locations

```
psi/specs/stories/
├── feature_list.json     # Source of truth
├── feature_list.bak      # Auto-backup before changes
└── archive/
    └── feature_list_[date].json  # Historical snapshots
```

## Philosophy

> "Fresh context, persistent progress."

Each session reads `feature_list.json` to know where to continue. No context bloat. No lost progress. The Matrix remembers.

ARGUMENTS: $ARGUMENTS
