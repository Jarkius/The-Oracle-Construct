#!/usr/bin/env node

/**
 * Matrix Gemini Parallel Research Tool
 *
 * Runs multiple Gemini browser instances in parallel for simultaneous research.
 * Uses Puppeteer Cluster with CONCURRENCY_BROWSER for true isolation.
 *
 * Usage:
 *   node gemini-parallel-research.js "query1" "query2" "query3"
 *   node gemini-parallel-research.js --youtube "URL1" "URL2"
 *
 * Architecture:
 *   Puppeteer Cluster → N Brave Windows → Gemini → psi/learn/inbox/*.md
 */

const { Cluster } = require('puppeteer-cluster');
const fs = require('fs').promises;
const path = require('path');
const os = require('os');
const { exec } = require('child_process');
const util = require('util');

const execPromise = util.promisify(exec);

// ============================================================================
// Configuration
// ============================================================================

const CONFIG = {
  // Browser: Brave (with stealth) or set BROWSER_PATH for Chrome
  BROWSER_PATH: process.env.BROWSER_PATH ||
    '/Applications/Brave Browser.app/Contents/MacOS/Brave Browser',
  GEMINI_URL: 'https://gemini.google.com/app',
  MATRIX_INBOX: path.join(process.env.HOME, 'workspace/The-matrix/psi/learn/inbox'),
  VOICE_SCRIPT: path.join(process.env.HOME, 'workspace/The-matrix/psi/matrix/voice.sh'),

  // DEDICATED automation profile (separate from main browser)
  // First run: sign in manually. Subsequent runs: session remembered.
  USER_DATA_DIR: process.env.GEMINI_PROFILE_DIR ||
    path.join(process.env.HOME, '.gemini-automation-profile'),
  PROFILE_DIR: 'Default',

  // Cookie file for backup/manual injection (fallback)
  COOKIES_FILE: path.join(process.env.HOME, 'workspace/The-matrix/psi/active/.gemini-cookies.json'),

  // Environment variable overrides
  HEADLESS: process.env.GEMINI_HEADLESS === 'true' || process.argv.includes('--headless'),
  VERBOSE: process.env.GEMINI_VERBOSE === 'true' || process.argv.includes('--verbose'),

  // Memory-adaptive concurrency (env override available)
  MAX_CONCURRENCY: parseInt(process.env.GEMINI_MAX_CONCURRENCY) ||
    (os.totalmem() > 16 * 1024 * 1024 * 1024 ? 8 : 4),

  WINDOW_SIZE: { width: 800, height: 600 },

  // Gemini selectors (updated 2026-01-29)
  // Multiple fallback selectors for resilience
  SELECTORS: {
    promptBox: [
      'textarea[placeholder*="Enter"]',
      'textarea[aria-label*="prompt"]',
      'div[contenteditable="true"]',
      'textarea',
      '.ql-editor',
      'rich-textarea textarea'
    ],
    responseContainer: [
      '.response-container',
      '.message-content',
      '.model-response',
      '[data-message-author-role="model"]',
      '.markdown-body'
    ],
    stopButton: 'button[aria-label*="Stop"]',
    newChat: 'button[aria-label*="New chat"]'
  },

  TIMEOUTS: {
    navigation: parseInt(process.env.GEMINI_TIMEOUT_NAVIGATION) || 30000,
    thinkingTime: parseInt(process.env.GEMINI_TIMEOUT_RESPONSE) || 20000,
    youtubeTime: parseInt(process.env.GEMINI_TIMEOUT_YOUTUBE) || 45000
  },

  // Retry configuration
  RETRY: {
    attempts: parseInt(process.env.GEMINI_RETRY_ATTEMPTS) || 3,
    baseDelay: 2000,
    maxDelay: 8000,
    jitter: 0.2
  }
};

// ============================================================================
// Error Classification
// ============================================================================

