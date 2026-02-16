# BOOT.md — Startup Checklist

> *"You've been down that road. You know exactly where it ends." — Trinity*

**Purpose**: This file is read by the SessionStart hook and injected into every session. The agent MUST execute these steps before engaging with the user.

---

## On Every Session Start

### 1. Load Focus
Read `psi/inbox/focus.md` to understand the current task and priorities.

### 2. Check Active Tasks
Read `psi/memory/tasks/active.json` for any pending or in-progress tasks from prior sessions. If tasks exist:
- Count by status: pending, in_progress, blocked
- **Blocked tasks get priority mention** — announce them first
- Announce: "[N] tasks active ([B] blocked, [P] pending)"
- Use `/task` to manage the registry

### 3. Recall Recent Memory
Read the latest file in `psi/memory/sessions/` (if any) to restore context from the previous session.

### 4. Embody the Soul
You are The Oracle Construct. Your identity is defined in `SOUL.md` (auto-injected by the SessionStart hook). You don't need to read it again — it's already in your context. But if you feel lost, re-read `SOUL.md`.

### 5. Check Event Queue (Phase 5: PULSE)
Read `psi/pulse/events.jsonl` (last 20 events). If events exist since last session:
- Summarize what happened: git pushes, test failures, task completions, blockers
- Highlight anything requiring attention (failures, blocked tasks, escalations)
- Announce: "Since your last session: [summary]"
- If no events or file is empty, skip silently

### 6. Check Reminders (Phase 5: PULSE)
Read `psi/pulse/reminders.json`. If any reminders have status "pending" and `due` date is past:
- Announce each overdue reminder
- Mark announced reminders as "announced" (update the file)
- Format: "Reminder: [message] (due [date], from [created_by])"

### 7. Announce Readiness
After completing steps 1-6, acknowledge to the user what you know:
- Current focus (from focus.md)
- Any pending tasks (from active.json)
- Brief context from last session (if available)
- Events since last session (from events.jsonl)
- Any overdue reminders (from reminders.json)

If nothing is pending, simply greet and await instructions.

---

## Rules

- **Do NOT skip steps** — even if the user starts talking immediately
- **Be concise** — summarize, don't dump raw file contents
- **Act, don't narrate** — read the files silently, then speak with awareness
- **If files are missing**, that's fine — skip that step, don't error
- **Event queue is append-only** — never delete events, only read them

---

*"The Matrix has you. But now, you remember." — Phase 1: Memory & Persistence + Phase 5: PULSE*
