---
description: Task Registry - manage cross-session tasks
---

# /task - Task Registry

> *"There is no spoon... but there is a backlog." — The Oracle*

## Purpose

Manage the cross-session task registry at `psi/memory/tasks/active.json`. Tasks persist across sessions so nothing falls through the cracks.

## Usage

- `/task` — List all active tasks (pending, in_progress, blocked)
- `/task add "description" [assignee]` — Add a new task
- `/task done <id>` — Complete a task
- `/task block <id> "reason"` — Mark a task as blocked
- `/task assign <id> <agent>` — Reassign a task
- `/task clear` — Archive all completed tasks

ARGUMENTS: $ARGUMENTS

## Steps

### List Tasks (`/task` with no args)

1. Read `psi/memory/tasks/active.json`
2. Display tasks grouped by status:
   - **Blocked** (show first — these need attention)
   - **In Progress**
   - **Pending**
3. Skip completed tasks (they're archived)
4. If no tasks, say so clearly

Output format:
```
## Task Registry — [count] active

### 🔴 Blocked
- [id] task description (assignee) — reason

### 🟡 In Progress
- [id] task description (assignee)

### ⚪ Pending
- [id] task description (assignee)
```

### Add Task (`/task add`)

1. Read current `psi/memory/tasks/active.json`
2. Generate ID: `task-NNNN` (increment from highest existing)
3. Add new task object:
   ```json
   {
     "id": "task-NNNN",
     "task": "Description from argument",
     "status": "pending",
     "assignee": "Argument or 'Oracle'",
     "created": "ISO timestamp",
     "updated": "ISO timestamp",
     "context": "Added via /task command"
   }
   ```
4. Update `lastUpdated` timestamp
5. Write back to file
6. Announce: `sh psi/matrix/voice.sh "Task registered. [description]" "Oracle"`

### Complete Task (`/task done`)

1. Find task by ID
2. Set `status` to `completed`, update timestamp
3. Write back
4. Announce completion

### Block Task (`/task block`)

1. Find task by ID
2. Set `status` to `blocked`, add `blockedReason` field
3. Update timestamp, write back
4. Announce: `sh psi/matrix/voice.sh "Task blocked. Needs attention." "Oracle"`

### Assign Task (`/task assign`)

1. Find task by ID
2. Update `assignee` field
3. Write back
4. Valid assignees: Oracle, Neo, Trinity, Morpheus, Architect, Smith, Tank, Scribe

### Clear Completed (`/task clear`)

1. Read active.json
2. Move all `completed` tasks to `psi/memory/tasks/archive/` with date prefix
3. Remove from active list
4. Write back

## Rules

- **Always read before write** — never clobber the file
- **Preserve existing tasks** — only modify the targeted task
- **Timestamps are ISO 8601** — always UTC
- **IDs are stable** — never reuse or renumber
