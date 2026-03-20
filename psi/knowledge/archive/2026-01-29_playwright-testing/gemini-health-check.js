#!/usr/bin/env node

/**
 * Gemini Research Health Check
 *
 * Pre-flight verification for parallel browser automation.
 * Run before research to ensure all dependencies and connectivity.
 *
 * Usage:
 *   node gemini-health-check.js           # Full check
 *   node gemini-health-check.js --quiet   # Exit code only
 *   node gemini-health-check.js --json    # JSON output
 */

const fs = require('fs');
const path = require('path');
const os = require('os');
const { exec } = require('child_process');
const https = require('https');

// ============================================================================
// Configuration
// ============================================================================

const CONFIG = {
  BRAVE_PATH: '/Applications/Brave Browser.app/Contents/MacOS/Brave Browser',
  GEMINI_URL: 'https://gemini.google.com',
  MATRIX_INBOX: path.join(process.env.HOME, 'workspace/The-matrix/psi/learn/inbox'),
  MIN_NODE_VERSION: 16,
  MIN_MEMORY_GB: 4,
  DEPS: ['puppeteer-cluster', 'puppeteer']
};

// ============================================================================
// Check Functions
// ============================================================================

async function checkNodeVersion() {
  const version = parseInt(process.version.slice(1).split('.')[0]);
  return {
    name: 'Node.js Version',
    healthy: version >= CONFIG.MIN_NODE_VERSION,
    message: version >= CONFIG.MIN_NODE_VERSION
      ? `v${process.version} (>= ${CONFIG.MIN_NODE_VERSION} required)`
      : `v${process.version} is too old (>= ${CONFIG.MIN_NODE_VERSION} required)`
  };
}

async function checkDependencies() {
  const missing = [];
  for (const dep of CONFIG.DEPS) {
    try {
      require.resolve(dep);
    } catch {
      missing.push(dep);
    }
  }

  return {
    name: 'NPM Dependencies',
    healthy: missing.length === 0,
    message: missing.length === 0
      ? `All dependencies installed (${CONFIG.DEPS.join(', ')})`
      : `Missing: ${missing.join(', ')} - Run: npm install`,
    fix: missing.length > 0 ? 'cd psi/active && npm install' : null
  };
}

async function checkBraveBrowser() {
  const exists = fs.existsSync(CONFIG.BRAVE_PATH);
  return {
    name: 'Brave Browser',
    healthy: exists,
    message: exists
      ? 'Installed at /Applications/Brave Browser.app'
      : 'Not found - Install from https://brave.com'
  };
}

async function checkGeminiReachable() {
  return new Promise((resolve) => {
    const timeout = setTimeout(() => {
      resolve({
        name: 'Gemini Connectivity',
        healthy: false,
        message: 'Connection timeout (5s)'
      });
    }, 5000);

    const req = https.request(CONFIG.GEMINI_URL, { method: 'HEAD' }, (res) => {
      clearTimeout(timeout);
      const isReachable = res.statusCode >= 200 && res.statusCode < 400;
      resolve({
        name: 'Gemini Connectivity',
        healthy: isReachable,
        message: isReachable
          ? `Reachable (HTTP ${res.statusCode})`
          : `Returned HTTP ${res.statusCode}`
      });
    });

    req.on('error', (err) => {
      clearTimeout(timeout);
      resolve({
        name: 'Gemini Connectivity',
        healthy: false,
        message: `Network error: ${err.message}`
      });
    });

    req.end();
  });
}

async function checkSystemMemory() {
  const totalGB = os.totalmem() / (1024 * 1024 * 1024);
  const freeGB = os.freemem() / (1024 * 1024 * 1024);
  const healthy = totalGB >= CONFIG.MIN_MEMORY_GB;

  return {
    name: 'System Memory',
    healthy,
    message: healthy
      ? `${totalGB.toFixed(1)}GB total, ${freeGB.toFixed(1)}GB free`
      : `Only ${totalGB.toFixed(1)}GB (need ${CONFIG.MIN_MEMORY_GB}GB minimum)`
  };
}

async function checkInboxWritable() {
  try {
    // Ensure directory exists
    if (!fs.existsSync(CONFIG.MATRIX_INBOX)) {
      fs.mkdirSync(CONFIG.MATRIX_INBOX, { recursive: true });
    }

    // Test write
    const testFile = path.join(CONFIG.MATRIX_INBOX, '.health-check-test');
    fs.writeFileSync(testFile, 'test');
    fs.unlinkSync(testFile);

    return {
      name: 'Inbox Directory',
      healthy: true,
      message: `Writable: ${CONFIG.MATRIX_INBOX}`
    };
  } catch (err) {
    return {
      name: 'Inbox Directory',
      healthy: false,
      message: `Not writable: ${err.message}`
    };
  }
}

async function checkMcpServers() {
  return new Promise((resolve) => {
    exec('claude mcp list 2>&1', { timeout: 10000 }, (err, stdout) => {
      if (err) {
        resolve({
          name: 'MCP Servers',
          healthy: false,
          message: 'Could not check MCP status'
        });
        return;
      }

      const playwrightConnected = stdout.includes('playwright') && stdout.includes('Connected');
      resolve({
        name: 'MCP Servers',
        healthy: playwrightConnected,
        message: playwrightConnected
          ? 'Playwright MCP connected'
          : 'Playwright MCP not connected'
      });
    });
  });
}

// ============================================================================
// Main Health Check
// ============================================================================

async function runHealthCheck(options = {}) {
  const { quiet = false, json = false } = options;

  const checks = await Promise.all([
    checkNodeVersion(),
    checkDependencies(),
    checkBraveBrowser(),
    checkGeminiReachable(),
    checkSystemMemory(),
    checkInboxWritable(),
    checkMcpServers()
  ]);

  const failed = checks.filter(c => !c.healthy);
  const result = {
    healthy: failed.length === 0,
    timestamp: new Date().toISOString(),
    checks,
    summary: failed.length === 0
      ? 'All systems operational'
      : `${failed.length} issue(s) detected`
  };

  if (json) {
    console.log(JSON.stringify(result, null, 2));
  } else if (!quiet) {
    console.log('\n🔮 Gemini Research Health Check\n');
    console.log('━'.repeat(50));

    for (const check of checks) {
      const icon = check.healthy ? '✅' : '❌';
      console.log(`${icon} ${check.name}`);
      console.log(`   ${check.message}`);
      if (check.fix) {
        console.log(`   💡 Fix: ${check.fix}`);
      }
    }

    console.log('━'.repeat(50));
    console.log(`\n${result.healthy ? '✅' : '❌'} ${result.summary}\n`);
  }

  return result;
}

// ============================================================================
// CLI
// ============================================================================

async function main() {
  const args = process.argv.slice(2);
  const quiet = args.includes('--quiet') || args.includes('-q');
  const json = args.includes('--json');

  const result = await runHealthCheck({ quiet, json });
  process.exit(result.healthy ? 0 : 1);
}

if (require.main === module) {
  main().catch(err => {
    console.error('Health check failed:', err);
    process.exit(1);
  });
}

module.exports = { runHealthCheck };
