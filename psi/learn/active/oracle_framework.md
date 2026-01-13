# Research: Oracle Framework Advanced

> Researched by: Morpheus
> Date: 2025-01-09
> Source: https://github.com/Soul-Brews-Studio/oracle-framework-advanced

## Executive Summary

The Oracle Framework Advanced is a **sibling philosophy** to our Matrix system. Same DNA, different evolution. Key insight: **they formalized subagent patterns we're still discovering**.

---

## Key Discoveries

### 1. Formalized Subagent Roles

| Agent | Model | Purpose | Our Equivalent |
|-------|-------|---------|----------------|
| `context-finder` | Haiku | Fast search git/files | Tank |
| `oracle-keeper` | Opus | Mission alignment | Oracle |
| `security-scanner` | Haiku | Secret detection | Smith |
| `repo-auditor` | Haiku | File health check | Smith |
| `coder` | Opus | Write code from specs | Neo |
| `executor` | Haiku | Run bash commands | Tank |

### 2. Delegation Pattern (Critical)

```
Main Agent (Opus)
    ├── Dispatch to Haiku (bulk work)
    ├── Haiku returns summary
    └── Main reviews + approves
```

**Anti-pattern**: Subagent writes, main just commits
**Correct**: Subagent gathers data, main writes everything

> This validates our ADR-001: Haiku gathers, Opus synthesizes.

### 3. ψ/ Structure (7 Pillars vs Our 5+)

| Their Pillar | Purpose | Our Equivalent |
|--------------|---------|----------------|
| `active/` | Research in progress (gitignored) | `psi/active/` |
| `inbox/` | Communication, focus.md | `psi/inbox/` |
| `memory/` | Knowledge base | `psi/memory/` |
| `writing/` | Blog drafts | ❌ Missing |
| `lab/` | Experiments | `psi/lab/` |
| `incubate/` | Active development (symlinks) | ❌ Missing |
| `learn/` | Study materials (symlinks) | ❌ Missing |

**Gap identified**: We lack `incubate/` and `learn/` pillars.

### 4. Commands Alignment

| Their Command | Purpose | Our Equivalent |
|---------------|---------|----------------|
| `/rrr` | Create retrospective | `/rrr` ✅ Same |
| `/snapshot` | Quick knowledge capture | `/snapshot` ✅ Same |
| `/recap` | Fresh start context | ❌ Missing |
| `/trace` | Find project across history | `/context-finder` |

### 5. Philosophy Alignment

Their 3 pillars match our Prime Directives:

| Oracle Framework | The Matrix |
|------------------|------------|
| Nothing is Deleted | Prime Directive #1 |
| Patterns Over Intentions | Prime Directive #2 |
| External Brain, Not Command | Philosophy alignment |

---

## What We Can Learn

### Immediate Adoption

1. **Formalize subagent definitions** - Create `.claude/subagents/` with explicit agent configs
2. **Add `/recap` command** - Fresh context summary for new sessions
3. **Symlink pattern for external repos** - `ghq` + symlinks to `psi/learn/`

### Strategic Evolution

1. **Add `incubate/` pillar** - Active development symlinks
2. **Add `learn/` pillar** - Study materials
3. **Security scanner as pre-commit** - Automated secret detection

### Multi-Agent Workflow Kit

Related repo mentioned: `multi-agent-workflow-kit` - Should investigate further.

---

## Architectural Comparison

```
ORACLE FRAMEWORK                    THE MATRIX
================                    ==========
oracle-keeper (Opus)         ←→     Oracle (orchestrator)
context-finder (Haiku)       ←→     Tank (internal search)
security-scanner (Haiku)     ←→     Smith (anomaly detection)
coder (Opus)                 ←→     Neo (implementation)
executor (Haiku)             ←→     Tank (bash execution)

Missing in Matrix:
- repo-auditor equivalent
- Formalized subagent spawning patterns
```

---

## Recommendation for Council

The Oracle Framework validates our direction. Key actions:

1. **ADR-001 confirmed** - Spawn vs Role-Switch pattern is correct
2. **Formalize subagents** - Document when to spawn each type
3. **Add missing pillars** - `incubate/`, `learn/`
4. **Add `/recap`** - Session context refresh

> "We are not so different, you and I." - The Oracle

---

*Research complete. Ready for Architect + Oracle synthesis.*
