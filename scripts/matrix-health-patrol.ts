#!/usr/bin/env bun
/**
 * Matrix Health Patrol — Code Quality Scanner
 *
 * Finds bloat, dead code, oversized files, unused exports,
 * and structural issues across the Matrix codebase.
 *
 * Usage:
 *   bun scripts/matrix-health-patrol.ts           # Full scan
 *   bun scripts/matrix-health-patrol.ts --quick    # Quick (size + imports only)
 *   bun scripts/matrix-health-patrol.ts --fix      # Auto-fix safe issues
 */

import { readdir, readFile, stat } from "node:fs/promises";
import { join, relative, extname } from "node:path";

const ROOT = join(import.meta.dir, "..");
const SRC = join(ROOT, "src");
const SCRIPTS = join(ROOT, "scripts");
const QUICK = process.argv.includes("--quick");

interface Issue {
  severity: "critical" | "high" | "medium" | "low";
  category: string;
  file: string;
  message: string;
  line?: number;
}

const issues: Issue[] = [];

// ============ Helpers ============

async function walkTs(dir: string): Promise<string[]> {
  const files: string[] = [];
  try {
    const entries = await readdir(dir, { withFileTypes: true });
    for (const entry of entries) {
      const full = join(dir, entry.name);
      if (entry.isDirectory() && !entry.name.startsWith(".") && entry.name !== "node_modules") {
        files.push(...(await walkTs(full)));
      } else if (entry.isFile() && (entry.name.endsWith(".ts") || entry.name.endsWith(".tsx"))) {
        files.push(full);
      }
    }
  } catch {}
  return files;
}

function rel(path: string): string {
  return relative(ROOT, path);
}

// ============ Checks ============

async function checkFileSize(files: string[]): Promise<void> {
  for (const file of files) {
    const s = await stat(file);
    const lines = (await readFile(file, "utf-8")).split("\n").length;
    const kb = Math.round(s.size / 1024);

    if (lines > 500) {
      issues.push({
        severity: lines > 1000 ? "high" : "medium",
        category: "bloat",
        file: rel(file),
        message: `${lines} lines (${kb}KB) — consider splitting`,
      });
    }
  }
}

async function checkDeadImports(files: string[]): Promise<void> {
  for (const file of files) {
    const content = await readFile(file, "utf-8");
    const lines = content.split("\n");

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];

      // Check for imports that cross module boundaries into the OLD flat structure
      // Valid: ../vector-db (within same module like memory/)
      // Invalid: ../../../db (going to root-level db that no longer exists)
      // We verify by checking if the resolved path actually exists
      const importMatch = line.match(/from\s+['"]([^'"]+)['"]/);
      if (importMatch) {
        const importPath = importMatch[1];
        // Only check relative imports that go up directories
        if (importPath.startsWith("..")) {
          const dir = join(file, "..");
          const resolved = join(dir, importPath);
          // Check if the resolved path exists (with .ts extension)
          const candidates = [resolved + ".ts", resolved + "/index.ts", resolved];
          const exists = candidates.some(c => {
            try { Bun.file(c).size; return true; } catch { return false; }
          });
          if (!exists) {
            issues.push({
              severity: "critical",
              category: "broken-import",
              file: rel(file),
              line: i + 1,
              message: `Broken import: ${line.trim()}`,
            });
          }
        }
      }
    }
  }
}

async function checkUnusedExports(files: string[]): Promise<void> {
  if (QUICK) return;

  // Build export map
  const exports = new Map<string, { file: string; name: string }[]>();
  for (const file of files) {
    const content = await readFile(file, "utf-8");
    const exportMatches = content.matchAll(/export\s+(?:async\s+)?(?:function|const|class|type|interface|enum)\s+(\w+)/g);
    for (const m of exportMatches) {
      const name = m[1];
      if (!exports.has(name)) exports.set(name, []);
      exports.get(name)!.push({ file: rel(file), name });
    }
  }

  // Check if exports are imported anywhere
  const allContent = await Promise.all(files.map(f => readFile(f, "utf-8")));
  const allText = allContent.join("\n");

  for (const [name, locations] of exports) {
    if (locations.length > 1) continue; // Multiple exports = likely intentional
    if (name.startsWith("_")) continue; // Private convention

    // Count occurrences (excluding the export itself)
    const regex = new RegExp(`\\b${name}\\b`, "g");
    const matches = allText.match(regex);
    const count = matches ? matches.length : 0;

    if (count <= 1) {
      issues.push({
        severity: "low",
        category: "unused-export",
        file: locations[0].file,
        message: `Possibly unused export: ${name}`,
      });
    }
  }
}

async function checkEmptyFiles(files: string[]): Promise<void> {
  for (const file of files) {
    const content = await readFile(file, "utf-8");
    const meaningful = content
      .split("\n")
      .filter(l => l.trim() && !l.trim().startsWith("//") && !l.trim().startsWith("*") && !l.trim().startsWith("/*"))
      .length;

    if (meaningful < 3) {
      issues.push({
        severity: "low",
        category: "empty-file",
        file: rel(file),
        message: `Only ${meaningful} meaningful lines — consider removing`,
      });
    }
  }
}

