export const SITE_ORIGIN = "https://young-blog.pages.dev";

export async function sha256(text) {
  const bytes = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(text));
  return Array.from(new Uint8Array(bytes), (b) => b.toString(16).padStart(2, "0")).join("");
}

export function parseSexp(source) {
  let offset = 0;
  function read() {
    while (/\s/.test(source[offset] ?? "") && offset < source.length) offset++;
    if (source[offset] === "(") {
      offset++;
      const result = [];
      while (true) {
        while (/\s/.test(source[offset] ?? "") && offset < source.length) offset++;
        if (source[offset] === ")") { offset++; return result; }
        if (offset >= source.length) throw new Error("Incomplete article index");
        result.push(read());
      }
    }
    const token = source.slice(offset).match(/^("(?:\\.|[^"\\])*"|[^\s()]+)/);
    if (!token) throw new Error("Invalid article index");
    offset += token[0].length;
    return token[0].startsWith('"') ? JSON.parse(token[0]) : token[0];
  }
  const result = read();
  if (source.slice(offset).trim()) throw new Error("Unexpected article index data");
  return result;
}

export function articlePaths(sexp) {
  const posts = parseSexp(sexp);
  if (!Array.isArray(posts) || posts.length > 10000) throw new Error("Invalid article list");
  return posts.map((pairs) => {
    const post = Object.fromEntries(pairs);
    if (["title", "summary", "date", "translation_key"].some((key) => typeof post[key] !== "string") ||
        !/^\d{4}-\d{2}-\d{2}$/.test(post.date) || !Array.isArray(post.tags) ||
        post.tags.some((tag) => typeof tag !== "string")) {
      throw new Error("Invalid article metadata");
    }
    const segments = [
      { Tech: "tech", Essays: "essays" }[post.area],
      { En: "en", Zh_hans: "zh-hans", Zh_hant: "zh-hant" }[post.locale],
      post.category, post.subcategory, post.slug,
    ];
    if (segments.some((s) => typeof s !== "string" || !/^[a-zA-Z0-9_-]+$/.test(s))) {
      throw new Error("Invalid article path");
    }
    return `/articles/${segments.join("/")}.html`;
  });
}

export async function legacyManifest(source) {
  const match = source.trim().match(/^globalThis\.BLOG_POSTS_SEXP\s*=\s*("(?:\\.|[^"\\])*");?$/);
  if (!match) throw new Error("Unsupported article index");
  const postsSexp = JSON.parse(match[1]);
  return {
    schemaVersion: 1,
    version: await sha256(postsSexp),
    postsSexp,
    articles: articlePaths(postsSexp).map((path) => ({ path })),
  };
}

export function validateManifest(manifest) {
  if (manifest?.schemaVersion !== 1 || typeof manifest.version !== "string" ||
      typeof manifest.postsSexp !== "string" || !Array.isArray(manifest.articles)) {
    throw new Error("Unsupported content format");
  }
  const paths = articlePaths(manifest.postsSexp);
  if (new Set(paths).size !== paths.length || paths.length !== manifest.articles.length ||
      manifest.articles.some((article, i) => article.path !== paths[i] ||
        (article.sha256 !== undefined && !/^[a-f0-9]{64}$/.test(article.sha256)))) {
    throw new Error("Content index does not match its articles");
  }
  return manifest;
}

// Activation happens only after every body is available and verified.
export async function downloadSnapshot(manifest, fetchText, sanitize) {
  validateManifest(manifest);
  const articles = {};
  let cursor = 0;
  async function worker() {
    while (cursor < manifest.articles.length) {
      const article = manifest.articles[cursor++];
      const html = await fetchText(article.path);
      if (/<!doctype|<html[\s>]/i.test(html)) throw new Error("Article request returned a page");
      if (article.sha256 && await sha256(html) !== article.sha256) {
        throw new Error("Content changed during download. Please refresh again.");
      }
      articles[article.path] = sanitize(html);
    }
  }
  await Promise.all(Array.from({ length: Math.min(4, manifest.articles.length) }, worker));
  return { manifest, articles };
}
