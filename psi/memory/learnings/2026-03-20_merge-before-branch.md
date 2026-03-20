# Merge Before Branch: Parallel Evolution Strategy

**Date**: 2026-03-20
**Category**: process
**Confidence**: high

## Lesson

Before creating a new feature branch for large restructuring work, always check remote branches for parallel efforts (`git branch -r`). Two independent restructures of the same codebase — one flattening lib/ to src/ with Nerve/CDP, another adding coordination/security/skills — merged cleanly with only 4 conflicts because they addressed orthogonal concerns.

## Pattern

Evolution should compound, not compete. When parallel work exists:
1. Check which branch has more evolution (raw code, new capabilities)
2. Merge YOUR work INTO the more evolved branch (not the other way around)
3. Resolve conflicts by keeping the version with correct paths/structure from your restructure, and new features from theirs

## Anti-Pattern

Creating a competing PR when parallel work exists on the same codebase. This forces a "pick one" decision when the right answer is "combine both."

## Applied

Merged 435-file Phase 0-15 restructure into 525-file evolve/matrix-overhaul branch. Result: 951 files changed with both branches' innovations preserved. 4 conflicts, all trivial.

**Tags**: git, branching, merge-strategy, parallel-work, evolution