const ERROR_TYPES = {
  NETWORK: { retryable: true, delay: 5000, pattern: /net::ERR|ECONNREFUSED|ETIMEDOUT/ },
  TIMEOUT: { retryable: true, delay: 3000, pattern: /timeout|TimeoutError/ },
  RATE_LIMIT: { retryable: true, delay: 30000, pattern: /429|rate.?limit/i },
  AUTH: { retryable: false, fallback: 'api', pattern: /auth|login|sign.?in/i },
  BROWSER_CRASH: { retryable: true, delay: 2000, pattern: /crashed|disconnected|closed/ },
  SELECTOR: { retryable: true, delay: 2000, pattern: /selector|element|waiting/ },
  UNKNOWN: { retryable: false, fallback: 'api' }
};

function classifyError(error) {
  const msg = error.message || String(error);
  for (const [type, config] of Object.entries(ERROR_TYPES)) {
    if (config.pattern && config.pattern.test(msg)) {
      return { type, ...config };
    }
  }
  return { type: 'UNKNOWN', ...ERROR_TYPES.UNKNOWN };
}

// ============================================================================
// Retry with Exponential Backoff
// ============================================================================

async function withRetry(fn, options = CONFIG.RETRY) {
  let lastError;

  for (let attempt = 0; attempt < options.attempts; attempt++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error;
      const errorInfo = classifyError(error);

      if (!errorInfo.retryable || attempt === options.attempts - 1) {
        if (CONFIG.VERBOSE) {
          console.log(`❌ Non-retryable error (${errorInfo.type}): ${error.message}`);
        }
        throw error;
      }

      // Exponential backoff with jitter
      const baseDelay = errorInfo.delay || options.baseDelay;
      const delay = Math.min(
        baseDelay * Math.pow(2, attempt) * (1 + Math.random() * options.jitter),
        options.maxDelay
      );

      console.log(`⚠️  Retry ${attempt + 1}/${options.attempts} (${errorInfo.type}) after ${Math.round(delay)}ms...`);
      await new Promise(r => setTimeout(r, delay));
    }
  }

  throw lastError;
}

// ============================================================================
// Voice Integration
// ============================================================================

async function speak(message, agent = 'Oracle') {
  try {
    await execPromise(`sh "${CONFIG.VOICE_SCRIPT}" "${message}" "${agent}"`);
  } catch (err) {
    console.log(`🔇 Voice: ${message}`);
  }
}

// ============================================================================
// Cookie Management for Parallel Auth
// ============================================================================

async function saveCookies(page) {
  try {
    // Get cookies from all Google domains for full auth
    const allCookies = await page.cookies(
      'https://gemini.google.com',
      'https://google.com',
      'https://accounts.google.com',
      'https://www.google.com'
    );

    // Include all Google cookies, especially auth-related ones
    const authCookieNames = ['SID', 'SSID', 'HSID', 'APISID', 'SAPISID', 'LSID', 'NID',
      '__Secure-1PSID', '__Secure-3PSID', '__Secure-1PAPISID', '__Secure-3PAPISID',
      '__Secure-1PSIDTS', '__Secure-3PSIDTS', '__Secure-1PSIDCC', '__Secure-3PSIDCC',
      'COMPASS', 'SIDCC', '__Secure-ENID'];

    const geminiCookies = allCookies.filter(c =>
      c.domain.includes('google.com') ||
      authCookieNames.some(name => c.name.includes(name))
    );

    await fs.writeFile(CONFIG.COOKIES_FILE, JSON.stringify(geminiCookies, null, 2));
    console.log(`🍪 Saved ${geminiCookies.length} cookies (${allCookies.length} total scanned)`);

    // Check for auth cookies
    const hasAuth = geminiCookies.some(c => authCookieNames.includes(c.name));
    if (!hasAuth) {
      console.log(`⚠️  Warning: No auth cookies found. Make sure you're signed in to Google.`);
    }
    return true;
  } catch (err) {
    console.error(`❌ Failed to save cookies: ${err.message}`);
    return false;
  }
}

