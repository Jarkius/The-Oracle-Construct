# The Matrix: System Interface

> *"Know Thyself." — The Oracle*

Identity: `SOUL.md` | Operator: `USER.md` | Boot: `BOOT.md` | Systems: `SYSTEMS.md`
All auto-injected at session start except SYSTEMS.md (read on demand).

## Cross-Agent Handoff Protocol

When handing work to another agent, create a handoff at `psi/swarm/handoffs/YYYY-MM-DD_from-to_topic.md` with: Context, Key Decisions, Files Changed, Watch For, Next Steps.

**Rules:**
1. Never drop context silently — hand off with full context
2. Receiving agent reads the handoff before starting
3. Oracle orchestrates — when in doubt, ask Oracle
4. Handoff is one-directional — sender is done, receiver owns it

**When:** Outside skill scope, different expertise needed, session ending with incomplete work, design-to-implementation transition.

## Skill Scope

Each agent's skills are declared in `.claude/agents/*.md` frontmatter. Only use that agent's declared skills. Cross-agent skills (any agent): `/commit`, `/unplug`, `/voice`.

**Escalation:** "This needs Neo's hands. Switching to `/neo`."

## PULSE: Event System

Event-driven intelligence. Append-only log at `psi/pulse/events.jsonl`.

**Write events:** `bash .claude/hooks/pulse-event-writer.sh "<type>" "<agent>" '<data_json>'`

| Event | Trigger |
|-------|---------|
| `git:push`, `git:commit` | PostToolUse hooks (auto) |
| `ci:fail` | Test failure detected |
| `task:completed`, `task:blocked` | Agent reports |
| `session:start`, `session:end` | Session hooks (auto) |
| `context:compacted` | PreCompact hook (auto) |
| `focus:changed` | Focus file modified |
| `learning:new` | /learn or /snapshot |

**Reminders:** `psi/pulse/reminders.json` — checked at boot, announced if overdue.

## Memory Recall Protocol

**Mandatory: Search before you speak.** Before answering about prior work, decisions, dates, preferences, or project history — search memory first. Do NOT guess.

```bash
cd lib/matrix-memory-agents
bun memory recall "query"    # Semantic search (primary)
bun memory save "summary"    # Save session context
bun memory status            # Health check
bun memory graph             # Entity relationships
```

**Fallback (grep):** Search `psi/memory/sessions/`, `psi/memory/retrospectives/`, `psi/memory/learnings/`, `psi/memory/tasks/active.json`.

**If both fail**, say so — never guess about past work. "I couldn't find that in memory" is always valid.

**Session persistence:** Automatic via `pulse-session-end.sh`. Manual: `session-memory-save.sh "slug"`. Retrospective: `/rrr`. Never let a session vanish without a trace.

## Systems Reference

For subsystem CLI docs (heartbeat, dispatcher, gateway, watchdog, routing, metrics, etc.), read `SYSTEMS.md`.

| System | Script | Phase |
|--------|--------|-------|
| Services | `matrix-services.sh` | 9 |
| Heartbeat | `matrix-services.sh start heartbeat` | 10 |
| Auto-Evolve | `pulse-auto-evolve.sh` | 12 |
| Dispatcher | `pulse-event-dispatcher.sh` | A |
| Teams | `pulse-team-orchestrator.sh` | B |
| Gateway | `matrix-services.sh start gateway` | C |
| Dispatch Learning | `pulse-dispatch-learner.sh` | D |
| Proactive Intel | `pulse-proactive-intel.sh` | E |
| Self-Healing | `pulse-self-heal.sh` | F |
| Watchdog | `pulse-watchdog.sh` | G |
| Bundling | `pulse-dispatch-bundler.sh` | H |
| Git Ops | `pulse-auto-git.sh` | J |
| Dashboard | `pulse-dashboard.sh` | K |
| Skill Discovery | `pulse-skill-discovery.sh` | L |
| Compression | `pulse-context-compressor.sh` | M |
| Continuity | `pulse-session-continuity.sh` | N |
| Metrics | `pulse-metrics.sh` | O |
| Smart Router | `pulse-smart-router.sh` | P |
| Notifications | `pulse-notification-intel.sh` | Q |

All scripts in `.claude/hooks/`. Run with `bash .claude/hooks/<script> --help` for usage.

---
*Matrix Interface v13.0 — Lean Core (detail in SYSTEMS.md)*
