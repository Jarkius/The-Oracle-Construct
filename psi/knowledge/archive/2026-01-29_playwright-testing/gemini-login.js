#!/usr/bin/env node

/**
 * Gemini Login Helper
 *
 * Creates a dedicated automation profile and lets you sign in ONCE.
 * After signing in, all future research runs will remember your session.
 *
 * Usage:
 *   node gemini-login.js
 */

const puppeteer = require('puppeteer');
const path = require('path');
const readline = require('readline');

const CONFIG = {
  BROWSER_PATH: '/Applications/Brave Browser.app/Contents/MacOS/Brave Browser',
  GEMINI_URL: 'https://gemini.google.com/app',
  // Dedicated automation profile - separate from your main browser
  USER_DATA_DIR: path.join(process.env.HOME, '.gemini-automation-profile'),
};

async function prompt(question) {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });
  return new Promise(resolve => {
    rl.question(question, answer => {
      rl.close();
      resolve(answer);
    });
  });
}

async function main() {
  console.log('\n🔐 Gemini Login Setup\n');
  console.log('This creates a DEDICATED automation profile.');
  console.log('You sign in ONCE, then all future runs remember you.\n');
  console.log(`Profile location: ${CONFIG.USER_DATA_DIR}\n`);

  // Launch with persistent profile
  const browser = await puppeteer.launch({
    executablePath: CONFIG.BROWSER_PATH,
    headless: false,
    userDataDir: CONFIG.USER_DATA_DIR,  // KEY: persistent profile
    args: [
      '--window-size=1200,800',
      '--disable-blink-features=AutomationControlled',
      '--disable-infobars'
    ],
    defaultViewport: null,
    ignoreDefaultArgs: ['--enable-automation']
  });

  const pages = await browser.pages();
  const page = pages[0] || await browser.newPage();

  // Stealth: hide webdriver flag
  await page.evaluateOnNewDocument(() => {
    Object.defineProperty(navigator, 'webdriver', { get: () => false });
  });

  console.log('📱 Opening Gemini...\n');
  await page.goto(CONFIG.GEMINI_URL, { waitUntil: 'networkidle2', timeout: 60000 });

  console.log('━'.repeat(50));
  console.log('👆 SIGN IN to Google in the browser window.');
  console.log('   Use your juckrit@gmail.com account.');
  console.log('━'.repeat(50));
  console.log('\nAfter you see your profile picture in top-right,');

  await prompt('press ENTER here to save the session... ');

  // Take a screenshot to verify
  const screenshotPath = path.join(CONFIG.USER_DATA_DIR, 'login-verified.png');
  await page.screenshot({ path: screenshotPath });
  console.log(`\n📸 Screenshot saved: ${screenshotPath}`);

  await browser.close();

  console.log('\n✅ Session saved to automation profile!');
  console.log('\nNow run parallel research:');
  console.log('  node gemini-parallel-research.js "query1" "query2" "query3"\n');
}

main().catch(err => {
  console.error('Error:', err.message);
  process.exit(1);
});
