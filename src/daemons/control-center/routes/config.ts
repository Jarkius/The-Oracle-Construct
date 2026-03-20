/**
 * Configuration Routes
 *
 * Sanitized config output and platform info.
 */

import { Hono } from "hono";
import { getSanitizedConfig } from "../../../core/config";

const app = new Hono();

// GET / — Sanitized configuration (API keys redacted)
app.get("/", async (c) => {
  try {
    const sanitized = getSanitizedConfig();
    return c.json(sanitized);
  } catch (e) {
    return c.json({ error: String(e) }, 500);
  }
});

// GET /platform — Runtime platform info
app.get("/platform", async (c) => {
  let python3: string | false = false;
  try {
    const proc = Bun.spawn(["python3", "--version"], { stdout: "pipe", stderr: "pipe" });
    const out = await new Response(proc.stdout).text();
    const code = await proc.exited;
    if (code === 0) {
      python3 = out.trim();
    }
  } catch {}

  let sharp: string | false = false;
  try {
    const mod = await import("sharp");
    // sharp exports a default function; its presence means it's installed
    sharp = typeof mod.default === "function" ? "installed" : "installed";
  } catch {}

  return c.json({
    os: process.platform,
    arch: process.arch,
    bun: Bun.version,
    python3,
    sharp,
    chromaSkip: !!process.env.SKIP_VECTORDB,
  });
});

export default app;
