#!/usr/bin/env bun
/**
 * audit-permissions.ts — Scan agent definitions and report permission enforcement
 * Usage: bun run scripts/security/audit-permissions.ts
 */

import { readFileSync, readdirSync, existsSync } from "fs";
import { join, basename } from "path";

const ROOT = join(import.meta.dir, "..", "..");
const AGENTS_DIR = join(ROOT, ".claude", "agents");
const GATE_HOOK = join(ROOT, ".claude", "hooks", "core", "matrix-permission-gate.sh");
const SETTINGS = join(ROOT, ".claude", "settings.json");

const RESET = "\x1b[0m";
const BOLD = "\x1b[1m";
const GREEN = "\x1b[32m";
const YELLOW = "\x1b[33m";
const RED = "\x1b[31m";
const CYAN = "\x1b[36m";
const DIM = "\x1b[2m";

const MODE_MAP: Record<string, string> = {
  acceptEdits: "full",
  plan: "plan",
  dontAsk: "dontAsk",
  bypassPermissions: "full",
};

function parseFrontmatter(content: string): Record<string, unknown> {
  const normalized = content.replace(/\r\n/g, "\n");
  const match = normalized.match(/^---\n([\s\S]*?)\n---/);
  if (!match) return {};
  const yaml: Record<string, unknown> = {};
  let currentKey = "";
  let currentList: string[] | null = null;

  for (const line of match[1].split("\n")) {
    const listItem = line.match(/^\s+-\s+(.+)/);
    if (listItem && currentKey) {
      currentList!.push(listItem[1].trim());
    } else {
      if (currentKey && currentList) yaml[currentKey] = currentList;
      const kv = line.match(/^(\w+):\s*(.*)/);
      if (kv) {
        currentKey = kv[1];
        if (kv[2].trim()) {
          yaml[currentKey] = kv[2].trim();
          currentList = null;
        } else {
          currentList = [];
        }
      }
    }
  }
  if (currentKey && currentList) yaml[currentKey] = currentList;
  return yaml;
}

function checkEnforcement(): string {
  const hookExists = existsSync(GATE_HOOK);
  if (!hookExists) return `${RED}NONE${RESET}`;
  try {
    const settings = JSON.parse(readFileSync(SETTINGS, "utf-8"));
    const preTools = settings?.hooks?.PreToolUse ?? [];
    const wired = preTools.some((entry: { hooks?: { command?: string }[] }) =>
      entry.hooks?.some((h) => h.command?.includes("matrix-permission-gate"))
    );
    return wired ? `${GREEN}ACTIVE${RESET}` : `${YELLOW}UNWIRED${RESET}`;
  } catch {
    return `${YELLOW}UNWIRED${RESET}`;
  }
}

const enforcement = checkEnforcement();
const files = readdirSync(AGENTS_DIR).filter((f) => f.endsWith(".md") && f !== "CLAUDE.md");
let restricted = 0;

console.log(`\n${BOLD}${CYAN} Agent Permission Audit${RESET}\n`);
console.log(`${"Agent".padEnd(18)} ${"Mode".padEnd(10)} ${"Disallowed Tools".padEnd(30)}`);
console.log(`${DIM}${"─".repeat(18)} ${"─".repeat(10)} ${"─".repeat(30)}${RESET}`);

for (const file of files.sort()) {
  const content = readFileSync(join(AGENTS_DIR, file), "utf-8");
  const fm = parseFrontmatter(content);
  const name = (fm.name as string) ?? basename(file, ".md");
  const rawMode = (fm.permissionMode as string) ?? "acceptEdits";
  const mode = MODE_MAP[rawMode] ?? rawMode;
  const disallowed = (fm.disallowedTools as string[]) ?? [];

  if (disallowed.length > 0) restricted++;
  const disallowedStr = disallowed.length > 0 ? `${RED}${disallowed.join(", ")}${RESET}` : `${DIM}none${RESET}`;
  const modeColor = mode === "plan" ? YELLOW : mode === "dontAsk" ? RED : GREEN;

  console.log(`${BOLD}${name.padEnd(18)}${RESET} ${modeColor}${mode.padEnd(10)}${RESET} ${disallowedStr}`);
}

console.log(`\n${BOLD}Summary:${RESET} ${restricted} agent(s) with restrictions, enforcement: ${enforcement}\n`);