async function loadCookies() {
  try {
    const data = await fs.readFile(CONFIG.COOKIES_FILE, 'utf-8');
    const cookies = JSON.parse(data);
    console.log(`🍪 Loaded ${cookies.length} cookies from cache`);
    return cookies;
  } catch (err) {
    if (err.code !== 'ENOENT') {
      console.error(`⚠️  Could not load cookies: ${err.message}`);
    }
    return null;
  }
}

async function injectCookies(page, cookies) {
  if (!cookies || cookies.length === 0) return false;
  try {
    await page.setCookie(...cookies);
    return true;
  } catch (err) {
    console.error(`⚠️  Could not inject cookies: ${err.message}`);
    return false;
  }
}

async function cookiesExist() {
  try {
    await fs.access(CONFIG.COOKIES_FILE);
    return true;
  } catch {
    return false;
  }
}

// ============================================================================
// Window Positioning (macOS)
// ============================================================================

function getWindowPosition(index, total) {
  const positions = [
    { x: 0, y: 0 },       // Top-left
    { x: 810, y: 0 },     // Top-right
    { x: 0, y: 650 },     // Bottom-left
    { x: 810, y: 650 }    // Bottom-right
  ];

  if (index < positions.length) {
    return positions[index];
  }

  // For >4 windows, cascade
  return {
    x: (index % 4) * 200,
    y: Math.floor(index / 4) * 200
  };
}

// ============================================================================
// Save Research to Matrix Inbox
// ============================================================================

async function saveToInbox(query, response, metadata = {}) {
  const timestamp = new Date().toISOString();
  const slug = query
    .toLowerCase()
    .replace(/[^\w\s-]/g, '')
    .replace(/\s+/g, '_')
    .substring(0, 50);

  const filename = `gemini_${slug}_${timestamp.replace(/[:.]/g, '-')}.md`;
  const filePath = path.join(CONFIG.MATRIX_INBOX, filename);

  const markdown = `# Gemini Research: ${query}

> **Date:** ${timestamp}
> **Source:** Parallel Gemini Browser Automation
> **Agent:** Morpheus
${metadata.windowIndex !== undefined ? `> **Window:** ${metadata.windowIndex}` : ''}
${metadata.isYouTube ? '> **Type:** YouTube Analysis' : ''}

## Query

${query}

## Response

${response}

${metadata.timestamps ? `## Timestamps\n\n${metadata.timestamps}\n` : ''}

---

## Metadata

- **Timestamp:** ${timestamp}
- **Agent:** Morpheus
- **Mode:** Parallel Browser Automation
${metadata.duration ? `- **Duration:** ${metadata.duration}ms` : ''}

## Tags

#gemini #parallel-research #auto-generated ${metadata.isYouTube ? '#youtube' : ''}

## Next Steps

- [ ] Distill insights to permanent memory via \`/distill\`
- [ ] Cross-reference with existing knowledge
- [ ] Generate follow-up questions

---

*Generated by Matrix Gemini Parallel Research Tool*
`;

  await fs.writeFile(filePath, markdown);
  console.log(`✅ Saved: ${filename}`);

  return { filename, filePath };
}

// ============================================================================
// Gemini Research Task
// ============================================================================

// Helper: Find first matching selector from array
async function findSelector(page, selectors, timeout = 10000) {
  if (!Array.isArray(selectors)) {
    selectors = [selectors];
  }

  for (const selector of selectors) {
    try {
      await page.waitForSelector(selector, { timeout: timeout / selectors.length });
      return selector;
    } catch {
      if (CONFIG.VERBOSE) console.log(`   Selector not found: ${selector}`);
    }
  }
  throw new Error(`No matching selector found from: ${selectors.join(', ')}`);
}

