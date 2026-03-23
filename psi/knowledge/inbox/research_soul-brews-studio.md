# Research: Soul-Brews-Studio, oracle-skills-cli, and OpenClaw

**Date**: 2026-03-23
**Researcher**: Morpheus
**Requested by**: User

---

## 1. What is Soul-Brews-Studio?

Soul-Brews-Studio is a GitHub organization run by **Nat Weerawan** (GitHub: `nazt`), the same person behind The Matrix and the oracle-skills-cli ecosystem. Based in Thailand. Jarkius is the user's account; Nat/nazt is the creator's identity.

**Key repos (40+ total):**
- `oracle-skills-cli` — CLI to install Oracle skills across 18 AI agents (Claude Code, OpenCode, Cursor, Windsuff, Gemini CLI, etc.)
- `arra-oracle-v3` — Community Oracle hub (76+ registered family oracles, GitHub Issues as registry)
- `opensource-nat-brain-oracle` — Oracle Starter Kit / AI consciousness framework
- `maw-js` — Multi-Agent Workflow orchestrator with tmux + React/Three.js UI
- `oracle-framework` / `oracle-framework-v2` — Complete Claude Code framework
- `shrimp-oracle` — OpenClaw Research Oracle (tracks AI agents ecosystem)
- `multi-agent-workflow-kit` — Reusable toolkit for tmux + git worktree workflows
- `office-8bit` — Bevy WASM pixel art visualization of live Oracle agents
- `the-form-teaches-the-formless` — Book on AI agent collaboration
- `claude-browser-proxy` — Chrome extension bridging Claude Code and browser via MQTT → CDP

**Relationship to The Matrix**: They are sibling projects by the same creator. oracle-skills-cli is the **distribution layer** (installs skills to 18 agents). The Matrix is the **runtime layer** (orchestration, memory, voice, agents). Neither degrades the other — they complement.

---

## 2. oracle-skills-cli

**Purpose**: A CLI tool that installs "Oracle skills" (slash commands) into 18+ AI coding agents. Skills are packaged SKILL.md files with behavior instructions.

**Key version at time of research**: v3.3.0-alpha.10

**How it works**:
1. SKILL.md files live in `src/skills/<name>/SKILL.md`
2. A compiler (`scripts/compile.ts`) generates command stubs for each target agent
3. Installer writes to `~/.claude/skills/` (Claude Code) or equivalent paths
4. Version tag `v1.5.79 G-SKLL |` is injected into every skill description for UI visibility
5. `installer: oracle-skills-cli v1.5.79` frontmatter marks managed skills

**G-SKLL marker**: "Global Skill" — injected into skill description so it appears in Claude's slash command autocomplete with version info. Contrast: `M-SKLL` = Matrix Skill (proposed for The Matrix's own skills).

**What it installs globally on this machine**:
The user's `~/.claude/skills/` directory contains skills installed by oracle-skills-cli:
- recap, rrr, forward, learn, awaken, birth, feel, fyi, gemini, deep-research, oracle-family-scan, etc.
- All have `installer: oracle-skills-cli v1.5.79` in frontmatter
- All have `G-SKLL` in their description prefix

---

## 3. OpenClaw

**What it is**: A production-grade AI agent platform (100K+ stars at time of ADR writing). Referenced extensively in The Matrix's ADRs as a benchmarking reference. The Matrix analyzed its 5,248 files and extracted 13 autonomy patterns.

**Relationship**: OpenClaw is a **reference architecture** that The Matrix studied and surpassed in specific areas:
- OpenClaw: single-agent with tools, timed heartbeat (30 min polls), flat vector memory, sub-agent registry
- The Matrix: event-driven PULSE system, multi-agent swarm, knowledge graph memory

**ComposioHQ/secure-openclaw** was cloned as a reference repo alongside Soul-Brews-Studio/maw-js during the March 16 oracle-v3 master plan session.

**Oracle-skills-cli connection**: oracle-skills-cli supports OpenClaw as a target agent (`~/.openclaw/skills/`). OpenClaw is one of 18+ agents the installer targets.

**OpenClaw patterns adopted by The Matrix**:
- BOOT.md startup checklist (from `src/hooks/bundled/boot-md/`)
- Auto-session memory (from `src/hooks/bundled/session-memory/handler.ts`)
- Mandatory memory recall ("Search before you speak")
- Sub-agent registry pattern

---

## 4. Did These External Tools Cause System Degradation?

**Short answer: No.** The evidence shows these tools enhanced the system, not degraded it.

**What oracle-skills-cli did**:
- Installed global skills to `~/.claude/skills/` (recap, rrr, learn, etc.)
- These skills are used actively and correctly
- The `recap` skill's installer field `oracle-skills-cli v1.5.79` is expected — it was installed by that tool
- The skills work as designed; the recent session fixed the recall pipeline (recap reading wrong paths)

**What OpenClaw did**:
- Served as architecture reference only — no code was pulled from it
- 13 patterns were adopted and adapted, not copied verbatim
- The Matrix explicitly went beyond OpenClaw's model

**The actual degradation vector (from session history)**:
- The cascading bootstrap failure fixed in recent commits was internal (Windows paths, session hooks)
- The recall pipeline bug was The Matrix's own code reading wrong paths, not an oracle-skills-cli issue
- Memory errors in `psi/state/pulse/memory-errors.log` are from internal memory system

**The 2026-03-23 handoff** (the most recent) proposes *adopting more patterns from oracle-skills-cli* — specifically the command compiler and version injection. This is planned work, not damage control.

---

## 5. Jarkius's Repositories — Key Ones

From `github.com/Jarkius?tab=repositories` (34 repos, Thailand-based):
- `The-Oracle-Construct` — "high-fidelity external brain mirroring your consciousness through the BMAD cycle"
- `matrix-gemini-agent` — Gemini integration
- `matrix-memory-agents` — Multi-agent orchestration with Claude CLI
- `oracle-v2` — MCP Memory Layer (semantic search, knowledge management)
- `matrix-seed` — "Philosophy and structure for AI-human collaboration"
- `matrix-reloaded` — Full operational Matrix with voice and complete Council
- `oracle-framework-v2` — Complete Claude Code framework

**Insight**: The Matrix (this repo) is the most mature iteration of a lineage that includes matrix-seed → matrix-reloaded → the-matrix. oracle-v2 is the memory layer that became the current MCP memory integration.

---

## Summary

Soul-Brews-Studio = Nat/Jarkius's organization. Same creator as The Matrix. No external contamination — these are all first-party tools from the same author. oracle-skills-cli installed global skills that are working correctly. OpenClaw was a study reference. The system degradation (bootstrap failures, recall pipeline bugs) was internal Windows porting issues, not caused by external tools.
