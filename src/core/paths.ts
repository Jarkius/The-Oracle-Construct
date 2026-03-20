/**
 * Project Root Detection
 *
 * Auto-detects the Matrix project root by walking up from any file
 * until we find CLAUDE.md (definitive) or package.json + .git.
 * Never relies on counting "../" levels.
 */

import { existsSync } from "node:fs";
import { join, dirname, resolve } from "node:path";

function findProjectRoot(startDir: string): string {
  let dir = resolve(startDir);
  const root = dirname(dir) === dir ? dir : "/"; // filesystem root

  while (dir !== dirname(dir)) {
    // CLAUDE.md is definitive for Matrix projects
    if (existsSync(join(dir, "CLAUDE.md")) && existsSync(join(dir, "src"))) {
      return dir;
    }
    // Fallback: package.json + .git
    if (existsSync(join(dir, "package.json")) && existsSync(join(dir, ".git"))) {
      return dir;
    }
    dir = dirname(dir);
  }

  // Last resort: cwd
  return process.cwd();
}

/** Matrix project root — auto-detected, never hardcoded */
export const PROJECT_ROOT = process.env.MATRIX_ROOT || findProjectRoot(import.meta.dir);
