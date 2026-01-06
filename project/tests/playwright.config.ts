import { defineConfig, devices } from '@playwright/test';

/**
 * See https://playwright.dev/docs/test-configuration.
 */
export default defineConfig({
  testDir: './tests',
  /* Run tests in files in parallel */
  fullyParallel: true,
  /* Fail the build on CI if you accidentally left test.only in the source code. */
  forbidOnly: !!process.env.CI,
  /* Retry on CI only */
  retries: process.env.CI ? 2 : 0,
  /* Opt out of parallel tests on CI. */
  workers: process.env.CI ? 1 : undefined,
  /* Reporter to use. See https://playwright.dev/docs/test-reporters */
  reporter: 'html',
  
  /* Shared settings for all the projects below. */
  use: {
    /* Collect trace when retrying the failed test. */
    trace: 'on-first-retry',
    /* Screenshot on failure */
    screenshot: 'only-on-failure',
  },

  /* Configure projects for disparate environments */
  projects: [
    {
      name: 'legacy',
      use: { 
        ...devices['Desktop Chrome'],
        baseURL: 'http://localhost:8888',
      },
    },
    {
      name: 'modern',
      use: { 
        ...devices['Desktop Chrome'],
        baseURL: 'http://localhost:5173',
      },
    },
    /* Mobile viewports for future verification */
    {
      name: 'modern-mobile',
      use: { 
        ...devices['Pixel 5'],
        baseURL: 'http://localhost:5173',
      },
    },
  ],
});
