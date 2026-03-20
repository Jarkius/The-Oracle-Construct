# Lesson: Auto-Detect Over Hardcode

**Date**: 2026-03-20
**Source**: Control Center v2 + Hooks Flatten
**Confidence**: High (burned twice in same day)

## Pattern

Never count `../` directory levels to find project root. Always walk up and find markers.

## Problem

Shell scripts used `$SCRIPT_DIR/../..` which broke when hooks moved from flat to subdirectory structure. TypeScript used `join(import.meta.dir, "../../../../..")` which resolved to wrong directory when depth was miscounted.

Both bugs took 30+ minutes to diagnose. Both had the same root cause: hardcoded relative path depth.

## Solution

Created `src/core/paths.ts`:
```typescript
function findProjectRoot(startDir: string): string {
  let dir = resolve(startDir);
  while (dir !== dirname(dir)) {
    if (existsSync(join(dir, "CLAUDE.md")) && existsSync(join(dir, "src"))) return dir;
    if (existsSync(join(dir, "package.json")) && existsSync(join(dir, ".git"))) return dir;
    dir = dirname(dir);
  }
  return process.cwd();
}
export const PROJECT_ROOT = process.env.MATRIX_ROOT || findProjectRoot(import.meta.dir);
```

## Rule

1. If you need the project root, use `PROJECT_ROOT` from `src/core/paths.ts`
2. If you need a file relative to root, use `join(PROJECT_ROOT, "path/to/file")`
3. Never write `../../../..` — it will break when files move

## Related

- Hooks flatten (2026-03-20): `$SCRIPT_DIR/../..` broke for subdirectories
- Control Center (2026-03-20): `import.meta.dir + ../../../../..` went one level too far
- ADR-019: Folder consolidation architecture

## Tags

architecture, paths, auto-detection, anti-pattern, typescript, shell
