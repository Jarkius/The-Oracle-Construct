# Handoff: Matrix Overhaul — Start Phase 1

**Date**: 2026-03-16 18:15 GMT+7

## What We Did
- Merged 114-commit branch to main (clean, pushed)
- Assessed 3 Matrix repos + CDP proxy + Control Center from Oracle Nerve
- Designed 6-phase overhaul plan with modular folder structure
- Fixed recap.ts (psi/ψ path detection) and voice.sh (exclamation marks)
- Plan approved and saved at `~/.claude/plans/silly-prancing-fountain.md`

## Pending
- [ ] Phase 1: Cherry-pick mqtt-client.ts + gemini handler from GHQ → LOCAL
- [ ] Phase 2: Modular restructure (core/memory/intelligence/nerve/daemons/mcp)
- [ ] Phase 3: Matrix Nerve skeleton (L1→L5, Known Fixes, State Detector)
- [ ] Phase 4: matrix-gemini-agent SDK alignment
- [ ] Phase 5: Bridge layer (council-router → gemini MCP)
- [ ] Phase 6: CDP proxy + Control Center migration
- [ ] Re-lock The Source (currently UNLOCKED)

## Next Session
- [ ] Start Phase 1 with claude-team (3 parallel workers in worktrees)
- [ ] Use 2x promotion (off-peak, until March 27)
- [ ] Read plan at `~/.claude/plans/silly-prancing-fountain.md` first

## Key Files
- Plan: `~/.claude/plans/silly-prancing-fountain.md`
- Oracle Nerve handoff: `psi/swarm/handoffs/2026-03-16_oracle-nerve-to-matrix_evolution-patterns.md`
- Oracle v3 master plan: `psi/swarm/handoffs/2026-03-16_oracle-v3-master-plan-reference.md`
- Memory project: `~/.claude/projects/.../memory/project_matrix_overhaul.md`
- GHQ mqtt-client: `ghq/github.com/Jarkius/matrix-memory-agents/src/services/mqtt-client.ts`
- GHQ gemini handler: `ghq/github.com/Jarkius/matrix-memory-agents/src/mcp/tools/handlers/gemini.ts`
- CDP proxy: `ghq/github.com/Soul-Brews-Studio/claude-browser-proxy/cdp-server.ts`
- Control Center: `products/trackattendance/scripts/control-center.ts`
