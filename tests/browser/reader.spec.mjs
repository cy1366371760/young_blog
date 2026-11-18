import { test, expect } from "@playwright/test";
import fs from "node:fs/promises";

test.beforeEach(async ({ page }) => {
  await page.goto("/tech/en");
  await expect(page.locator("#article-search")).toBeVisible();
});

test("search, tags, empty state, and mobile topics are usable", async ({ page }) => {
  const cards = page.locator(".post-card");
  const initial = await cards.count();
  expect(initial).toBeGreaterThan(5);
  await page.getByRole("searchbox").fill("printing machine");
  await expect(cards).toHaveCount(1);
  await page.getByRole("searchbox").fill("no-such-note-12345");
  await expect(page.getByRole("heading", { name: "No matching notes" })).toBeVisible();
  await page.getByRole("button", { name: "Clear filters" }).click();
  await expect(cards).toHaveCount(initial);
  await page.locator(".filter-tags").getByRole("button", { name: "atcoder", exact: true }).click();
  await expect.poll(() => cards.count()).toBeLessThan(initial);
  await page.locator(".mobile-categories > summary").click();
  await expect(page.locator(".mobile-categories .category-navigation")).toBeVisible();
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true);
});

test("saved works across languages and restarts", async ({ page }) => {
  const title = await page.locator(".post-title").first().textContent();
  await page.locator(".post-card").first().getByRole("button", { name: "Save article" }).click();
  await page.getByRole("button", { name: "Saved notes", exact: true }).click();
  await expect(page.locator(".post-card")).toHaveCount(1);
  await page.getByRole("link", { name: "简体中文", exact: true }).click();
  await expect(page.locator(".post-card")).toHaveCount(1);
  await expect(page.locator(".post-card").getByRole("button", { name: "已收藏", exact: true })).toBeVisible();
  await expect(page.locator("html")).toHaveAttribute("lang", "zh-Hans");
  await page.reload();
  await page.getByRole("button", { name: "我的收藏", exact: true }).click();
  await expect(page.locator(".post-card")).toHaveCount(1);
  await page.getByRole("link", { name: "English", exact: true }).click();
  await expect(page.locator(".post-title")).toHaveText(title);
});

test("reading settings, code tools, and progress survive reopening", async ({ page }) => {
  await page.getByRole("searchbox").fill("why ocaml");
  await page.locator(".post-title").first().click();
  await expect(page.locator(".article-body pre").first()).toBeVisible();
  await expect(page.locator(".copy-code").first()).toHaveText("Copy");
  await expect(page.locator(".article-toc")).toBeVisible();
  await page.getByLabel("Reading settings").click();
  await page.getByRole("button", { name: "A+", exact: true }).click();
  await page.getByRole("button", { name: "Dark", exact: true }).click();
  await expect(page.locator("html")).toHaveAttribute("data-theme", "dark");
  await expect(page.locator(".article-body")).toHaveCSS("font-size", "19px");
  await page.getByLabel("Reading settings").click();
  await page.evaluate(() => window.scrollTo(0, 1600));
  await expect.poll(() => page.evaluate(() => localStorage.getItem(`reader:position:${location.pathname}`))).toBe("1600");
  await page.reload();
  await expect(page.locator(".article-body")).toBeVisible();
  await expect.poll(() => page.evaluate(() => scrollY)).toBeGreaterThan(1500);
  await expect(page.locator(".article-body")).toHaveCSS("font-size", "19px");
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true);
});

test("content sync activates atomically and survives a failed refresh", async ({ page }) => {
  const manifest = JSON.parse(await fs.readFile("public/content-index.json", "utf8"));
  await page.route("https://young-blog.pages.dev/**", async (route) => {
    const path = new URL(route.request().url()).pathname;
    if (path === "/content-index.json") return route.fulfill({ json: manifest });
    return route.fulfill({ body: await fs.readFile("public" + path), contentType: "text/html" });
  });
  await page.getByRole("button", { name: "Refresh library" }).click();
  await expect(page.getByRole("status")).toContainText("Library updated", { timeout: 20000 });
  await page.reload();
  await page.route("https://young-blog.pages.dev/**", (route) => route.abort());
  await page.getByRole("button", { name: "Refresh library" }).click();
  await expect(page.getByRole("status")).toContainText("Could not refresh");
  await page.route("**/articles/**", (route) => route.abort());
  await page.locator(".post-title").first().click();
  await expect(page.locator(".article-body")).toBeVisible();
});

test("tablet layout and traditional Chinese remain readable", async ({ page }) => {
  await page.setViewportSize({ width: 1024, height: 768 });
  await page.getByRole("link", { name: "繁體中文", exact: true }).click();
  await expect(page.locator("html")).toHaveAttribute("lang", "zh-Hant");
  await expect(page.locator(".desktop-topics")).toBeVisible();
  await expect(page.locator(".mobile-topics-wrap")).toBeHidden();
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true);
});

test("article tools are recreated when Bonsai reuses the body for a translation", async ({ page }) => {
  await page.getByRole("searchbox").fill("why ocaml");
  await page.locator(".post-title").first().click();
  await expect(page.locator(".copy-code").first()).toHaveText("Copy");
  await page.getByRole("link", { name: "繁體中文", exact: true }).click();
  await expect(page.locator(".article-body h1").first()).toContainText("從一段布爾");
  await expect(page.locator(".copy-code").first()).toHaveText("複製");
  await expect(page.locator(".article-toc")).toHaveCount(1);
  await expect(page.locator(".article-toc")).toBeVisible();
  await expect(page.locator(".article-body")).toHaveAttribute("data-reader-ready", "true");
  await page.evaluate(() => scrollTo(0, 1200));
  await expect.poll(() => page.evaluate(() => localStorage.getItem(`reader:position:${location.pathname}`))).toBe("1200");
  await page.setViewportSize({ width: 320, height: 740 });
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true);
});
