import { describe, test, expect, beforeEach } from "bun:test";
import { StateDetector } from "../state-detector";
import { mkdtemp, writeFile, readFile } from "node:fs/promises";
import { join } from "node:path";
import { tmpdir } from "node:os";

describe("StateDetector", () => {
  let detector: StateDetector;
  let eventsPath: string;

  beforeEach(async () => {
    const dir = await mkdtemp(join(tmpdir(), "nerve-sd-test-"));
    eventsPath = join(dir, "events.jsonl");
    await writeFile(eventsPath, "");
    detector = new StateDetector(eventsPath);
  });

  test("first check returns null (no previous state)", async () => {
    const result = await detector.check("test", "healthy");
    expect(result).toBeNull();
  });

  test("no event on same state", async () => {
    await detector.check("test", "healthy");
    const result = await detector.check("test", "healthy");
    expect(result).toBeNull();
    const content = await readFile(eventsPath, "utf-8");
    expect(content.trim()).toBe("");
  });

  test("emits heartbeat:fail on healthy→unhealthy", async () => {
    await detector.check("test", "healthy");
    const result = await detector.check("test", "unhealthy");
    expect(result).not.toBeNull();
    expect(result!.from).toBe("healthy");
    expect(result!.to).toBe("unhealthy");
    const content = await readFile(eventsPath, "utf-8");
    expect(content).toContain("heartbeat:fail");
  });

  test("emits heartbeat:recover on unhealthy→healthy", async () => {
    await detector.check("test", "unhealthy");
    const result = await detector.check("test", "healthy");
    expect(result).not.toBeNull();
    const content = await readFile(eventsPath, "utf-8");
    expect(content).toContain("heartbeat:recover");
  });

  test("emits heartbeat:degraded on healthy→degraded (not fail)", async () => {
    await detector.check("test", "healthy");
    await detector.check("test", "degraded");
    const content = await readFile(eventsPath, "utf-8");
    expect(content).toContain("heartbeat:degraded");
    expect(content).not.toContain("heartbeat:fail");
  });

  test("tracks multiple services independently", async () => {
    await detector.check("svc-a", "healthy");
    await detector.check("svc-b", "healthy");
    await detector.check("svc-a", "unhealthy");
    const states = detector.getStates();
    expect(states.get("svc-a")).toBe("unhealthy");
    expect(states.get("svc-b")).toBe("healthy");
  });
});