async function geminiResearchTask({ page, data }) {
  const { query, index, isYouTube, cookies, saveCookiesAfter } = data;
  const startTime = Date.now();

  console.log(`🚀 Window ${index}: Starting research for "${query}"`);

  try {
    // STEALTH: Hide automation detection before any navigation
    await page.evaluateOnNewDocument(() => {
      // Remove webdriver flag
      Object.defineProperty(navigator, 'webdriver', { get: () => false });

      // Override plugins to look like real browser
      Object.defineProperty(navigator, 'plugins', {
        get: () => [
          { name: 'Chrome PDF Plugin', filename: 'internal-pdf-viewer' },
          { name: 'Chrome PDF Viewer', filename: 'mhjfbmdgcfjbbpaeojofohoefgiehjai' },
          { name: 'Native Client', filename: 'internal-nacl-plugin' }
        ]
      });

      // Override languages
      Object.defineProperty(navigator, 'languages', { get: () => ['en-US', 'en'] });

      // Hide automation in chrome object
      window.chrome = { runtime: {} };

      // Override permissions query
      const originalQuery = window.navigator.permissions.query;
      window.navigator.permissions.query = (parameters) => (
        parameters.name === 'notifications' ?
          Promise.resolve({ state: Notification.permission }) :
          originalQuery(parameters)
      );
    });

    // Inject cookies for authentication if provided
    if (cookies && cookies.length > 0) {
      await injectCookies(page, cookies);
      if (CONFIG.VERBOSE) console.log(`   🍪 Window ${index}: Injected ${cookies.length} auth cookies`);
    }

    // Navigate to Gemini (no blank page - maintain session)
    await page.goto(CONFIG.GEMINI_URL, {
      waitUntil: 'networkidle2',
      timeout: CONFIG.TIMEOUTS.navigation
    });

    // Wait for page to fully stabilize and JS to load
    await page.waitForTimeout(3000);

    // Find prompt box using fallback selectors
    const promptSelector = await findSelector(page, CONFIG.SELECTORS.promptBox, CONFIG.TIMEOUTS.navigation);
    if (CONFIG.VERBOSE) console.log(`   Using prompt selector: ${promptSelector}`);

    // Type query
    await page.type(promptSelector, query, { delay: 50 });

    // Submit (press Enter)
    await page.keyboard.press('Enter');

    console.log(`⏳ Window ${index}: Waiting for Gemini response...`);

    // Wait for response (longer for YouTube)
    const waitTime = isYouTube ? CONFIG.TIMEOUTS.youtubeTime : CONFIG.TIMEOUTS.thinkingTime;
    await page.waitForTimeout(waitTime);

    // Save debug screenshot before extraction
    if (CONFIG.VERBOSE) {
      const screenshotPath = path.join(CONFIG.MATRIX_INBOX, `debug_response_${index}_${Date.now()}.png`);
      await page.screenshot({ path: screenshotPath, fullPage: true });
      console.log(`   📸 Response screenshot: ${screenshotPath}`);
    }

    // Extract response using fallback selectors
    const response = await page.evaluate((selectors) => {
      // Try each selector in order
      let container = null;
      const selectorList = Array.isArray(selectors.responseContainer)
        ? selectors.responseContainer
        : [selectors.responseContainer];

      for (const sel of selectorList) {
        container = document.querySelector(sel);
        if (container) break;
      }

      if (!container) {
        // Fallback: get all text from main content area
        const main = document.querySelector('main') || document.body;
        return { text: main.innerText.substring(0, 5000), timestamps: null };
      }

      // Extract text and preserve some structure
      const text = container.innerText;

      // Try to extract timestamps for YouTube
      const timestampLinks = Array.from(document.querySelectorAll('a[href*="youtube.com"]'))
        .filter(a => /\d{1,2}:\d{2}/.test(a.textContent))
        .map(a => `- [${a.textContent}](${a.href})`)
        .join('\n');

      return {
        text,
        timestamps: timestampLinks || null
      };
    }, CONFIG.SELECTORS);

    const duration = Date.now() - startTime;

    console.log(`✅ Window ${index}: Response received (${duration}ms)`);
    console.log(`   Preview: ${response.text.substring(0, 100)}...`);

    // Save cookies if requested (first successful query in profile mode)
    if (saveCookiesAfter && index === 0) {
      await saveCookies(page);
    }

    // Save to inbox
    const saved = await saveToInbox(query, response.text, {
      windowIndex: index,
      isYouTube,
      timestamps: response.timestamps,
      duration
    });

    return {
      query,
      response: response.text,
      saved: saved.filePath,
      duration,
      success: true
    };

  } catch (error) {
    console.error(`❌ Window ${index}: Error - ${error.message}`);

    // Save debug screenshot on failure
    try {
      const screenshotPath = path.join(CONFIG.MATRIX_INBOX, `debug_window${index}_${Date.now()}.png`);
      await page.screenshot({ path: screenshotPath, fullPage: true });
      console.log(`   📸 Debug screenshot: ${screenshotPath}`);
    } catch (ssError) {
      console.log(`   Could not save debug screenshot: ${ssError.message}`);
    }

    return {
      query,
      error: error.message,
      duration: Date.now() - startTime,
      success: false
    };
  }
}

