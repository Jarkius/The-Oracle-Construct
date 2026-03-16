#!/usr/bin/env bun
/**
 * CDP Server — Bridge between MQTT commands and Chrome DevTools Protocol
 *
 * Matrix daemon module: controls Chrome tabs via CDP, receives commands over MQTT.
 * The extension becomes a read-only status display (sidepanel).
 *
 * Usage:
 *   bun cdp-server.ts                     # Default: port 9222
 *   bun cdp-server.ts --port 9222,9223    # Multiple profiles
 *   bun cdp-server.ts --profile paid:9222 free:9223
 *
 * Migrated from: claude-browser-proxy/cdp-server.ts
 */

import mqtt from "mqtt";
import { appendFile } from "node:fs/promises";
import { resolve } from "node:path";
import { createLogger } from "../../core/utils/logger";

// === LOGGER ===
const log = createLogger("cdp-proxy");

// === PULSE EVENT EMISSION ===
const PULSE_EVENTS_PATH = resolve(
  import.meta.dir,
  "../../../../../psi/pulse/events.jsonl"
);

async function emitPulseEvent(
  type: string,
  data: Record<string, unknown>
): Promise<void> {
  const event = {
    ts: new Date().toISOString(),
    type,
    agent: "cdp-proxy",
    session: "daemon",
    data,
  };
  try {
    await appendFile(PULSE_EVENTS_PATH, JSON.stringify(event) + "\n");
  } catch (err: any) {
    log.warn("Failed to write PULSE event", { error: err.message, type });
  }
}

// === CONFIG ===
const MQTT_URL = process.env.MQTT_URL || "mqtt://localhost:1883";
const VERSION = "1.1.0";
const DEFAULT_CDP_PORT = 9222;

// Parse CLI args for CDP ports
interface ProfileConfig {
  name: string;
  port: number;
}

function parseArgs(): ProfileConfig[] {
  const args = process.argv.slice(2);
  const profiles: ProfileConfig[] = [];

  for (let i = 0; i < args.length; i++) {
    if (args[i] === "--port") {
      const ports = args[++i]?.split(",").map(Number) || [DEFAULT_CDP_PORT];
      ports.forEach((port, idx) =>
        profiles.push({ name: idx === 0 ? "default" : `profile${idx}`, port })
      );
    } else if (args[i] === "--profile") {
      // Consume all following name:port pairs until next flag
      while (i + 1 < args.length && !args[i + 1]!.startsWith("--")) {
        const parts = args[++i]!.split(":");
        const name = parts[0] ?? "default";
        profiles.push({ name, port: Number(parts[1]) });
      }
    }
  }

  if (profiles.length === 0) {
    profiles.push({ name: "default", port: DEFAULT_CDP_PORT });
  }
  return profiles;
}

// === MQTT TOPICS ===
// Write actions delegated to extension (needs chrome.scripting privilege)
const WRITE_ACTIONS = new Set([
  'chat', 'click', 'clickText', 'type', 'key', 'find',
  'select_model', 'select_mode',
  'inject_badge', 'execute',
  'wait_response', 'get_response',
  'transcribe',
]);

function topics(profile: string) {
  const prefix =
    profile === "default" ? "claude/browser" : `claude/browser/${profile}`;
  return {
    command: `${prefix}/command`,
    response: `${prefix}/response`,
    extWrite: `${prefix}/ext-write`,  // CDP -> extension for write actions
    status: `${prefix}/status`,
    state: `${prefix}/state`,
    answer: `${prefix}/answer`,
    page: `${prefix}/page`,
  };
}

// === CDP CLIENT ===
interface CDPTab {
  id: string;
  title: string;
  url: string;
  webSocketDebuggerUrl: string;
  type: string;
}

