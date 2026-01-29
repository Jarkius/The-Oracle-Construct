# Parallel Browser Automation Research: Matrix Gemini Tool

> **Date:** 2026-01-29
> **Session:** Parallel browser automation for multi-Gemini research
> **Focus:** True parallel execution with separate windows for macOS + Brave

---

## Executive Summary

For building a Matrix-native parallel Gemini research tool, **concurrent-browser-mcp** is the recommended approach. It provides true multi-instance concurrency with complete resource isolation, built on Playwright, specifically designed for parallel browser operations.

**Winner:** concurrent-browser-mcp (Playwright-based)
**Runner-up:** Puppeteer-cluster with CONCURRENCY_BROWSER
**Native macOS:** Limited (AppleScript/JXA has significant limitations)

---

## Comparison Matrix

| Approach | True Parallel | Separate Windows | Brave Support | macOS Compatible | Complexity | Recommendation |
|----------|--------------|------------------|---------------|------------------|------------|----------------|
| **concurrent-browser-mcp** | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes | Low | **Best Choice** |
| **Puppeteer-cluster** | ✅ Yes | ✅ Yes (BROWSER mode) | ✅ Yes | ✅ Yes | Medium | Strong Alternative |
| **Playwright multi-context** | ⚠️ Shared browser | ❌ Tabs only | ✅ Yes | ✅ Yes | Low | Good for isolation |
| **Selenium Grid** | ✅ Yes | ✅ Yes | ⚠️ Via WebDriver | ✅ Yes | High | Overkill |
| **CDP Direct** | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes | High | Too low-level |
| **AppleScript/JXA** | ❌ Limited | ⚠️ Unreliable | ✅ Yes | ✅ Native | High | Not recommended |

---

## 1. concurrent-browser-mcp (RECOMMENDED)

### Overview

A purpose-built MCP server for parallel browser automation using Playwright. Discovered via MCP market, it's specifically designed for multi-instance concurrency with complete resource isolation.