async function checkDuplicateLogic(files: string[]): Promise<void> {
  if (QUICK) return;

  // Check for duplicated function signatures across files
  const funcMap = new Map<string, string[]>();
  for (const file of files) {
    const content = await readFile(file, "utf-8");
    const funcs = content.matchAll(/(?:export\s+)?(?:async\s+)?function\s+(\w+)\s*\(/g);
    for (const m of funcs) {
      const name = m[1];
      if (!funcMap.has(name)) funcMap.set(name, []);
      funcMap.get(name)!.push(rel(file));
    }
  }

  for (const [name, locations] of funcMap) {
    if (locations.length > 1 && !["default", "main", "init", "start", "stop"].includes(name)) {
      issues.push({
        severity: "medium",
        category: "duplicate",
        file: locations.join(", "),
        message: `Function "${name}" defined in ${locations.length} files`,
      });
    }
  }
}

async function checkBunWriteAppend(files: string[]): Promise<void> {
  for (const file of files) {
    const content = await readFile(file, "utf-8");
    // Only flag actual Bun.write() calls with append, not comments mentioning it
    if (/Bun\.write\s*\(/.test(content) && content.includes("append: true")) {
      issues.push({
        severity: "critical",
        category: "known-bug",
        file: rel(file),
        message: "Bun.write with append flag — BROKEN in Bun 1.3.x. Use appendFile().",
      });
    }
  }
}

async function checkTodoFixme(files: string[]): Promise<void> {
  if (QUICK) return;

  for (const file of files) {
    const content = await readFile(file, "utf-8");
    const lines = content.split("\n");
    for (let i = 0; i < lines.length; i++) {
      if (/\b(TODO|FIXME|HACK|XXX)\b/.test(lines[i])) {
        issues.push({
          severity: "low",
          category: "todo",
          file: rel(file),
          line: i + 1,
          message: lines[i].trim().slice(0, 100),
        });
      }
    }
  }
}

async function checkAnyType(files: string[]): Promise<void> {
  if (QUICK) return;

  for (const file of files) {
    const content = await readFile(file, "utf-8");
    const lines = content.split("\n");
    let anyCount = 0;
    for (const line of lines) {
      // Match `: any`, `as any`, `<any>`, but not in comments
      if (!line.trim().startsWith("//") && /\bany\b/.test(line)) {
        anyCount++;
      }
    }
    if (anyCount > 3) {
      issues.push({
        severity: "medium",
        category: "type-safety",
        file: rel(file),
        message: `${anyCount} uses of 'any' type — consider proper typing`,
      });
    }
  }
}

// ============ Summary ============

function printSummary(): void {
  const critical = issues.filter(i => i.severity === "critical");
  const high = issues.filter(i => i.severity === "high");
  const medium = issues.filter(i => i.severity === "medium");
  const low = issues.filter(i => i.severity === "low");

  console.log("\n=== Matrix Health Patrol Report ===\n");

  if (critical.length > 0) {
    console.log(`\x1b[31m CRITICAL (${critical.length})\x1b[0m`);
    for (const i of critical) console.log(`  ${i.file}:${i.line || ""} — ${i.message}`);
    console.log();
  }

  if (high.length > 0) {
    console.log(`\x1b[33m HIGH (${high.length})\x1b[0m`);
    for (const i of high) console.log(`  ${i.file} — ${i.message}`);
    console.log();
  }

  if (medium.length > 0) {
    console.log(`\x1b[36m MEDIUM (${medium.length})\x1b[0m`);
    for (const i of medium) console.log(`  ${i.file} — ${i.message}`);
    console.log();
  }

  if (low.length > 0 && !QUICK) {
    console.log(`\x1b[90m LOW (${low.length})\x1b[0m`);
    for (const i of low.slice(0, 20)) console.log(`  ${i.file} — ${i.message}`);
    if (low.length > 20) console.log(`  ... and ${low.length - 20} more`);
    console.log();
  }

  // Category breakdown
  const categories = new Map<string, number>();
  for (const i of issues) {
    categories.set(i.category, (categories.get(i.category) || 0) + 1);
  }

  console.log("--- By Category ---");
  for (const [cat, count] of [...categories.entries()].sort((a, b) => b[1] - a[1])) {
    console.log(`  ${cat}: ${count}`);
  }

  console.log(`\n--- Total: ${issues.length} issues (${critical.length} critical, ${high.length} high, ${medium.length} medium, ${low.length} low) ---`);

  // Score
  const score = Math.max(0, 100 - critical.length * 20 - high.length * 5 - medium.length * 2 - low.length * 0.5);
  const grade = score >= 90 ? "A" : score >= 80 ? "B" : score >= 70 ? "C" : score >= 60 ? "D" : "F";
  console.log(`\nHealth Score: ${Math.round(score)}/100 (${grade})`);
}

// ============ Main ============

async function main(): Promise<void> {
  console.log(`Scanning ${QUICK ? "(quick)" : "(full)"}...`);

  const srcFiles = await walkTs(SRC);
  const scriptFiles = await walkTs(SCRIPTS);
  const allFiles = [...srcFiles, ...scriptFiles];

  console.log(`Found ${allFiles.length} TypeScript files`);

  await checkFileSize(allFiles);
  await checkDeadImports(allFiles);
  await checkBunWriteAppend(allFiles);
  await checkEmptyFiles(srcFiles);

  if (!QUICK) {
    await checkUnusedExports(srcFiles);
    await checkDuplicateLogic(srcFiles);
    await checkTodoFixme(allFiles);
    await checkAnyType(srcFiles);
  }

  printSummary();
}

main().catch(console.error);