async function cdpListTabs(port: number): Promise<CDPTab[]> {
  try {
    const res = await fetch(`http://127.0.0.1:${port}/json`);
    const targets = (await res.json()) as any[];
    return targets
      .filter((t) => t.type === "page")
      .map((t) => ({
        id: t.id,
        title: t.title,
        url: t.url,
        webSocketDebuggerUrl: t.webSocketDebuggerUrl,
        type: t.type,
      }));
  } catch (e: any) {
    return [];
  }
}

async function cdpNewTab(
  port: number,
  url: string
): Promise<CDPTab | null> {
  try {
    // Chrome 145+ requires PUT method for /json/new
    const res = await fetch(
      `http://127.0.0.1:${port}/json/new?${url}`,
      { method: "PUT" }
    );
    return (await res.json()) as CDPTab;
  } catch {
    return null;
  }
}

async function cdpCloseTab(port: number, tabId: string): Promise<boolean> {
  try {
    // Try PUT first (Chrome 145+), fallback to GET
    let res = await fetch(`http://127.0.0.1:${port}/json/close/${tabId}`, { method: "PUT" });
    if (!res.ok) res = await fetch(`http://127.0.0.1:${port}/json/close/${tabId}`);
    return true;
  } catch {
    return false;
  }
}

async function cdpActivateTab(port: number, tabId: string): Promise<boolean> {
  try {
    let res = await fetch(`http://127.0.0.1:${port}/json/activate/${tabId}`, { method: "PUT" });
    if (!res.ok) res = await fetch(`http://127.0.0.1:${port}/json/activate/${tabId}`);
    return true;
  } catch {
    return false;
  }
}

// Execute JS on a tab via CDP WebSocket
async function cdpExecute(
  wsUrl: string,
  expression: string,
  timeout = 15000
): Promise<any> {
  return new Promise((resolve, reject) => {
    const ws = new WebSocket(wsUrl);
    const timer = setTimeout(() => {
      ws.close();
      reject(new Error("CDP execution timeout"));
    }, timeout);

    const msgId = 1;

    ws.onopen = () => {
      ws.send(
        JSON.stringify({
          id: msgId,
          method: "Runtime.evaluate",
          params: {
            expression,
            returnByValue: true,
            awaitPromise: true,
          },
        })
      );
    };

    ws.onmessage = (event) => {
      const data = JSON.parse(event.data as string);
      if (data.id === msgId) {
        clearTimeout(timer);
        ws.close();
        if (data.result?.exceptionDetails) {
          reject(
            new Error(
              data.result.exceptionDetails.exception?.description ||
                "JS execution error"
            )
          );
        } else {
          resolve(data.result?.result?.value);
        }
      }
    };

    ws.onerror = (err) => {
      clearTimeout(timer);
      reject(new Error("CDP WebSocket error"));
    };
  });
}

// Navigate a tab via CDP
async function cdpNavigate(wsUrl: string, url: string): Promise<boolean> {
  return new Promise((resolve, reject) => {
    const ws = new WebSocket(wsUrl);
    const timer = setTimeout(() => {
      ws.close();
      reject(new Error("Navigate timeout"));
    }, 10000);

    ws.onopen = () => {
      ws.send(
        JSON.stringify({
          id: 1,
          method: "Page.navigate",
          params: { url },
        })
      );
    };

    ws.onmessage = (event) => {
      const data = JSON.parse(event.data as string);
      if (data.id === 1) {
        clearTimeout(timer);
        ws.close();
        resolve(!data.error);
      }
    };

    ws.onerror = () => {
      clearTimeout(timer);
      resolve(false);
    };
  });
}

// === FIND TAB ===
async function findGeminiTab(
  port: number,
  tabId?: string
): Promise<CDPTab | null> {
  const allTabs = await cdpListTabs(port);
  const geminiTabs = allTabs.filter((t) =>
    t.url.includes("gemini.google.com")
  );

  if (tabId) {
    // Find by CDP tab ID
    return geminiTabs.find((t) => t.id === tabId) || null;
  }

  // Return most relevant Gemini tab (prefer /app/ over /share/)
  const appTabs = geminiTabs.filter((t) => t.url.includes("/app/"));
  return appTabs[0] || geminiTabs[0] || null;
}

