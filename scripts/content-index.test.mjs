import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { execFileSync } from "node:child_process";
import test from "node:test";
import vm from "node:vm";

test("the reader manifest covers every emitted article with its exact body hash", (t) => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "blog-content-index-"));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  const postsPath = path.join(root, "posts.js");
  execFileSync(process.execPath, ["scripts/generate_posts.mjs", postsPath]);
  const manifest = JSON.parse(fs.readFileSync(path.join(root, "content-index.json"), "utf8"));
  const context = {};
  vm.runInNewContext(fs.readFileSync(postsPath, "utf8"), context);
  assert.equal(manifest.schemaVersion, 1);
  assert.equal(manifest.postsSexp, context.BLOG_POSTS_SEXP);
  assert.match(manifest.version, /^[a-f0-9]{64}$/);
  const emitted = fs.readdirSync(path.join(root, "articles"), { recursive: true })
    .filter((file) => file.endsWith(".html"))
    .map((file) => "/articles/" + file.split(path.sep).join("/"));
  assert.deepEqual(manifest.articles.map((article) => article.path).sort(), emitted.sort());
  for (const locale of ["en", "zh-hans", "zh-hant"]) {
    assert.ok(manifest.articles.some((article) => article.path.includes(`/${locale}/`)));
  }
  for (const article of manifest.articles) {
    const body = fs.readFileSync(path.join(root, article.path.slice(1)));
    assert.equal(article.sha256, createHash("sha256").update(body).digest("hex"));
  }
  execFileSync(process.execPath, ["scripts/generate_posts.mjs", postsPath]);
  assert.equal(JSON.parse(fs.readFileSync(path.join(root, "content-index.json"), "utf8")).version, manifest.version);
});
