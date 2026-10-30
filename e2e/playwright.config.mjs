import { defineConfig, devices } from '@playwright/test';

// The web build (tool/web_build.sh) in the browsers people use. Locally only Chromium may be
// installed: BROWSERS=chromium npx playwright test
const all = [
  { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
  { name: 'firefox', use: { ...devices['Desktop Firefox'] } },
  { name: 'webkit', use: { ...devices['Desktop Safari'] } },
  // phone-sized windows: the phone layout with the bottom bar. (Touch emulation is left out: in
  // it Flutter's accessibility tree, which the tests read, only turns on with a real tap.)
  { name: 'chromium-phone', use: { ...devices['Desktop Chrome'], viewport: { width: 412, height: 915 }, deviceScaleFactor: 2.6 } },
  { name: 'webkit-phone', use: { ...devices['Desktop Safari'], viewport: { width: 390, height: 844 }, deviceScaleFactor: 3 } },
];
const only = process.env.BROWSERS?.split(',');

export default defineConfig({
  testDir: './tests',
  timeout: 90_000,
  expect: { timeout: 20_000 },
  retries: process.env.CI ? 1 : 0,
  reporter: process.env.CI ? [['list'], ['html', { open: 'never' }]] : 'list',
  use: { baseURL: 'http://localhost:4321', screenshot: 'only-on-failure', trace: 'retain-on-failure' },
  projects: only ? all.filter((p) => only.some((o) => p.name.startsWith(o))) : all,
  webServer: { command: 'node serve.mjs', url: 'http://localhost:4321/slope-calculation/app', reuseExistingServer: true },
});