// Find tab by numeric Chrome tab ID (approximate match via title/url)
async function findTabByNumericId(
  port: number,
  numericId: number
): Promise<CDPTab | null> {
  // CDP doesn't use numeric tab IDs, so we just find the best Gemini tab
  return findGeminiTab(port);
}

// === COMMAND HANDLER ===
async function handleCommand(
  command: any,
  port: number,
  profile: string,
  mqttClient: ReturnType<typeof mqtt.connect>
): Promise<any> {
  const t = topics(profile);

  try {
    switch (command.action) {
      case "list_tabs": {
        const allTabs = await cdpListTabs(port);
        const geminiTabs = allTabs.filter((t) =>
          t.url.includes("gemini.google.com")
        );
        return {
          tabs: geminiTabs.map((t) => ({
            id: t.id,
            title: t.title,
            url: t.url,
            active: false, // CDP doesn't track active state
          })),
          count: geminiTabs.length,
          profile,
          success: true,
        };
      }

      case "create_tab":
      case "new_tab": {
        const url = command.url || "https://gemini.google.com/app";
        const tab = await cdpNewTab(port, url);
        if (tab) {
          return { tabId: tab.id, url: tab.url, success: true };
        }
        return { error: "Failed to create tab" };
      }

      case "focus_tab": {
        if (!command.tabId) return { error: "tabId required" };
        const ok = await cdpActivateTab(port, command.tabId);
        return { success: ok, tabId: command.tabId };
      }

      case "close_tab": {
        if (!command.tabId) return { error: "tabId required" };
        const ok = await cdpCloseTab(port, command.tabId);
        return { success: ok };
      }

      case "navigate": {
        const tab = command.tabId
          ? (await cdpListTabs(port)).find((t) => t.id === command.tabId)
          : await findGeminiTab(port);
        if (!tab) return { error: "Tab not found" };
        const ok = await cdpNavigate(tab.webSocketDebuggerUrl, command.url);
        return { success: ok, url: command.url };
      }

      case "get_url": {
        const tab = command.tabId
          ? (await cdpListTabs(port)).find((t) => t.id === command.tabId)
          : await findGeminiTab(port);
        if (!tab) return { error: "No Gemini tab found" };
        return { url: tab.url, title: tab.title, success: true };
      }

      case "get_text": {
        const tab = command.tabId
          ? (await cdpListTabs(port)).find((t) => t.id === command.tabId)
          : await findGeminiTab(port);
        if (!tab) return { error: "No Gemini tab found" };
        const text = await cdpExecute(
          tab.webSocketDebuggerUrl,
          "document.body.innerText"
        );
        return { text, success: true };
      }

      case "get_html": {
        const tab = command.tabId
          ? (await cdpListTabs(port)).find((t) => t.id === command.tabId)
          : await findGeminiTab(port);
        if (!tab) return { error: "No Gemini tab found" };
        const html = await cdpExecute(
          tab.webSocketDebuggerUrl,
          "document.documentElement.outerHTML.substring(0, 50000)"
        );
        return { html, success: true };
      }

      case "get_state": {
        const tab = await findGeminiTab(port);
        if (!tab) return { loading: false, responseCount: 0, tool: null };
        const state = await cdpExecute(
          tab.webSocketDebuggerUrl,
          `(() => {
            const spinner = document.querySelector('mat-mdc-progress-spinner.mdc-circular-progress--indeterminate');
            let loading = false;
            if (spinner) {
              const rect = spinner.getBoundingClientRect();
              if (rect.top > 100 && rect.top < window.innerHeight) loading = true;
            }
            const streaming = document.querySelector('.streaming-indicator, [data-streaming="true"]');
            if (streaming) loading = true;
            const getActiveTool = () => {
              if (document.querySelector('img.youtube-icon')) return 'youtube';
              if (document.querySelector('img.tool-logo[src*="search"]')) return 'search';
              return null;
            };
            return {
              loading,
              responseCount: document.querySelectorAll('MESSAGE-CONTENT').length,
              tool: getActiveTool(),
              timestamp: Date.now()
            };
          })()`
        );
        // Publish to state topic
        mqttClient.publish(t.state, JSON.stringify(state));
        return state;
      }

      case "get_response": {
        const tab = await findGeminiTab(port);
        if (!tab) return { error: "No Gemini tab found" };
        const result = await cdpExecute(
          tab.webSocketDebuggerUrl,
          `(() => {
            const all = document.querySelectorAll('MESSAGE-CONTENT, message-content');
            if (all.length === 0) return { error: 'No responses found' };
            const last = all[all.length - 1];
            const answer = (last.innerText || '').trim();
            if (!answer || answer.length < 5) return { error: 'Response empty' };
            return { answer, count: all.length, success: true };
          })()`
        );
        if (result?.answer) {
          mqttClient.publish(
            t.answer,
            JSON.stringify({ answer: result.answer, timestamp: Date.now() }),
            { retain: true }
          );
        }
        return result;
      }

      case "chat": {
        const tab = await findGeminiTab(port);
        if (!tab) return { error: "No Gemini tab found" };
        if (!tab.url.includes("gemini.google.com"))
          return { error: "Not on Gemini page" };

        const chatText = command.text || "";
        const result = await cdpExecute(
          tab.webSocketDebuggerUrl,
          `(() => {
            try {
              const selectors = [
                'rich-textarea .ql-editor',
                'rich-textarea [contenteditable="true"]',
                '.ql-editor[contenteditable="true"]',
                'div[aria-label="Enter a prompt here"]',
                '[contenteditable="true"]'
              ];
              let input = null;
              for (const sel of selectors) {
                input = document.querySelector(sel);
                if (input) break;
              }
              if (!input) return { error: 'Input not found' };
              input.focus();
              if (input.innerHTML !== undefined) {
                input.innerHTML = '<p>${chatText.replace(/'/g, "\\'").replace(/\n/g, "<br>")}</p>';
              }
              input.dispatchEvent(new InputEvent('input', { bubbles: true, data: '${chatText.replace(/'/g, "\\'")}' }));
              setTimeout(() => {
                const sendBtn = document.querySelector('button[aria-label*="Send"], button[data-test-id="send-button"]');
                if (sendBtn) sendBtn.click();
                else input.dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter', code: 'Enter', keyCode: 13, bubbles: true }));
              }, 100);
              return { success: true, sent: '${chatText.substring(0, 50).replace(/'/g, "\\'")}' };
            } catch (e) {
              return { error: e.message };
            }
          })()`
        );
        return result;
      }

      case "wait_response": {
        const tab = await findGeminiTab(port);
        if (!tab) return { error: "No Gemini tab found" };
        const timeout = command.timeout || 30000;
        const result = await cdpExecute(
          tab.webSocketDebuggerUrl,
          `new Promise((resolve) => {
            const startTime = Date.now();
            const getResponses = () => document.querySelectorAll('MESSAGE-CONTENT, message-content');
            const initialCount = getResponses().length;
            let lastText = '';
            let stableCount = 0;
            const check = () => {
              const responses = getResponses();
              if (responses.length > initialCount) {
                const text = (responses[responses.length - 1].textContent || '').trim();
                if (text === lastText && text.length > 5) {
                  stableCount++;
                  if (stableCount >= 3) { resolve({ answer: text, success: true }); return true; }
                } else { lastText = text; stableCount = 0; }
              }
              if (Date.now() - startTime > ${timeout}) {
                resolve(lastText.length > 5 ? { answer: lastText, success: true } : { error: 'Timeout' });
                return true;
              }
              return false;
            };
            const interval = setInterval(() => { if (check()) clearInterval(interval); }, 500);
          })`,
          timeout + 5000
        );
        if (result?.answer) {
          mqttClient.publish(
            t.answer,
            JSON.stringify({ answer: result.answer, timestamp: Date.now() }),
            { retain: true }
          );
        }
        return result;
      }

      case "execute": {
        const tab = command.tabId
          ? (await cdpListTabs(port)).find((t) => t.id === command.tabId)
          : await findGeminiTab(port);
        if (!tab) return { error: "No tab found" };
        const result = await cdpExecute(
          tab.webSocketDebuggerUrl,
          command.code
        );
        return { result, success: true };
      }

      case "select_model": {
        const tab = await findGeminiTab(port);
        if (!tab) return { error: "No Gemini tab found" };
        const model = command.model || "pro";
        const result = await cdpExecute(
          tab.webSocketDebuggerUrl,
          `(async () => {
            const allBtns = Array.from(document.querySelectorAll('button'));
            let dropdownBtn = allBtns.find(b => b.className.includes('input-area-switch'));
            if (!dropdownBtn) dropdownBtn = allBtns.find(b => b.textContent.trim().match(/^(Pro|Fast|Thinking)$/));
            if (!dropdownBtn) return { error: 'Model dropdown not found' };
            dropdownBtn.click();
            await new Promise(r => setTimeout(r, 600));
            const modelMap = { 'fast': 'Fast', 'thinking': 'Thinking', 'pro': 'Pro' };
            const target = modelMap['${model}'] || '${model}';
            const options = document.querySelectorAll('[role="option"], [role="menuitem"]');
            for (const opt of options) {
              if (opt.textContent.includes(target)) { opt.click(); return { success: true, model: target }; }
            }
            return { error: 'Model not found: ' + target };
          })()`
        );
        return result;
      }

      case "click": {
        const tab = await findGeminiTab(port);
        if (!tab) return { error: "No tab found" };
        const result = await cdpExecute(
          tab.webSocketDebuggerUrl,
          `(() => {
            const el = document.querySelector('${command.selector}');
            if (el) { el.click(); return { success: true }; }
            return { error: 'Not found: ${command.selector}' };
          })()`
        );
        return result;
      }

      case "get_profile":
        return { profile, port, success: true };

      case "switch_profile":
        return {
          error:
            "switch_profile not supported in CDP mode. Start server with --profile flag.",
        };

      default:
        return { error: "Unknown action: " + command.action };
    }
  } catch (err: any) {
    return { error: err.message };
  }
}