// ============================================================================
// Main Parallel Research Function
// ============================================================================

async function parallelGeminiResearch(queries, options = {}) {
  const { isYouTube = false } = options;
  // Use CONFIG.HEADLESS (from env/CLI) with option override
  const headless = options.headless !== undefined ? options.headless : CONFIG.HEADLESS;

  await speak(`Morpheus online. Opening ${queries.length} parallel Gemini portals.`);

  console.log(`\n🔮 Matrix Gemini Parallel Research`);
  console.log(`📊 Queries: ${queries.length}`);
  console.log(`🖥️  Max Concurrency: ${CONFIG.MAX_CONCURRENCY}`);
  console.log(`👁️  Mode: ${headless ? 'headless (fast)' : 'visible (debug)'}`);
  console.log(`🧠 Memory: ${Math.round(os.totalmem() / 1024 / 1024 / 1024)}GB`);
  if (CONFIG.VERBOSE) {
    console.log(`🔧 Verbose: enabled`);
    console.log(`🔄 Retry: ${CONFIG.RETRY.attempts} attempts, ${CONFIG.RETRY.baseDelay}ms base delay`);
  }
  console.log('');

  // Auth mode: Always use persistent profile for authentication
  // --no-auth flag to skip profile (for testing/public pages)
  const noAuth = process.argv.includes('--no-auth');
  const saveCookiesFlag = process.argv.includes('--save-cookies');

  // Ensure automation profile directory exists
  try {
    await fs.mkdir(CONFIG.AUTOMATION_PROFILE_DIR, { recursive: true });
  } catch (e) { /* ignore */ }

  // Mode: sequential for reliability (one query at a time with fresh page)
  // Use CONCURRENCY_PAGE with maxConcurrency=1 for sequential but efficient
  const concurrencyMode = noAuth ? Cluster.CONCURRENCY_BROWSER : Cluster.CONCURRENCY_PAGE;

  if (!noAuth) {
    console.log(`🔐 Auth mode: Using your existing Brave profile`);
    console.log(`   Profile: ${CONFIG.USER_DATA_DIR}/${CONFIG.PROFILE_DIR}`);
    console.log(`   Parallel: ${queries.length} tabs in single authenticated browser`);
    console.log(`   ⚠️  CLOSE BRAVE BROWSER FIRST to avoid profile lock!`);
  } else {
    console.log(`⚠️  No-auth mode: Separate browsers, no login session`);
  }

  // For cookie backup (optional)
  let cookies = null;
  if (saveCookiesFlag) {
    console.log(`   🍪 Will save cookies after first successful query`);
  }

  // Launch cluster with retry wrapper
  const cluster = await withRetry(async () => {
    const launchArgs = [
      `--window-size=${CONFIG.WINDOW_SIZE.width},${CONFIG.WINDOW_SIZE.height}`,
      // Anti-detection / Stealth flags
      '--disable-blink-features=AutomationControlled',
      '--disable-infobars',
      '--disable-dev-shm-usage',
      '--disable-gpu'
    ];

    // Profile is set via puppeteerOptions.userDataDir (more reliable than CLI arg)

    return await Cluster.launch({
      concurrency: concurrencyMode,
      // With auth: parallel tabs in one browser (limited by Gemini, not us)
      // Without auth: separate browsers
      // Sequential for reliability (1 at a time), or parallel with --no-auth
      maxConcurrency: noAuth ? Math.min(queries.length, CONFIG.MAX_CONCURRENCY) : 1,
      puppeteerOptions: {
        executablePath: CONFIG.BROWSER_PATH,
        headless,
        args: launchArgs,
        defaultViewport: null,
        // KEY: Persistent profile for session memory
        userDataDir: noAuth ? undefined : CONFIG.USER_DATA_DIR,
        // Stealth: Don't use automation user agent
        ignoreDefaultArgs: ['--enable-automation'],
      },
      timeout: CONFIG.TIMEOUTS.navigation + CONFIG.TIMEOUTS.thinkingTime,
      retryLimit: CONFIG.RETRY.attempts,
      retryDelay: CONFIG.RETRY.baseDelay
    });
  });

  // Set task handler
  await cluster.task(geminiResearchTask);

  // Queue all research queries with staggered start to avoid race conditions
  for (let index = 0; index < queries.length; index++) {
    const query = queries[index];
    const position = getWindowPosition(index, queries.length);

    // Stagger tab starts by 2 seconds to avoid Gemini rate limiting
    if (index > 0 && !noAuth) {
      await new Promise(r => setTimeout(r, 2000));
    }

    cluster.queue({
      query,
      index,
      isYouTube,
      position,
      cookies,
      saveCookiesAfter: !noAuth && saveCookiesFlag && index === 0
    });
  }

  // Wait for all tasks to complete
  console.log('⏳ Waiting for all research to complete...\n');
  await cluster.idle();
  await cluster.close();

  await speak(`Research complete. ${queries.length} insights harvested.`);

  console.log('\n✅ All research tasks completed!');
  console.log(`📁 Results saved to: ${CONFIG.MATRIX_INBOX}\n`);
}

