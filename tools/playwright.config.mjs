import { defineConfig } from '@playwright/test';
export default defineConfig({
  testDir: './e2e', timeout: 120000, expect: {timeout: 15000}, workers: 1,
  outputDir: '../.local-tools/playwright-results', reporter: 'list',
  use: { channel: 'chrome', headless: true, baseURL: 'http://127.0.0.1:5173',
    viewport: {width: 1100, height: 900}, timezoneId: 'Asia/Rangoon',
    permissions: ['geolocation'], geolocation: {latitude: 16.8661, longitude: 96.1951},
    screenshot: 'only-on-failure', trace: 'retain-on-failure' },
});
