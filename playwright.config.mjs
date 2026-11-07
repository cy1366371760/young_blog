import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: "tests/browser",
  fullyParallel: false,
  workers: 1,
  timeout: 30000,
  use: {
    baseURL: "http://127.0.0.1:8891",
    channel: process.env.CI ? undefined : "chrome",
    viewport: { width: 390, height: 844 },
    locale: "en-US",
    screenshot: "only-on-failure",
  },
  webServer: { command: "node scripts/serve_site.mjs", port: 8891, reuseExistingServer: !process.env.CI },
});
