# ADR-019: Matrix Restructure & Parallel Safety

**Status**: Accepted
**Date**: 2026-03-18
**Deciders**: Jarkius + Oracle

## Context

The Oracle Construct grew organically through 17 evolution phases into 17 psi/ subdirectories, 83 flat hook scripts, duplicated command surfaces, and three agent spawning modes with no decision logic. Multiple agents editing the same codebase had no safety mechanisms — no file locking, no merge sequencing, no cross-worktree communication.

## Decision

### 1. Layered Modular Architecture
Reorganize into 5 dependency layers where lower layers never import from higher:
- L0: Identity (SOUL, BOOT, psi/source/)
- L1: State (psi/state/, psi/memory/, ~/.matrix/coordination/)
- L2: Services (lib/matrix-memory-agents/)
- L3: Automation (.claude/hooks/, .agent/workflows/)
- L4: Extensions (mcp/, agents, skills)

### 2. Folder Consolidation
- `psi/`: 17 dirs → 7 (source, state, memory, knowledge, swarm, projects, archive)
- `.claude/hooks/`: flat → 4 subdirs (core, pulse, voice, util)
- `.claude/commands/`: deleted (`.agent/workflows/` is canonical)
- New `docs/` for non-boot documentation
- New `mcp/` for external MCP servers

### 3. External Coordination Registry
`~/.matrix/coordination/` outside git for cross-worktree safety:
- `handshake.json` — master work plan (orchestrator writes, agents read)
- `agents/` — per-agent status files
- `locks/` — file ownership claims
- `messages/` — point-to-point JSON messages
- `results/` — task completion data

### 4. Composable Agent Model
Subagent, Agent Team, and Worktree are composable layers, not separate modes. Decision tree documented in `docs/multi-agent-protocol.md`.

### 5. Hybrid Repo Strategy
- Core (matrix-memory-agents) embedded at `lib/`
- Satellites (gemini-agent) at `mcp/`
- Distribution (seed, reloaded) published via `scripts/`

## Consequences

- All hook paths in settings.json must be updated
- All psi/ paths in CLAUDE.md, BOOT.md, agent definitions, hook scripts must be updated
- Extraction scripts for matrix-seed and matrix-reloaded must be updated
- `/orchestra` workflow deprecated in favor of Agent Teams

## References

- `docs/multi-agent-protocol.md` — full protocol specification
- Plan: `~/.claude/plans/compiled-exploring-wall.md`
