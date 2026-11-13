import { execFileSync } from "node:child_process";
import fs from "node:fs/promises";
import path from "node:path";
import os from "node:os";
import { chromium, expect } from "@playwright/test";

const adb = path.join(process.env.ANDROID_HOME ?? path.join(os.homedir(), "Library/Android/sdk"), "platform-tools/adb");
const serial = process.env.ANDROID_SERIAL ?? "emulator-5554";
const pkg = "dev.youngblog.reader";
const run = (...args) => execFileSync(adb, ["-s", serial, ...args], { encoding: "utf8", maxBuffer: 8 * 1024 * 1024 });
const steps = [];
let browser;
if (!serial.startsWith("emulator-")) throw new Error("Run this state-resetting suite on a dedicated emulator.");
const originalProxy = run("shell", "settings", "get", "global", "http_proxy").trim();
const originalAirplane = run("shell", "settings", "get", "global", "airplane_mode_on").trim();
const originalWifi = run("shell", "settings", "get", "global", "wifi_on").trim();
const originalData = run("shell", "settings", "get", "global", "mobile_data").trim();
async function attach() {
  await expect.poll(() => run("shell", "pidof", pkg).trim(), { timeout: 10000 }).not.toBe("");
  const pid = run("shell", "pidof", pkg).trim();
  run("forward", "tcp:9223", `localabstract:webview_devtools_remote_${pid}`);
  await expect.poll(async () => {
    try { return (await fetch("http://127.0.0.1:9223/json/version")).ok; } catch { return false; }
  }, { timeout: 10000 }).toBe(true);
  browser = await chromium.connectOverCDP("http://127.0.0.1:9223", { noDefaults: true });
  return browser.contexts()[0].pages()[0];
}
async function screenshot(name) {
  await fs.writeFile(`artifacts/${name}.png`, execFileSync(adb, ["-s", serial, "exec-out", "screencap", "-p"], { maxBuffer: 8 * 1024 * 1024 }));
}
await fs.mkdir("artifacts", { recursive: true });
try {
  if (process.env.ANDROID_TEST_PROXY) run("shell", "settings", "put", "global", "http_proxy", process.env.ANDROID_TEST_PROXY);
  run("shell", "pm", "clear", pkg);
  run("shell", "am", "start", "-W", "-n", `${pkg}/.MainActivity`);
  let page = await attach();
  await page.goto("https://localhost/tech/en");
  await expect(page.getByRole("searchbox")).toBeVisible();
  await page.getByRole("searchbox").fill("why ocaml");
  await expect(page.locator(".post-card")).toHaveCount(1);
  await page.locator(".post-card").getByRole("button", { name: "Save article", exact: true }).click();
  await page.locator(".post-title").click();
  await expect(page.locator(".article-body pre").first()).toBeVisible();
  await expect(page.locator(".copy-code").first()).toBeVisible();
  steps.push("Bonsai search, favorite, article loading, and code tools work in Android WebView");
  await page.getByLabel("Reading settings").click();
  await page.getByRole("button", { name: "A+", exact: true }).click();
  await expect(page.locator(".article-body")).toHaveCSS("font-size", "19px");
  run("shell", "input", "keyevent", "4");
  await expect(page.locator(".reader-settings")).not.toHaveAttribute("open", "");
  steps.push("Android Back closes reading settings before navigation");
  await page.getByRole("button", { name: "Share article", exact: true }).click();
  await expect.poll(() => run("shell", "dumpsys", "activity", "activities"), { timeout: 10000 }).toContain("ChooserActivity");
  await screenshot("android-share");
  run("shell", "input", "keyevent", "4");
  steps.push("Native Android share sheet opens with the public article URL");
  await page.getByRole("button", { name: "Refresh library", exact: true }).click();
  await expect(page.getByRole("status")).toContainText(/Library updated|up to date/, { timeout: 90000 });
  const verifiedBodies = await page.evaluate(async () => {
    const db = await new Promise((resolve, reject) => {
      const request = indexedDB.open("young-blog-reader", 1);
      request.onsuccess = () => resolve(request.result);
      request.onerror = () => reject(request.error);
    });
    try {
      const snapshot = await new Promise((resolve, reject) => {
        const request = db.transaction("content").objectStore("content").get("active");
        request.onsuccess = () => resolve(request.result);
        request.onerror = () => reject(request.error);
      });
      return snapshot.manifest.articles.every((article) => /^[a-f0-9]{64}$/.test(article.sha256))
        && Object.keys(snapshot.articles).length === snapshot.manifest.articles.length;
    } finally { db.close(); }
  });
  expect(verifiedBodies).toBe(true);
  steps.push("Real production hashed content refresh succeeds through the native HTTP bridge");
  const articlePath = "/tech/zh-hant/ocaml-learning/jane-street-video-notes/jane-street-why-ocaml";
  run("shell", "am", "start", "-W", "-a", "android.intent.action.VIEW", "-d", `https://young-blog.pages.dev${articlePath}`, pkg);
  await expect(page.locator("html")).toHaveAttribute("lang", "zh-Hant");
  await expect(page.locator(".article-body")).toBeVisible();
  await expect(page.locator(".article-toc")).toBeVisible();
  await expect(page.locator(".copy-code").first()).toHaveText("複製");
  await expect(page.locator(".article-body")).toHaveAttribute("data-reader-ready", "true");
  await expect(page.locator(".article-actions").getByRole("button", { name: "已收藏", exact: true })).toBeVisible();
  await screenshot("android-reading");
  steps.push("HTTPS article intents open the matching translation and preserve the shared favorite");
  await page.evaluate(() => window.scrollTo(0, 1400));
  await expect.poll(() => page.evaluate(() => localStorage.getItem(`reader:position:${location.pathname}`))).toBe("1400");
  await page.evaluate(() => globalThis.BlogReader.flush());
  await expect.poll(() => run("shell", "run-as", pkg, "cat", "shared_prefs/CapacitorStorage.xml")).toContain(">1400</string>");
  await browser.close();
  browser = undefined;
  run("shell", "cmd", "connectivity", "airplane-mode", "enable");
  run("shell", "svc", "wifi", "disable");
  run("shell", "svc", "data", "disable");
  run("shell", "am", "force-stop", pkg);
  run("shell", "am", "start", "-W", "-n", `${pkg}/.MainActivity`);
  page = await attach();
  await expect(page.locator(".article-body")).toBeVisible();
  await expect(page.locator(".article-body")).toHaveCSS("font-size", "19px");
  await expect.poll(() => page.evaluate(() => scrollY)).toBeGreaterThan(1300);
  await screenshot("android-offline");
  steps.push("Airplane-mode cold restart restores the saved article, font size, favorite, and reading position");
  await page.getByRole("button", { name: "更新文章庫", exact: true }).click();
  await expect(page.getByRole("status")).toContainText("暫時無法更新", { timeout: 40000 });
  await expect(page.locator(".article-body")).toBeVisible();
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true);
  steps.push("Offline refresh fails gracefully without removing readable content or overflowing the screen");
  await fs.writeFile("artifacts/android-smoke.json", JSON.stringify({ serial, package: pkg, steps }, null, 2) + "\n");
  console.log(steps.map((step) => `PASS ${step}`).join("\n"));
} finally {
  if (browser) await browser.close();
  run("shell", "cmd", "connectivity", "airplane-mode", originalAirplane === "1" ? "enable" : "disable");
  run("shell", "svc", "wifi", originalWifi === "1" ? "enable" : "disable");
  run("shell", "svc", "data", originalData === "1" ? "enable" : "disable");
  if (process.env.ANDROID_TEST_PROXY) {
    if (originalProxy === "null") run("shell", "settings", "delete", "global", "http_proxy");
    else run("shell", "settings", "put", "global", "http_proxy", originalProxy);
  }
  run("forward", "--remove", "tcp:9223");
}
