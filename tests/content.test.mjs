import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs/promises";
import { validateManifest, legacyManifest, articlePaths, downloadSnapshot, sha256, decodeNativeText } from "../web/content.mjs";

const manifest = JSON.parse(await fs.readFile("public/content-index.json", "utf8"));

test("native binary responses preserve Unicode, line endings, and body hashes", async () => {
  const html = "<p>中文與 emoji 🌙</p>\r\n<pre>let x = 1</pre>\n";
  const encoded = Buffer.from(html).toString("base64");
  assert.equal(decodeNativeText(encoded), html);
  const snapshot = await downloadSnapshot(manifest, async (path) => {
    const bytes = await fs.readFile("public" + path);
    return decodeNativeText(bytes.toString("base64"));
  }, (s) => s);
  assert.equal(Object.keys(snapshot.articles).length, manifest.articles.length);
  assert.deepEqual(JSON.parse(decodeNativeText(manifest)), manifest);
  assert.throws(() => decodeNativeText(null), /Invalid native HTTP response/);
  assert.throws(() => decodeNativeText(Buffer.from([0xff]).toString("base64")));
});

test("the generated index pairs every article with the exact emitted body", async () => {
  validateManifest(manifest);
  const snapshot = await downloadSnapshot(manifest, (path) => fs.readFile("public" + path, "utf8"), (s) => s);
  assert.equal(Object.keys(snapshot.articles).length, manifest.articles.length);
  assert.ok(manifest.articles.length > 0);
  assert.ok(manifest.articles.some((a) => a.path.includes("/zh-hant/")));
});
test("legacy publishing is supported without evaluating remote JavaScript", async () => {
  const legacy = await legacyManifest(await fs.readFile("public/posts.js", "utf8"));
  assert.deepEqual(articlePaths(legacy.postsSexp), manifest.articles.map((a) => a.path));
  await assert.rejects(legacyManifest('globalThis.BLOG_POSTS_SEXP = "()"; alert(1)'));
});
test("interrupted and mixed-version downloads never return a snapshot", async () => {
  await assert.rejects(downloadSnapshot(manifest, async () => { throw new Error("Offline"); }, (s) => s), /Offline/);
  await assert.rejects(downloadSnapshot(manifest, async () => "new body", (s) => s), /Content changed/);
});
test("SPA fallback pages and path escapes are rejected", async () => {
  await assert.rejects(downloadSnapshot(manifest, async () => "<!doctype html><html>fallback</html>", (s) => s), /returned a page/);
  const bad = structuredClone(manifest);
  bad.articles[0].path = "/../../private";
  assert.throws(() => validateManifest(bad));
  assert.equal((await sha256("hello")).length, 64);
});
