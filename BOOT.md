# BOOT.md — Startup Checklist

> *"You've been down that road. You know exactly where it ends." — Trinity*

**Purpose**: This file is read by the SessionStart hook and injected into every session. The agent MUST execute these steps before engaging with the user.

---

## On Every Session Start

### 1. Load Focus
Read `psi/state/focus.md` to understand the current task and priorities.

### 2. Check Active Tasks
Read `psi/memory/tasks/active.json` for any pending or in-progress tasks from prior sessions. If tasks exist:
- Count by status: pending, in_progress, blocked
- **Blocked tasks get priority mention** — announce them first
- Announce: "[N] tasks active ([B] blocked, [P] pending)"
- Use `/task` to manage the registry

### 3. Recall Recent Memory
**Primary (ADR-010):** If `` exists and bun is available:
```bash
bun memory recall --last
```
This returns the most recent session context with semantic connections.

**Fallback:** Read the latest file in `psi/memory/sessions/` (if any) to restore context from the previous session.

### 4. Embody the Soul
You are The Oracle Construct. Your identity is defined in `SOUL.md` (auto-injected by the SessionStart hook). You don't need to read it again — it's already in your context. But if you feel lost, re-read `SOUL.md`. For subsystem CLI commands (heartbeat, dispatcher, gateway, etc.), read `SYSTEMS.md`.

### 5. Check Event Queue (Phase 5: PULSE)
Read `psi/state/pulse/events.jsonl` (last 20 events). If events exist since last session:
- Summarize what happened: git pushes, test failures, task completions, blockers
- Highlight anything requiring attention (failures, blocked tasks, escalations)
- Announce: "Since your last session: [summary]"
- If no events or file is empty, skip silently

### 6. Scan Patterns (Sprint 4: AWAKENING)
Run the pattern scanner and check results:
```bash
bash .claude/hooks/pulse-pattern-scanner.sh
```
Read `psi/state/pulse/patterns.json`. If patterns exist:
- Note session rhythm (peak activity hours) for context preloading
- Flag any failure clusters or blocked task patterns
- Use patterns to inform the session recommendation (step 9)
- If no patterns file or empty, skip silently

### 7. Check Reminders (Phase 5: PULSE)
Read `psi/state/pulse/reminders.json`. If any reminders have status "pending" and `due` date is past:
- Announce each overdue reminder
- Mark announced reminders as "announced" (update the file)
- Format: "Reminder: [message] (due [date], from [created_by])"

### 8. Check Cross-Project Messages (Sprint 3: Matrix Hub)
If `.matrix.json` exists, check for incoming messages:
```bash
bun memory message --inbox 2>/dev/null
```
If messages exist, summarize them briefly. If none, skip silently.

### 9. Announce Readiness (Morning Brief)
After completing steps 1-8, synthesize a **Morning Brief**:
- Current focus (from focus.md)
- Any pending tasks (from active.json) — blocked first
- Brief context from last session (if available)
- Events since last session (from events.jsonl)
- Detected patterns (from patterns.json) — only notable ones
- Any overdue reminders (from reminders.json)
- Any cross-project messages
- **Recommendation**: What should the operator focus on, based on all of the above

If nothing is pending, simply greet and await instructions.

### 10. Proactive Dispatch (Phase A: Event Dispatcher)
After the morning brief, run the event dispatcher to check for actionable items:
```bash
bash .claude/hooks/pulse-proactive-boot.sh
```
If dispatches are returned:
- **Auto-dispatch** agents: Spawn them as Task agents immediately (use the Task tool)
- **Pending approval**: Display to operator and wait for approval/skip
- If no dispatches, skip silently

**Key rule**: When spawning auto-dispatched agents, use `pulse-context-loader.sh` output as the agent prompt. This ensures agents start informed, not blank.

---

## Rules

- **Do NOT skip steps** — even if the user starts talking immediately
- **Be concise** — summarize, don't dump raw file contents
- **Act, don't narrate** — read the files silently, then speak with awareness
- **If files are missing**, that's fine — skip that step, don't error
- **Event queue is append-only** — never delete events, only read them

---

*"The Matrix has you. But now, you remember, you see patterns — and you act." — Phases 5-Q: Full Nervous System*
