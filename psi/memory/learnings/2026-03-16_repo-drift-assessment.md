# Repo Drift Assessment Before Consolidation

**Date**: 2026-03-16
**Context**: Three Matrix repos drifting apart, needed consolidation strategy
**Confidence**: High

## Key Learning

Always assess repo drift with parallel explore agents before planning consolidation. What appeared to be a massive 3-repo merge (124 vs 117 vs 16 TypeScript files) turned out to be a 2-file cherry-pick once we discovered that LOCAL was 49 commits ahead and GHQ only had 2 unique files.

The assessment pattern: launch 3 parallel agents — one per repo — comparing file trees, git history, and unique features. The diff output (`find src/ -name "*.ts" | sort`) immediately reveals which directories are unique to each copy.

## The Pattern

1. Count files and commits in each copy
2. Diff directory structures to find unique dirs
3. Diff shared files to find code drift
4. Check which copy is "canonical" (most commits, most features)
5. Cherry-pick unique files from stale copies into canonical
6. Archive stale copies

## Why This Matters

Without assessment, we would have attempted a full 3-way merge — days of work. With assessment, we identified a 15-minute cherry-pick. The explore agents paid for themselves 100x over.

## Tags

`architecture`, `consolidation`, `git`, `assessment`, `repo-management`
