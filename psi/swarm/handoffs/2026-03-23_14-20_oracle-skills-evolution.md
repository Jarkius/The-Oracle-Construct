# Handoff: Oracle Skills Evolution — Adopt oracle-skills-cli Patterns

**Date**: 2026-03-23 14:20 GMT+7
**From**: Oracle → Neo (next session)
**Source**: `/learn` of `Soul-Brews-Studio/oracle-skills-cli` (v3.3.0-alpha.10)

## Context

The Matrix and oracle-skills-cli share the same creator (Nat/Jarkius). oracle-skills-cli is the distribution layer — it installs skills across 18 AI agents. The Matrix is the runtime — orchestration, memory, voice, agents. Time to bring the distribution patterns home.

## Patterns to Adopt

### 1. Command Stub Compiler (Priority 1)
**What**: Auto-generate `.claude/commands/*.md` from `.claude/skills/*/SKILL.md`
**Why**: We hand-maintain 43 command loader stubs. oracle-skills-cli compiles them automatically.
**How**: Build `scripts/compile-commands.ts` that:
- Reads each `SKILL.md` frontmatter (description, argument-hint)
- Generates command stub `.md` with Skill tool reference
- Injects version from `package.json`
- Run on `postinstall` or as `/compile` skill

**Reference**: `oracle-skills-cli/scripts/compile.ts`

### 2. Version Injection (Priority 2)
**What**: Inject `v{version} M-SKLL |` prefix into every skill description
**Why**: Users can't tell if skills are stale. oracle-skills-cli shows version in autocomplete.
**How**:
- Add `installer: the-matrix` marker to all SKILL.md frontmatter
- Inject version prefix during compilation
- `M-SKLL` = Matrix Skill (vs `G-SKLL` = Global Skill from oracle-skills-cli)

**Reference**: `oracle-skills-cli/src/cli/installer.ts` lines for version injection

### 3. Profile System (Priority 3)
**What**: Tiered skill loading — `minimal` (core 8), `standard` (daily 15), `full` (all 43)
**Why**: Loading 43 skills bloats session context. Most sessions use <10.
**How**: Create `src/profiles.ts` with include/exclude arrays:
```typescript
profiles = {
  minimal: { include: ['recap', 'rrr', 'forward', 'commit', 'oracle', 'neo', 'task', 'now'] },
  standard: { include: [...minimal, 'learn', 'trace', 'smith', 'architect', 'tank', 'health', 'standup'] },
  full: {} // everything
}
```
**Reference**: `oracle-skills-cli/src/profiles.ts`

### 4. Installer Marker (Priority 4)
**What**: Add `installer: the-matrix` to all our SKILL.md frontmatter
**Why**: Distinguishes Matrix-native skills from oracle-skills-cli installed ones
**How**: Batch update all 43 SKILL.md files + add to compiler template

### 5. Feature Stacking (Priority 5)
**What**: `/go +voice`, `/go +research`, `/go +debug` to add feature modules
**Why**: Composable skill sets without loading everything
**How**: Define feature groups matching our agent domains:
```typescript
features = {
  voice: ['voice', 'speak'],
  research: ['deep-research', 'learn', 'watch', 'gemini'],
  debug: ['smith', 'patrol', 'health', 'fix'],
  design: ['trinity', 'component-spec', 'design-review', 'frontend-design'],
}
```

## Implementation Order

```
Session N+1 (Next):
  1. Build compile-commands.ts (auto-generate 43 command stubs)
  2. Add version injection + installer markers
  3. Test: delete all .claude/commands/*.md, run compiler, verify

Session N+2:
  4. Build profile system (profiles.ts)
  5. Create /go skill for profile switching
  6. Test minimal vs standard vs full

Session N+3:
  7. Feature stacking
  8. Cross-repo sync (skills that exist in both repos)
```

## Key Files from oracle-skills-cli

| File | Pattern | Our Equivalent |
|------|---------|---------------|
| `scripts/compile.ts` | Command stub compiler | Build `scripts/compile-commands.ts` |
| `src/profiles.ts` | Profile tiers | Build `src/profiles.ts` |
| `src/cli/installer.ts` | Version injection | Add to compiler |
| `src/cli/skill-source.ts` | VFS abstraction | Not needed (we're single-agent) |
| `src/cli/agents.ts` | Multi-agent registry | Not needed (Claude Code only) |

## Learning Docs

Exploration output at: `psi/learn/Soul-Brews-Studio/oracle-skills-cli/2026-03-23/`
- Architecture analysis (from agent)
- Code snippets (key implementations)
- Quick reference + comparison table

## What NOT to Adopt

- **Multi-agent installer**: We only target Claude Code
- **VFS abstraction**: We don't compile to binary
- **OpenCode plugin**: Not relevant
- **bunx distribution**: We're a repo, not a package

## Session Stats (Current)

- 18 commits, 28+ files changed, ~1,000 lines added
- Cascading bootstrap failure fixed
- Full Piper TTS on Windows (10 voices + effects)
- Recall pipeline fixed (recap reads correct paths)
- Adaptive System voice with KITT pulse
- oracle-skills-cli learned and compared