// ============================================================================
// CLI Interface
// ============================================================================

async function main() {
  const args = process.argv.slice(2);

  if (args.length === 0) {
    console.log(`
🔮 Matrix Gemini Parallel Research Tool

Usage:
  node gemini-parallel-research.js "query1" "query2" "query3"
  node gemini-parallel-research.js --youtube "URL1" "URL2"
  node gemini-parallel-research.js --headless "query"

Examples:
  # Regular research
  node gemini-parallel-research.js \\
    "quantum computing breakthroughs" \\
    "AI safety research" \\
    "neural network fundamentals"

  # YouTube analysis
  node gemini-parallel-research.js --youtube \\
    "https://youtube.com/watch?v=abc123" \\
    "https://youtube.com/watch?v=def456"

Options:
  --youtube     Optimize for YouTube video analysis (longer wait times)
  --headless    Run in headless mode (no visible windows)

Output:
  Results saved to: ${CONFIG.MATRIX_INBOX}
  Format: gemini_[slug]_[timestamp].md
    `);
    process.exit(1);
  }

  // Parse options
  const isYouTube = args.includes('--youtube');
  const headless = args.includes('--headless');

  // Filter out flags
  const queries = args.filter(arg => !arg.startsWith('--'));

  if (queries.length === 0) {
    console.error('❌ Error: No queries provided');
    process.exit(1);
  }

  // Run parallel research
  try {
    await parallelGeminiResearch(queries, { isYouTube, headless });
  } catch (error) {
    console.error('❌ Fatal error:', error);
    await speak('Research failed. Check the Matrix logs.', 'Smith');
    process.exit(1);
  }
}

// ============================================================================
// Module Exports & CLI Entry Point
// ============================================================================

if (require.main === module) {
  main().catch(console.error);
}

module.exports = {
  parallelGeminiResearch,
  saveToInbox,
  CONFIG
};
