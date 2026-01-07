# Research: Knowledge Base Starter

> Source: https://github.com/ThePassionateProgrammer/knowledge-base-starter
> Researched: 2026-01-08
> Agent: Morpheus

## Summary

A flat-file knowledge base template for AI-assisted development. Teaches Claude "how you work" through documented practices.

## Key Pattern: Tiered Access

```
Tier 1 - Core (Auto-load at session start)
├── index.md           # Navigation hub
├── style-guide.md     # Code standards
└── working-agreement.md # Partnership norms

Tier 2 - Reference (On-demand)
├── philosophy.md      # Development approach
├── testing.md         # Test-first workflow
├── refactoring.md     # Safe restructuring
├── design-patterns.md # Architectural patterns
├── domain-language.md # Project vocabulary
└── decisions.md       # ADRs

Tier 3 - Maintenance
└── CONTRIBUTING.md    # How to evolve
```

## Design Principles

1. **Flat structure** - No subdirectories, all `.md` files at root or `/docs`
2. **~400 words per file** - Concise but meaningful
3. **Token efficiency** - Core files load always, rest on-demand
4. **Version controlled** - Lives with codebase
5. **Living document** - Updated as practices evolve

## Philosophy

- Extreme Programming (XP)
- Domain-Driven Design (DDD)
- Test-first discipline
- Red-green-refactor workflow

## Relevance to The Matrix

Our `psi/` folder already implements a more sophisticated version:
- `psi/knowledge/` = Tier 1+2 (core + reference)
- `psi/specs/` = Domain-specific (ADRs, stories)
- `psi/memory/` = Session history (Tier 3)

**Recommendation**: Adopt the ~400 word guideline for knowledge files. Keep them scannable.

## Status: COMPLETE
