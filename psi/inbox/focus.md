# Current Focus

> *"What is the One task?"*

## Active Task

**Task**: Oracle Construct Self-Improvement — Legendary Infrastructure
**Status**: In Progress
**Updated**: 2026-02-17

## Context

All ADR-010 integration sprints (0-4) complete. System now self-improving. The Oracle Construct is nearly battle-ready for CIS Modernization — hooks, memory, agents, and intelligence layers all operational.

## Phase Coverage

| Phase | Status | Coverage |
|-------|--------|----------|
| Phase 5: PULSE | Done | Event queue, hooks, reminders |
| Phase 6: REMEMBRANCE | Done | SQLite + ChromaDB + CLAUDE.md wiring verified |
| Phase 7: SWARM | ~80% | Task routing + handoff protocol done; soul-aware teams pending (#24316) |
| Phase 8: AWAKENING | Done | Scanner + recommender + predictive loader + morning brief + evolution proposer |
| Phase 9: DAEMON | Sprint A+B Done | WEP-003/004/005 applied, matrix-services.sh, autostart config, morning brief health |
| Phase 10: HEARTBEAT | Done | Always-on daemon, 5 health checks, matrix-services.sh integration |
| Phase 10C: PERMISSIONS | Done | Agent permission declarations in frontmatter (all 8 agents) |
| Phase 12: AUTO-EVOLVE | Done | pulse-auto-evolve.sh, risk classification, kill switch |
| Phase 13: SELF-EVOLUTION | Tier 1 Done | Sandbox branching, 5 test gates, evolution log, sacred files |

## Completed

- [x] Fix 49 non-executable hooks (88% of pipeline was dead)
- [x] Install bun dependencies for matrix-memory-agents
- [x] WEP-001: Hook Permission Guard (applied — auto-heals on boot)
- [x] WEP-002: Agent Definition Quality Gate (proposed)
- [x] Rebuild Scribe agent (1.5/5 → 4.5/5)
- [x] Rebuild Neo agent (52 → 109 lines, code philosophy, CIS stack)
- [x] Phase 6.5: Verify CLAUDE.md recall wiring (confirmed semantic primary)
- [x] Phase 8.1: Pattern-to-Recommendation engine (6 rules, wired to boot)
- [x] Project context auto-loader (CONTEXT.md injection from psi/projects/)
- [x] Phase 7.5: Cross-agent handoff protocol (psi/swarm/handoffs/ + CLAUDE.md)
- [x] Phase 8.2: Predictive context loader (rhythm detection, context depth)
- [x] Phase 8.5: Morning brief synthesizer (unified intelligence at boot)
- [x] WEP-002: Upgrade Oracle (89→138 lines), Smith (51→112 lines), Architect (64→128 lines)
- [x] Phase 8.3: Evolution proposer (auto-drafts WEPs from patterns, wired to boot)
- [x] WEP-002 moved to applied (all agents at 4.5/5+)
- [x] Phase 9 Sprint A: WEP-003 (commit separation), WEP-004 (session IDs), WEP-005 (failure detection)
- [x] Phase 9 Sprint B: matrix-services.sh (daemon lifecycle), autostart config, morning brief health
- [x] Phase 10: Heartbeat daemon (heartbeat-daemon.ts, heartbeat.json, HEARTBEAT.md, ADR-012)
- [x] Phase 10C: Agent permission declarations (all 8 agents, CLAUDE.md section)
- [x] Phase 12: Auto-evolve script (pulse-auto-evolve.sh, risk classification, ADR-014)
- [x] Phase 13 Tier 1: Sandbox evolution (5 test gates, evolution-log.jsonl, sacred files, ADR-015)
- [x] Phase 14: Learning skills namespace (/learn:concept, :teach, :flash, :plan, :research, :course)

## Next Priority

### Phase 13: TRUE SELF-EVOLUTION (ADR-015 — Tier 1 Done)
- [x] Tier 1: Sandbox Evolution — branch → test gates → merge/rollback
- [x] Extend pulse-auto-evolve.sh with sandbox branching
- [x] Add 5 test gates (syntax, hooks, memory, services, custom)
- [x] Evolution log (evolution-log.jsonl) + sacred files exclusion
- [x] Wire to heartbeat as optional trigger (sandbox_evolution config)
- [ ] Tier 2: Intelligent Evolution (requires Phase 11 / Claude API)
- [ ] Tier 3: Cascading Evolution (after Tier 2 proven)

### Phase 11: GATEWAY — Messaging as UI (ADR-013 — Proposed)
- [ ] Telegram bot (grammY) → Agent Router → Claude API Bridge
- [ ] Security layer (allowlist, pairing, rate limiting, shell sandbox)
- [ ] Heartbeat → Gateway notification bridge
- [ ] Prerequisites: Telegram Bot Token, ANTHROPIC_API_KEY

### Phase 14: SKILLS ECOSYSTEM (New — Inspired by ClawHub/Awesome-Agent-Skills)
- [x] YouTube Player skill (yt-dlp + mpv)
- [x] Skill Creator meta-skill (bootstrap new skills)
- [x] Learning skills namespace (/learn:*)
  - [x] /learn:concept — Deep-dive structured learning
  - [x] /learn:teach — Feynman technique explanations
  - [x] /learn:flash — Flashcard generator (Anki-compatible)
  - [x] /learn:plan — Study planner with tracking
  - [x] /learn:research — Multi-source parallel deep research
  - [x] /learn:course — Course/tutorial progress tracker
- [ ] Browser Stealth skill (enhance Morpheus anti-detection)
- [ ] File Organizer skill
- [ ] Finance Monitor skill (Yahoo Finance)
- [ ] Google Workspace skill (Gmail/Calendar/Drive)
- [ ] MCP Builder skill
- [ ] Changelog Generator skill

### Remaining Infrastructure
- [ ] Agent Teams: Blocked on Issue #24316
- [ ] Phase 9 Sprint C (optional): Event processor daemon

### Ready to Start
- [ ] CIS Modernization: Resume React SPA + Laravel API development

---

*Updated by Oracle - 2026-02-18 (Phase 13 + 11 planned, Phase 14 Skills Ecosystem started)*
