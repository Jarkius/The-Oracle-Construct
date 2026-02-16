# Current Focus

> *"What is the One task?"*

## Active Task

**Task**: Integrate matrix-memory-agents — The REMEMBRANCE Shortcut (ADR-010)
**Status**: In Progress
**Updated**: 2026-02-16

## Context

Phases 1-5 complete. Instead of building Phases 6-8 from scratch, integrating `matrix-memory-agents` (our own repo) as a git subtree. This gives us SQLite + ChromaDB semantic search, knowledge graphs, self-evolving learnings, and cross-project messaging — replacing ADR-009 Phases 6.1-6.4, 7.1-7.4, and 8.4 in one move. Direct integration (not MCP) keeps zero-daemon philosophy intact.

## Completed

- [x] Phase 1.1: Auto-Session Memory Hook
- [x] Phase 1.2: BOOT.md Startup Checklist
- [x] Phase 1.3: Mandatory Memory Recall Protocol
- [x] Phase 3.1: SOUL.md Structural Personality Injection
- [x] Phase 3.3: Action-First Default Behavior
- [x] Phase 2.3: Focus-Driven Context Injection (enhanced)
- [x] Phase 3.4: Operator Profile (USER.md) + Voice Calibration + Quality Self-Checks
- [x] Phase 3.2: Agent-Specific Skill Gating (/team, skill matrix in CLAUDE.md)
- [x] Phase 2.2: Task Registry Enhancement (/task command)
- [x] Phase 4.1: Context Compaction (/compact command)
- [x] Phase 4.5: Agent Teams Integration (experimental flag, /team, TeammateIdle/TaskCompleted hooks)
- [x] Phase 5.1: Async Hook Pipeline (PostToolUse, Stop, PreCompact)
- [x] Phase 5.2: Event Queue System (events.jsonl + handlers.json)
- [x] Phase 5.3: Enhanced BOOT.md (event-aware startup, steps 5-7)
- [x] Phase 5.4: Scheduled Reminders (reminders.json + boot check)
- [x] ADR-009: Next Evolution Phases 5-8 documented

## Next (ADR-010 Integration Sprints)

- [x] Sprint 0: Git subtree add + setup script + bootstrap from existing psi/
- [x] Sprint 1: Wire Pulse hooks → `bun memory` (save, learn, distill)
- [x] Sprint 2: Replace CLAUDE.md recall protocol with semantic search
- [ ] Sprint 3: Agent coordination (Council ↔ Oracle router, task sync, Matrix Hub)
- [ ] Sprint 4: Matrix-specific intelligence (patterns, predictions, morning brief)
- [ ] Agent Teams: Wait for Issue #24316 (`.claude/agents/` as teammates)
- [ ] CIS Modernization: Resume active development

---

*Updated by Oracle - 2026-02-16 (ADR-010 pivot)*
