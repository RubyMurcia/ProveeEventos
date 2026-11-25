// E2E (TESTs §2.2 y §15; CICD §13.4). Lee .env cuando existe; no añade variables propias.
import { existsSync } from 'node:fs';

import { defineConfig, devices } from '@playwright/test';

if (existsSync('.env')) process.loadEnvFile('.env');

export default defineConfig({
  testDir: 'backend/src/tests/e2e',
  retries: 0,
  forbidOnly: true,
  reporter: 'list',
  use: {
    baseURL: process.env['APP_BASE_URL'] ?? 'http://localhost:3000',
    trace: 'retain-on-failure',
  },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    { name: 'webkit', use: { ...devices['Desktop Safari'] } },
  ],
});