**GitHub:** [sailaoda/concurrent-browser-mcp](https://github.com/sailaoda/concurrent-browser-mcp)
**MCP Market:** [Concurrent Browser](https://mcpmarket.com/server/concurrent-browser)

### Key Features

- **Multi-instance concurrency** with complete resource isolation
- **Parallel concurrent processing** with automatic instance lifecycle management
- **Dynamic browser creation** with automatic cleanup of timed-out instances
- **Cross-platform support** for Chromium, Firefox, and WebKit
- **Custom configuration** including max instances, browser type, headless mode

### Installation

```bash
# Global installation
npm install -g concurrent-browser-mcp

# Or use directly via npx
npx concurrent-browser-mcp

# Custom configuration
npx concurrent-browser-mcp --max-instances 25 --browser firefox --headless false
```

### Code Example

```javascript
// Via MCP (Claude Code integration)
// The MCP server handles instance management automatically

// Example MCP configuration in .claude.json:
{
  "mcpServers": {
    "concurrent-browser": {
      "command": "npx",
      "args": [
        "concurrent-browser-mcp",
        "--max-instances", "5",
        "--browser", "chromium",
        "--executable-path", "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser"
      ]
    }
  }
}

// Claude Code can then orchestrate via MCP tools:
// - browser_create_instance(id)
// - browser_navigate(id, url)
// - browser_execute(id, script)
// - browser_close_instance(id)
```

### Pros

- Purpose-built for parallel operations
- Automatic resource cleanup prevents memory leaks
- Works seamlessly with Claude Code via MCP
- Configurable instance limits
- Supports Brave via --executable-path

### Cons

- Relatively new project (less battle-tested)
- Requires MCP infrastructure
- Documentation is sparse

---

## 2. Puppeteer-cluster (STRONG ALTERNATIVE)

### Overview

A mature library for running pools of Puppeteer instances in parallel, with multiple concurrency models.

**GitHub:** [thomasdondorf/puppeteer-cluster](https://github.com/thomasdondorf/puppeteer-cluster)

### Concurrency Models

1. **CONCURRENCY_PAGE**: Each worker manages a single page (shared browser context)
2. **CONCURRENCY_CONTEXT**: Each worker handles a distinct browser context (incognito-like)
3. **CONCURRENCY_BROWSER**: Each worker opens a NEW browser window (true isolation)

**For Matrix Gemini Tool:** Use **CONCURRENCY_BROWSER** for complete isolation.

### Installation

```bash
npm install puppeteer-cluster puppeteer
```

### Code Example

```javascript
const { Cluster } = require('puppeteer-cluster');

(async () => {
  // Launch cluster with separate browser instances
  const cluster = await Cluster.launch({
    concurrency: Cluster.CONCURRENCY_BROWSER,
    maxConcurrency: 4, // 4 separate Brave windows
    puppeteerOptions: {
      executablePath: '/Applications/Brave Browser.app/Contents/MacOS/Brave Browser',
      headless: false,
      args: ['--window-size=800,600', '--window-position=0,0']
    }
  });

  // Define task: Open Gemini and run research
  await cluster.task(async ({ page, data }) => {
    const { query, windowIndex } = data;

    // Position windows side-by-side
    const x = windowIndex * 810;
    await page.setViewport({ width: 800, height: 600 });

    // Navigate to Gemini
    await page.goto('https://gemini.google.com', { waitUntil: 'networkidle2' });

    // Find prompt box
    await page.waitForSelector('textarea[placeholder*="Enter a prompt"]');

    // Type query
    await page.type('textarea', query);
    await page.keyboard.press('Enter');

    // Wait for response
    await page.waitForTimeout(15000); // Gemini thinking time

    // Extract response
    const response = await page.evaluate(() => {
      const responseDiv = document.querySelector('.response-container');
      return responseDiv ? responseDiv.innerText : 'No response';
    });

    console.log(`Window ${windowIndex}: ${response.substring(0, 100)}...`);

    return { query, response };
  });

  // Queue parallel research tasks
  cluster.queue({ query: 'Explain quantum entanglement', windowIndex: 0 });
  cluster.queue({ query: 'Latest AI breakthroughs 2026', windowIndex: 1 });
  cluster.queue({ query: 'Neural network fundamentals', windowIndex: 2 });
  cluster.queue({ query: 'Transformer architecture', windowIndex: 3 });

  // Wait for all tasks to complete
  await cluster.idle();
  await cluster.close();
})();
```

### Advanced: Matrix Integration

```javascript
// Save to psi/learn/inbox with timestamps
const fs = require('fs').promises;
const path = require('path');

await cluster.task(async ({ page, data }) => {
  const { query } = data;

  // ... (navigation and extraction code from above)

  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const filename = `gemini_${query.replace(/\s+/g, '_')}_${timestamp}.md`;
  const filePath = path.join(
    process.env.HOME,
    'workspace/The-matrix/psi/learn/inbox',
    filename
  );

  const markdown = `# Gemini Research: ${query}

> **Date:** ${new Date().toISOString()}
> **Query:** ${query}

## Response

${response}

---

#gemini #parallel-research #auto-generated
`;

  await fs.writeFile(filePath, markdown);
  console.log(`Saved: ${filename}`);

  return { query, response, saved: filePath };
});
```

### Pros

- Mature, battle-tested library
- CONCURRENCY_BROWSER provides true isolation
- Excellent error handling and retry mechanisms
- Works with Brave via executablePath
- Can position windows programmatically

### Cons

- Not MCP-native (requires Node.js script)
- Higher memory usage (full browser per instance)
- Requires manual orchestration from Claude Code

---

## 3. Playwright Multi-Context

### Overview

Playwright's native approach using BrowserContexts for isolated sessions within a single browser instance.

**Docs:** [Playwright Isolation](https://playwright.dev/docs/browser-contexts)

### Code Example

```javascript
const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({
    executablePath: '/Applications/Brave Browser.app/Contents/MacOS/Brave Browser',
    headless: false
  });

  // Create isolated contexts (like incognito tabs)
  const context1 = await browser.newContext();
  const context2 = await browser.newContext();
  const context3 = await browser.newContext();

  // Create pages in each context
  const page1 = await context1.newPage();
  const page2 = await context2.newPage();
  const page3 = await context3.newPage();

  // Navigate all pages to Gemini in parallel
  await Promise.all([
    page1.goto('https://gemini.google.com'),
    page2.goto('https://gemini.google.com'),
    page3.goto('https://gemini.google.com')
  ]);

  // Type different queries in parallel
  await Promise.all([
    (async () => {
      await page1.fill('textarea[placeholder*="Enter"]', 'Query 1');
      await page1.press('textarea', 'Enter');
    })(),
    (async () => {
      await page2.fill('textarea[placeholder*="Enter"]', 'Query 2');
      await page2.press('textarea', 'Enter');
    })(),
    (async () => {
      await page3.fill('textarea[placeholder*="Enter"]', 'Query 3');
      await page3.press('textarea', 'Enter');
    })()
  ]);

  // Wait for responses (10 seconds)
  await new Promise(resolve => setTimeout(resolve, 10000));

  // Extract responses in parallel
  const results = await Promise.all([
    page1.textContent('.response-container'),
    page2.textContent('.response-container'),
    page3.textContent('.response-container')
  ]);

  console.log(results);

  await browser.close();
})();
```

### Pros

- Fast context creation (lightweight)
- Complete session isolation (cookies, storage)
- Native Playwright support
- Works with existing Playwright MCP

### Cons

- **Opens TABS, not separate windows** (by default)
- Cannot programmatically detach tabs into windows (GitHub issue #10299)
- Shared browser process (less resource isolation)

**Verdict:** Good for isolated sessions, but NOT for separate visible windows.

---

## 4. Selenium Grid

### Overview

Distributed test execution framework, routes WebDriver commands to multiple browser nodes.

**Docs:** [Selenium Grid Tutorial](https://www.browserstack.com/guide/selenium-grid-tutorial)

### Architecture

```
Hub (localhost:4444)
  ├── Node 1 (Chrome)
  ├── Node 2 (Firefox)
  └── Node 3 (Brave)
```

### Setup

```bash
# Start hub
java -jar selenium-server.jar hub

# Start node
java -jar selenium-server.jar node --detect-drivers true
```

### Code Example

```javascript
const { Builder } = require('selenium-webdriver');
const chrome = require('selenium-webdriver/chrome');

async function runParallelTests() {
  const options = new chrome.Options();
  options.setChromeBinaryPath('/Applications/Brave Browser.app/Contents/MacOS/Brave Browser');

  const promises = [1, 2, 3].map(async (index) => {
    const driver = await new Builder()
      .forBrowser('chrome')
      .setChromeOptions(options)
      .usingServer('http://localhost:4444')
      .build();

    try {
      await driver.get('https://gemini.google.com');
      // ... automation logic
    } finally {
      await driver.quit();
    }
  });

  await Promise.all(promises);
}
```

### Pros

- Industry standard for distributed testing
- Scales to hundreds of browsers
- Cross-platform, cross-browser

### Cons

- **Overkill** for local parallel automation
- Complex setup (hub + nodes)
- Higher latency (network overhead)
- Not MCP-compatible

**Verdict:** Use only for large-scale distributed testing, not local parallel research.

---

## 5. Chrome DevTools Protocol (CDP) Direct

### Overview

Low-level protocol for controlling Chromium-based browsers via WebSocket connections.

**Docs:** [Chrome DevTools Protocol](https://chromedevtools.github.io/devtools-protocol/)

### Architecture

```
Your Script
  ├── WebSocket → Browser Instance 1 (localhost:9222)
  ├── WebSocket → Browser Instance 2 (localhost:9223)
  └── WebSocket → Browser Instance 3 (localhost:9224)
```

### Code Example

```javascript
const CDP = require('chrome-remote-interface');
const { spawn } = require('child_process');

async function launchBrave(port) {
  return spawn('/Applications/Brave Browser.app/Contents/MacOS/Brave Browser', [
    `--remote-debugging-port=${port}`,
    '--user-data-dir=/tmp/brave-' + port,
    '--no-first-run'
  ]);
}

async function runParallelCDP() {
  // Launch 3 Brave instances on different ports
  const processes = [
    await launchBrave(9222),
    await launchBrave(9223),
    await launchBrave(9224)
  ];

  // Wait for startup
  await new Promise(resolve => setTimeout(resolve, 2000));

  // Connect to each instance
  const clients = await Promise.all([
    CDP({ port: 9222 }),
    CDP({ port: 9223 }),
    CDP({ port: 9224 })
  ]);

  // Enable domains for each client
  await Promise.all(clients.map(async (client) => {
    await client.Page.enable();
    await client.Runtime.enable();
  }));

  // Navigate in parallel
  await Promise.all(clients.map(async (client, index) => {
    await client.Page.navigate({ url: 'https://gemini.google.com' });
  }));

  // Cleanup
  await Promise.all(clients.map(client => client.close()));
  processes.forEach(proc => proc.kill());
}
```

### Pros

- Direct browser control (no abstraction layers)
- Multiple independent browser processes
- Full access to DevTools features

### Cons

- **Very low-level** (must handle everything manually)
- Complex WebSocket lifecycle management
- No high-level APIs (must send CDP commands)
- Steep learning curve

**Verdict:** Only use if you need absolute control and Playwright/Puppeteer won't suffice.

---

## 6. AppleScript / JXA (macOS Native)

### Overview

macOS native automation using AppleScript or JavaScript for Automation (JXA).

**GitHub:** [steipete/macos-automator-mcp](https://github.com/steipete/macos-automator-mcp)

### Code Example (JXA)

```javascript
// Open multiple Brave windows
const brave = Application('Brave Browser');

// Open 3 windows
for (let i = 0; i < 3; i++) {
  brave.Window().make();
  delay(1); // Wait 1 second
}

// Get all windows
const windows = brave.windows();

// Navigate each window to Gemini
windows.forEach((window, index) => {
  const tab = window.activeTab();
  tab.url = 'https://gemini.google.com';
});
```

### AppleScript Example

```applescript
tell application "Brave Browser"
  activate
  make new window
  delay 2
  set URL of active tab of front window to "https://gemini.google.com"
end tell
```

### Known Issues

- **Multiple window handling is unreliable** (source: [vitorgalvao/5392178](https://gist.github.com/vitorgalvao/5392178))
- AppleScript "not working when there are two windows of a browser"
- JXA is considered "dead" by community (sparse documentation, no active development)
- Cannot easily control page content (only URLs and basic navigation)

### Pros

- Native macOS integration
- No external dependencies
- Can control any macOS app

### Cons

- **Unreliable with multiple windows**
- Limited to basic browser control (URLs, tabs)
- Cannot interact with page content (no DOM access)
- JXA development is stagnant

**Verdict:** Not recommended for complex browser automation. Use only for simple URL launching.

---

## Recommended Architecture for Matrix Gemini Tool

### Option A: MCP-Native (Best Integration)

```
Claude Code (Orchestrator)
      │
      ▼
concurrent-browser-mcp
      │
      ├── Browser Instance 1 (Brave) → Gemini Query 1
      ├── Browser Instance 2 (Brave) → Gemini Query 2
      ├── Browser Instance 3 (Brave) → Gemini Query 3
      └── Browser Instance 4 (Brave) → Gemini Query 4
      │
      ▼
Save to psi/learn/inbox/*.md
```

**Implementation:**

1. Install concurrent-browser-mcp
2. Configure in .claude.json with Brave path
3. Claude Code orchestrates via MCP tools
4. Results saved automatically to inbox

**Pros:** Seamless MCP integration, auto-cleanup, configurable limits

---

### Option B: Puppeteer-cluster (Most Powerful)

```
Claude Code
      │
      ▼
Node.js Script (research.js)
      │
      ▼
Puppeteer Cluster (CONCURRENCY_BROWSER)
      │
      ├── Brave Window 1 → Gemini
      ├── Brave Window 2 → Gemini
      ├── Brave Window 3 → Gemini
      └── Brave Window 4 → Gemini
      │
      ▼
Save to psi/learn/inbox/*.md
```

**Implementation:**

```bash
# Create research script
cat > ~/workspace/The-matrix/psi/active/gemini-parallel-research.js << 'EOF'
const { Cluster } = require('puppeteer-cluster');
const fs = require('fs').promises;
const path = require('path');

async function parallelGeminiResearch(queries) {
  const cluster = await Cluster.launch({
    concurrency: Cluster.CONCURRENCY_BROWSER,
    maxConcurrency: queries.length,
    puppeteerOptions: {
      executablePath: '/Applications/Brave Browser.app/Contents/MacOS/Brave Browser',
      headless: false,
      args: ['--window-size=800,600']
    }
  });

  await cluster.task(async ({ page, data }) => {
    const { query, index } = data;

    await page.goto('https://gemini.google.com', { waitUntil: 'networkidle2' });
    await page.waitForSelector('textarea[placeholder*="Enter"]');
    await page.type('textarea', query);
    await page.keyboard.press('Enter');
    await page.waitForTimeout(15000);

    const response = await page.evaluate(() => {
      return document.querySelector('.response-container')?.innerText || 'No response';
    });

    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const filename = `gemini_${query.replace(/\s+/g, '_')}_${timestamp}.md`;
    const filePath = path.join(
      process.env.HOME,
      'workspace/The-matrix/psi/learn/inbox',
      filename
    );

    await fs.writeFile(filePath, `# ${query}\n\n${response}\n\n#gemini #parallel`);
    return { query, response };
  });

  queries.forEach((query, index) => {
    cluster.queue({ query, index });
  });

  await cluster.idle();
  await cluster.close();
}

// CLI usage
const queries = process.argv.slice(2);
parallelGeminiResearch(queries);
EOF

# Make executable
chmod +x ~/workspace/The-matrix/psi/active/gemini-parallel-research.js

# Run from Claude Code
node ~/workspace/The-matrix/psi/active/gemini-parallel-research.js \
  "quantum computing" \
  "AI safety" \
  "neural networks"
```

**Pros:** Most control, battle-tested, window positioning

---

### Option C: Hybrid (Flexibility)

```
Claude Code
      │
      ├─► Simple tasks → Playwright MCP (single browser)
      │
      └─► Parallel tasks → concurrent-browser-mcp OR Puppeteer-cluster
```

Use Playwright MCP for single-tab research, escalate to concurrent-browser-mcp or Puppeteer-cluster when parallelism is needed.

---

## Final Recommendations

### For Matrix Gemini Tool:

1. **Primary:** concurrent-browser-mcp
   - Reason: MCP-native, auto-cleanup, designed for parallel operations
   - Trade-off: Newer project, less documentation

2. **Alternative:** Puppeteer-cluster with CONCURRENCY_BROWSER
   - Reason: Mature, flexible, window positioning
   - Trade-off: Requires Node.js script (not MCP-direct)

3. **Fallback:** Playwright multi-context via existing MCP
   - Reason: Already installed, good isolation
   - Trade-off: Tabs only, no separate windows

### Avoid:

- Selenium Grid (overkill for local use)
- CDP Direct (too low-level)
- AppleScript/JXA (unreliable with multiple windows)

---

## Implementation Checklist

- [ ] Install concurrent-browser-mcp via npm
- [ ] Configure .claude.json with Brave executable path
- [ ] Test single instance creation via MCP
- [ ] Test parallel instance creation (3-4 browsers)
- [ ] Verify Gemini login/session persistence
- [ ] Test typing and response extraction
- [ ] Implement auto-save to psi/learn/inbox
- [ ] Add error handling and retry logic
- [ ] Create /gemini-parallel skill wrapper
- [ ] Document selectors in skill README
- [ ] Test memory usage with max instances
- [ ] Add voice announcements via Matrix voice.sh

---

## Code Snippets for Matrix Integration

### Voice Integration

```bash
# Announce parallel research start
sh ~/workspace/The-matrix/psi/matrix/voice.sh \
  "Morpheus online. Opening 4 parallel Gemini portals." \
  "Oracle"

# Announce completion
sh ~/workspace/The-matrix/psi/matrix/voice.sh \
  "Research complete. 4 insights harvested." \
  "Oracle"
```

### Auto-save to Inbox

```javascript
// Within Puppeteer-cluster task
const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
const slug = query.toLowerCase().replace(/\s+/g, '_').substring(0, 50);
const filename = `gemini_${slug}_${timestamp}.md`;
const inboxPath = path.join(
  process.env.HOME,
  'workspace/The-matrix/psi/learn/inbox',
  filename
);

const markdown = `# Gemini Research: ${query}

> **Date:** ${new Date().toISOString()}
> **Source:** Parallel Gemini Browser Automation
> **Agent:** Morpheus

## Query

${query}

## Response

${response}

---

## Metadata

- **Timestamp:** ${timestamp}
- **Window:** ${windowIndex}
- **Tags:** #gemini #parallel-research #auto-generated

## Next Steps

- [ ] Distill insights to permanent memory
- [ ] Cross-reference with existing knowledge
- [ ] Generate follow-up questions
`;

await fs.writeFile(inboxPath, markdown);
console.log(`✅ Saved: ${filename}`);
```

---

## Browser Window Positioning (macOS)

```javascript
// Puppeteer-cluster: Position windows in grid
const positions = [
  { x: 0, y: 0 },       // Top-left
  { x: 810, y: 0 },     // Top-right
  { x: 0, y: 650 },     // Bottom-left
  { x: 810, y: 650 }    // Bottom-right
];

puppeteerOptions: {
  args: [
    `--window-position=${positions[index].x},${positions[index].y}`,
    '--window-size=800,600'
  ]
}
```

---

## Memory Management

```javascript
// Limit concurrent instances to avoid memory pressure
const maxConcurrency = os.totalmem() > 16 * 1024 * 1024 * 1024
  ? 8  // 16GB+ RAM: 8 browsers
  : 4; // <16GB RAM: 4 browsers

const cluster = await Cluster.launch({
  concurrency: Cluster.CONCURRENCY_BROWSER,
  maxConcurrency,
  timeout: 60000, // 60s timeout per task
  retryLimit: 2,
  retryDelay: 3000
});
```

---

## Sources

- [concurrent-browser-mcp GitHub](https://github.com/sailaoda/concurrent-browser-mcp)
- [Concurrent Browser MCP Market](https://mcpmarket.com/server/concurrent-browser)
- [Puppeteer Cluster GitHub](https://github.com/thomasdondorf/puppeteer-cluster)
- [Playwright Multi-Context Guide](https://dev.to/raghwendrasonu/using-multiple-browser-contexts-in-playwright-with-real-life-examples--3mga)
- [Playwright Isolation Docs](https://playwright.dev/docs/browser-contexts)
- [Selenium Grid Tutorial](https://www.browserstack.com/guide/selenium-grid-tutorial)
- [Chrome DevTools Protocol Docs](https://chromedevtools.github.io/devtools-protocol/)
- [macOS Automator MCP](https://github.com/steipete/macos-automator-mcp)
- [AppleScript Browser Automation Gist](https://gist.github.com/vitorgalvao/5392178)
- [Playwright Multiple Browser Instances Issue](https://github.com/microsoft/playwright/issues/8535)
- [Building Browser Pool with Playwright](https://medium.com/@devcriston/building-a-robust-browser-pool-for-web-automation-with-playwright-2c750eb0a8e7)
- [Puppeteer Cluster Setup Guide](https://www.webshare.io/academy-article/puppeteer-cluster)
- [Brave Multiple Instances Discussion](https://community.brave.app/t/can-two-separate-instances-of-brave-be-run-simultaneously/238595)

---

## Tags

#gemini #parallel-automation #browser-automation #playwright #puppeteer #brave #mcp #research

---

*"There is no spoon. There are only browser instances."*

*Morpheus, 2026-01-29*
