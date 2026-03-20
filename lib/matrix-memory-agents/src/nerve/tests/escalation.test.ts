import { describe, test, expect, beforeEach } from "bun:test";
import { EscalationEngine } from "../escalation";
import { DEFAULT_ESCALATION_CONFIG } from "../types";
import type { DaemonState } from "../types";
import { mkdtemp, writeFile, readFile } from "node:fs/promises";
import { join } from "node:path";
import { tmpdir } from "node:os";

function makeDaemon(name = "test-daemon"): DaemonState {
  return {
    name,
    pid: null,
    state: "unhealthy",
    previousState: "healthy",
    level: 0,
    restarts: 0,
    restartsThisHour: 0,
    lastRestartHour: Math.floor(Date.now() / 3_600_000),
    lastHealthCheck: Date.now(),
    lastStateChange: Date.now(),
    escalationTimer: null,
    standbyTimer: null,
    exitHistory: [1, 1, 1],
    port: 8080,
    command: "echo test",
    logFile: "/tmp/test.log",
  };
}

describe("EscalationEngine", () => {
  let engine: EscalationEngine;
  let eventsPath: string;

  beforeEach(async () => {
    const dir = await mkdtemp(join(tmpdir(), "nerve-test-"));
    eventsPath = join(dir, "events.jsonl");
    await writeFile(eventsPath, "");
    engine = new EscalationEngine(eventsPath);
  });

  test("L1: first failure triggers simple restart", async () => {
    const daemon = makeDaemon();
    const level = await engine.handleFailure(daemon);
    expect(level).toBe(1);
    expect(daemon.level).toBe(1);
    expect(daemon.restartsThisHour).toBe(1);
  });

  test("L2: 3+ restarts/hour triggers state reset", async () => {
    const daemon = makeDaemon();
    daemon.restartsThisHour = 2; // Already had 2
    const level = await engine.handleFailure(daemon);
    expect(level).toBe(2);
    expect(daemon.level).toBe(2);
  });

  test("L3: 5+ restarts/hour triggers human notification", async () => {
    const daemon = makeDaemon();
    daemon.restartsThisHour = 4; // Already had 4
    let notified = false;
    engine.wire({ notify: async () => { notified = true; } });
    const level = await engine.handleFailure(daemon);
    expect(level).toBe(3);
    expect(notified).toBe(true);
  });

  test("circuit breaker: L4 limited to max per day", () => {
    const usage = engine.getL4Usage();
    expect(usage.used).toBe(0);
    expect(usage.max).toBe(DEFAULT_ESCALATION_CONFIG.l4MaxPerDay);
  });

  test("reset clears all escalation state", () => {
    const daemon = makeDaemon();
    daemon.level = 3;
    daemon.restartsThisHour = 10;
    engine.reset(daemon);
    expect(daemon.level).toBe(0);
    expect(daemon.restartsThisHour).toBe(0);
  });

  test("events are written to JSONL", async () => {
    const daemon = makeDaemon();
    await engine.handleFailure(daemon);
    const content = await readFile(eventsPath, "utf-8");
    expect(content.length).toBeGreaterThan(0);
    const event = JSON.parse(content.trim());
    expect(event.type).toBe("nerve:escalation");
    expect(event.agent).toBe("nerve");
  });

  test("hourly counter resets on new hour", async () => {
    const daemon = makeDaemon();
    daemon.restartsThisHour = 10;
    daemon.lastRestartHour = Math.floor(Date.now() / 3_600_000) - 1; // Previous hour
    await engine.handleFailure(daemon);
    expect(daemon.restartsThisHour).toBe(1); // Reset + this failure
  });
});