// === MAIN ===
async function main() {
  const profiles = parseArgs();

  log.info("CDP Proxy daemon starting", { version: VERSION, profiles: profiles.map(p => `${p.name}:${p.port}`) });
  await emitPulseEvent("daemon:start", { daemon: "cdp-proxy", version: VERSION, profiles });

  // Check CDP connectivity for each profile
  for (const p of profiles) {
    const tabs = await cdpListTabs(p.port);
    if (tabs.length > 0) {
      log.info(`Profile connected`, { profile: p.name, port: p.port, tabs: tabs.length });
      tabs
        .filter((t) => t.url.includes("gemini"))
        .forEach((t) => log.debug("Gemini tab found", { title: t.title, url: t.url.substring(0, 60) }));
    } else {
      log.warn(`Profile not connected — launch Chrome with --remote-debugging-port=${p.port}`, { profile: p.name, port: p.port });
    }
  }

  // Connect to MQTT
  const client = mqtt.connect(MQTT_URL, {
    clientId: "cdp-proxy-" + Date.now(),
    will: {
      topic: topics("default").status,
      payload: JSON.stringify({
        status: "offline",
        timestamp: Date.now(),
        version: VERSION,
        mode: "cdp",
      }),
      qos: 0,
      retain: true,
    },
  });

  client.on("connect", async () => {
    log.info("MQTT connected", { url: MQTT_URL });
    await emitPulseEvent("daemon:connected", { daemon: "cdp-proxy", broker: MQTT_URL });

    // Subscribe to command topics for all profiles
    for (const p of profiles) {
      const t = topics(p.name);
      client.subscribe(t.command);
      log.debug("Subscribed to command topic", { topic: t.command });

      // Publish online status
      client.publish(
        t.status,
        JSON.stringify({
          status: "online",
          timestamp: Date.now(),
          version: VERSION,
          profile: p.name,
          port: p.port,
          mode: "cdp",
        }),
        { retain: true }
      );

      // Clear stale retained response
      client.publish(t.response, "", { retain: true });
    }

    log.info("CDP Proxy ready — listening for commands");
  });

  client.on("message", async (topic, message) => {
    if (!message.length) return; // Skip empty (retained clear)

    let command: any;
    try {
      command = JSON.parse(message.toString());
    } catch {
      return;
    }

    // Determine which profile this command is for
    let matchedProfile: ProfileConfig = profiles[0]!;
    for (const p of profiles) {
      if (topic === topics(p.name).command) {
        matchedProfile = p;
        break;
      }
    }

    const t = topics(matchedProfile.name);

    // Skip state polls from extension (noisy)
    if (command.id?.startsWith("state_poll_")) return;

    const actionLabel = command.action || "unknown";
    const shortId = (command.id || "").substring(0, 20);

    // HYBRID: Write actions are handled by the extension (both listen on same command topic)
    // CDP server ignores write actions -- extension picks them up directly
    if (WRITE_ACTIONS.has(command.action)) {
      log.debug("Delegating to extension", { profile: matchedProfile.name, action: actionLabel, id: shortId });
      return; // Extension will handle and publish response
    }

    log.info("Handling command via CDP", { profile: matchedProfile.name, action: actionLabel, id: shortId });

    // Handle READ command via CDP
    const result = await handleCommand(
      command,
      matchedProfile.port,
      matchedProfile.name,
      client
    );

    // Publish response (NOT retained)
    const response = {
      id: command.id,
      action: command.action,
      ...result,
      source: 'cdp',
      profile: matchedProfile.name,
      timestamp: Date.now(),
    };
    client.publish(t.response, JSON.stringify(response));

    // Log result
    if (result.error) {
      log.warn("Command failed", { action: actionLabel, error: result.error });
    } else {
      log.debug("Command succeeded", { action: actionLabel });
    }
  });

  client.on("error", (err) => {
    log.error("MQTT error", { error: err.message });
    emitPulseEvent("daemon:error", { daemon: "cdp-proxy", error: err.message });
  });

  // Periodic page info publish (like the extension did)
  setInterval(async () => {
    for (const p of profiles) {
      const tab = await findGeminiTab(p.port);
      if (tab) {
        const t = topics(p.name);
        client.publish(
          t.page,
          JSON.stringify({
            url: tab.url,
            title: tab.title,
            timestamp: Date.now(),
          }),
          { retain: true }
        );
      }
    }
  }, 10000);

  // Graceful shutdown
  process.on("SIGINT", async () => {
    log.info("Shutting down CDP Proxy daemon");
    await emitPulseEvent("daemon:stop", { daemon: "cdp-proxy", reason: "SIGINT" });

    for (const p of profiles) {
      const t = topics(p.name);
      client.publish(
        t.status,
        JSON.stringify({
          status: "offline",
          timestamp: Date.now(),
          version: VERSION,
          mode: "cdp",
        }),
        { retain: true }
      );
    }
    setTimeout(() => {
      client.end();
      process.exit(0);
    }, 500);
  });
}

main().catch(async (err) => {
  log.error("Fatal error", { error: err.message });
  await emitPulseEvent("daemon:crash", { daemon: "cdp-proxy", error: err.message });
  process.exit(1);
});
