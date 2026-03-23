# Lesson: Sibling Codebases Hold Proven Patterns

**Date**: 2026-03-23
**Source**: /learn oracle-skills-cli → comparison with the-matrix
**Tags**: architecture, patterns, skill-system, distribution, evolution

## The Pattern

When you build multiple projects with the same philosophy, each solves different problems. The solutions in one are patterns waiting to be adopted by the other. Don't reinvent — reunify.

## What We Found

oracle-skills-cli (distribution layer) solved problems the-matrix (runtime layer) hadn't:
1. **Command compiler** — auto-generates 43 command stubs from SKILL.md metadata
2. **Version injection** — `v3.3.0 G-SKLL |` in every skill description for UI visibility
3. **Profile system** — minimal/standard/full tiers (not all 43 skills every session)
4. **Installer markers** — `installer: oracle-skills-cli` identifies managed vs hand-written
5. **Feature stacking** — composable add-ons (`+soul`, `+research`, `+debug`)

## The Lesson

Before building a new system, check if a sibling project already solved it. The answer is often "yes, six months ago." Cross-pollination beats reinvention.
