---
description: Context Compaction - compress session into structured summary
---

# /compact - Context Compaction

> *"Free your mind." — Morpheus*

## Purpose

When a session grows long and context bloats, `/compact` distills everything into a structured checkpoint. This preserves critical decisions while freeing working memory.

## Usage

- `/compact` — Generate a session summary and optionally save it
- `/compact save` — Generate and auto-save to `psi/memory/sessions/`

ARGUMENTS: $ARGUMENTS

## Steps

### 1. Analyze Current Session

Silently review the conversation so far. Extract:

- **Decisions Made** — What was decided? Architecture choices, naming, approach selections.
- **Open TODOs** — What remains undone? Be specific with file paths and line numbers.
- **Open Questions** — What's unresolved? What needs the Operator's input?
- **Constraints Discovered** — What limitations did we find? API limits, tech debt, blockers.
- **Files Modified** — List every file touched with a one-line summary of changes.
- **Context for Continuation** — What would a fresh session need to know to pick up here?

### 2. Generate Compact Output

```markdown
## Session Compact — [YYYY-MM-DD HH:MM]

### Decisions Made
- [decision 1]
- [decision 2]

### Open TODOs
- [ ] [todo with file:line reference]
- [ ] [todo with file:line reference]

### Open Questions
- [question needing human input]

### Constraints Discovered
- [constraint or blocker]

### Files Modified
| File | Change |
|------|--------|
| `path/to/file` | Brief description |

### Context for Continuation
> [2-3 sentences a fresh session needs to continue this work]
```

### 3. Save (if `/compact save`)

1. Generate filename: `psi/memory/sessions/YYYY-MM/YYYY-MM-DD_HH.MM_compact.md`
2. Write the compact output with session memory header
3. Announce: `sh psi/matrix/voice.sh "Session compacted. Context preserved." "Oracle"`

### 4. Display

Always display the compact to the Operator, even if saving.

## Rules

- **Be ruthless** — only preserve what matters for continuation. No fluff.
- **File paths are mandatory** — vague references like "the auth module" are useless. Say `src/auth/sanctum.php:42`.
- **Decisions need rationale** — "chose X" is incomplete. "Chose X because Y" is useful.
- **Don't fabricate** — if you're unsure about something, mark it as an open question.
