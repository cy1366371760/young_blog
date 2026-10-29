import { Capacitor, CapacitorHttp } from "@capacitor/core";
import { App } from "@capacitor/app";
import { Share } from "@capacitor/share";
import { Preferences } from "@capacitor/preferences";
import DOMPurify from "dompurify";
import { SITE_ORIGIN, legacyManifest, validateManifest, downloadSnapshot } from "./content.mjs";

const native = Capacitor.isNativePlatform();
const nativePreferences = new Map();
let pendingWrites = Promise.resolve();
if (native) {
  const { keys } = await Preferences.keys();
  await Promise.all(keys.filter((key) => key.startsWith("reader:")).map(async (key) => {
    const { value } = await Preferences.get({ key });
    if (value !== null) nativePreferences.set(key, value);
  }));
}
const sanitize = (html) => DOMPurify.sanitize(html, {
  ALLOWED_TAGS: ["p", "h1", "h2", "h3", "h4", "ul", "ol", "li", "pre", "code", "a", "blockquote", "strong", "em", "br", "hr"],
  ALLOWED_ATTR: ["href", "class", "id"],
});
let snapshot;
let syncing = false;
let articleKey = "";
let readyForProgress = false;
let indexListener;
let routeListener;
let pendingRoute;
const preparedBodies = new WeakMap();
const dbPromise = new Promise((resolve, reject) => {
  const request = indexedDB.open("young-blog-reader", 1);
  request.onupgradeneeded = () => request.result.createObjectStore("content");
  request.onsuccess = () => resolve(request.result);
  request.onerror = () => reject(request.error);
});
// A browser may deny storage; bundled articles still work.
dbPromise.catch(() => {});
async function storedSnapshot(value) {
  const db = await dbPromise;
  return new Promise((resolve, reject) => {
    const tx = db.transaction("content", value ? "readwrite" : "readonly");
    const store = tx.objectStore("content");
    const request = value ? store.put(value, "active") : store.get("active");
    tx.oncomplete = () => resolve(request.result);
    tx.onerror = () => reject(tx.error);
    tx.onabort = () => reject(tx.error || new Error("Storage was interrupted"));
  });
}
function preference(key, fallback = "") {
  if (nativePreferences.has(`reader:${key}`)) return nativePreferences.get(`reader:${key}`);
  try { return localStorage.getItem(`reader:${key}`) ?? fallback; } catch { return fallback; }
}
function savePreference(key, value) {
  if (native) {
    nativePreferences.set(`reader:${key}`, value);
    pendingWrites = pendingWrites.then(() => Preferences.set({ key: `reader:${key}`, value }))
      .catch((error) => console.warn("Could not save reading preferences", error));
  }
  try { localStorage.setItem(`reader:${key}`, value); } catch { /* Reading remains available. */ }
}
function uiText(en, hans, hant = hans) {
  return document.documentElement.lang === "en" ? en : document.documentElement.lang === "zh-Hant" ? hant : hans;
}
function notify(message) {
  const toast = document.getElementById("reader-toast");
  toast.textContent = message;
  clearTimeout(notify.timer);
  notify.timer = setTimeout(() => { toast.textContent = ""; }, 4500);
}
async function remoteText(path) {
  if (native) {
    const response = await CapacitorHttp.get({
      url: SITE_ORIGIN + path, responseType: "text", connectTimeout: 12000, readTimeout: 20000,
      headers: { "Cache-Control": "no-cache" },
    });
    if (response.status !== 200) throw new Error(`HTTP ${response.status}`);
    return typeof response.data === "string" ? response.data : JSON.stringify(response.data);
  }
  const response = await fetch(SITE_ORIGIN + path, { cache: "no-store", signal: AbortSignal.timeout(20000) });
  if (!response.ok) throw new Error(`HTTP ${response.status}`);
  return response.text();
}
async function syncContent() {
  if (syncing) return;
  syncing = true;
  document.documentElement.dataset.syncing = "true";
  notify(uiText("Checking for new articles…", "正在检查新文章…", "正在檢查新文章…"));
  try {
    let manifest;
    let raw;
    try { raw = await remoteText("/content-index.json"); }
    catch (error) {
      if (error.message !== "HTTP 404") throw error;
      raw = "<legacy>";
    }
    if (/^\s*</.test(raw)) {
      manifest = await legacyManifest(await remoteText("/posts.js"));
    } else {
      manifest = validateManifest(JSON.parse(raw));
    }
    // Legacy indexes omit body revisions, so they are always downloaded.
    if (snapshot?.manifest.version === manifest.version && manifest.articles.every((a) => a.sha256)) {
      notify(uiText("Your library is up to date.", "文章库已是最新。", "文章庫已是最新。"));
      return;
    }
    const next = await downloadSnapshot(manifest, remoteText, sanitize);
    await storedSnapshot(next);
    snapshot = next;
    globalThis.BLOG_POSTS_SEXP = manifest.postsSexp;
    indexListener?.();
    savePreference("synced", new Date().toISOString());
    notify(uiText("Library updated. Articles are available offline.", "更新完成，文章已可离线阅读。", "更新完成，文章已可離線閱讀。"));
  } catch (error) {
    console.warn("Content refresh failed", error);
    notify(uiText("Could not refresh. Your saved library is still available.", "暂时无法更新，仍可阅读本地文章。", "暫時無法更新，仍可閱讀本地文章。"));
  } finally {
    syncing = false;
    delete document.documentElement.dataset.syncing;
  }
}
function saveProgress() {
  if (articleKey && readyForProgress) savePreference(`position:${articleKey}`, String(window.scrollY));
}
function prepareBody() {
  const body = document.querySelector(".article-body");
  if (!body || body.closest("[data-article-path]")?.dataset.articlePath !== articleKey) return;
  const prepared = preparedBodies.get(body);
  if (prepared?.path === articleKey && prepared.node === body.firstChild) return;
  body.dataset.prepared = "true";
  body.dataset.readerReady = "false";
  body.querySelectorAll(".article-toc,.copy-code").forEach((element) => element.remove());
  let headingIndex = 0;
  const headings = Array.from(body.querySelectorAll("h1,h2,h3"));
  headings.forEach((heading) => { heading.id = `section-${headingIndex++}`; });
  if (headings.length > 1) {
    const details = document.createElement("details");
    details.className = "article-toc";
    const summary = document.createElement("summary");
    summary.textContent = uiText("On this page", "本文目录", "本文目錄");
    details.append(summary);
    for (const heading of headings) {
      const link = document.createElement("a");
      link.href = `#${heading.id}`;
      link.textContent = heading.textContent;
      details.append(link);
    }
    body.prepend(details);
  }
  for (const pre of body.querySelectorAll("pre")) {
    const button = document.createElement("button");
    button.className = "copy-code";
    button.textContent = uiText("Copy", "复制", "複製");
    button.type = "button";
    button.addEventListener("click", async () => {
      try {
        await navigator.clipboard.writeText(pre.querySelector("code").textContent);
        notify(uiText("Code copied", "代码已复制", "程式碼已複製"));
      } catch { notify(uiText("Select the code to copy it.", "请长按选择代码复制。", "請長按選擇程式碼複製。")); }
    });
    pre.prepend(button);
  }
  // inner_html can replace children while reusing the same outer element.
  const preparation = { path: articleKey, node: body.firstChild };
  preparedBodies.set(body, preparation);
  readyForProgress = false;
  const restoreKey = articleKey;
  requestAnimationFrame(() => requestAnimationFrame(() => {
    if (restoreKey !== articleKey || !body.isConnected || preparedBodies.get(body) !== preparation) return;
    if (location.hash) document.getElementById(location.hash.slice(1))?.scrollIntoView();
    else window.scrollTo(0, Number(preference(`position:${articleKey}`, "0")));
    readyForProgress = true;
    body.dataset.readerReady = "true";
  }));
}

globalThis.BlogReader = {
  flush() { saveProgress(); return pendingWrites; },
  get: preference,
  set: savePreference,
  subscribeIndex(callback) { indexListener = callback; },
  subscribeRoute(callback) {
    routeListener = callback;
    if (pendingRoute) { callback(pendingRoute); pendingRoute = undefined; }
  },
  async readArticle(path, callback) {
    try {
      let html = snapshot?.articles[path];
      if (html === undefined) {
        const response = await fetch(path);
        if (!response.ok) throw new Error("Article unavailable");
        html = await response.text();
        if (/<!doctype|<html[\s>]/i.test(html)) throw new Error("Article unavailable");
        html = sanitize(html);
      }
      callback(true, html);
    } catch {
      callback(false, uiText("This article is unavailable. Try refreshing your library.", "文章暂时不可用，请尝试更新文章库。", "文章暫時無法使用，請嘗試更新文章庫。"));
    }
  },
  sync() { void syncContent(); },
  font(size) {
    savePreference("font", String(size));
    document.documentElement.style.setProperty("--reader-font-size", `${size}px`);
  },
  theme(value) {
    savePreference("theme", value);
    document.documentElement.dataset.theme = value;
  },
  route(path, lang, title) {
    document.documentElement.lang = lang;
    document.title = `${title} · Young Blog`;
    if (articleKey === path) return;
    saveProgress();
    articleKey = path;
    readyForProgress = false;
    document.querySelectorAll(".mobile-categories[open], .reader-settings[open]").forEach((panel) => panel.removeAttribute("open"));
    savePreference("route", path);
    window.scrollTo(0, 0);
    queueMicrotask(prepareBody);
  },
  async share(path, title) {
    try {
      const url = SITE_ORIGIN + path;
      if (native) await Share.share({ title, url });
      else if (navigator.share) await navigator.share({ title, url });
      else { await navigator.clipboard.writeText(url); notify(uiText("Link copied", "链接已复制", "連結已複製")); }
    } catch (error) { if (error.name !== "AbortError") console.info("Share dismissed", error); }
  },
};

document.documentElement.dataset.theme = preference("theme", "system");
document.documentElement.style.setProperty("--reader-font-size", `${Math.max(15, Math.min(26, Number(preference("font", "18")) || 18))}px`);
try {
  snapshot = await storedSnapshot();
  if (snapshot) {
    validateManifest(snapshot.manifest);
    if (snapshot.manifest.articles.some((a) => typeof snapshot.articles[a.path] !== "string")) throw new Error("Incomplete saved library");
    globalThis.BLOG_POSTS_SEXP = snapshot.manifest.postsSexp;
  }
} catch { snapshot = undefined; }
if (location.pathname === "/") {
  const preferred = preference("route");
  const language = navigator.language.startsWith("zh") ? "zh-hans" : "en";
  history.replaceState(null, "", /^\/(tech|essays)\/(en|zh-hans|zh-hant)(\/|$)/.test(preferred) ? preferred : `/tech/${language}`);
}
// Bonsai replaces the mount element, so observe its stable parent.
new MutationObserver(prepareBody).observe(document.body, { childList: true, subtree: true });
let scrollTimer;
window.addEventListener("scroll", () => {
  clearTimeout(scrollTimer);
  scrollTimer = setTimeout(saveProgress, 200);
}, { passive: true });
window.addEventListener("pagehide", saveProgress);
document.addEventListener("visibilitychange", () => { if (document.hidden) saveProgress(); });
document.addEventListener("click", (event) => {
  const link = event.target.closest?.("a[href]");
  if (!link || event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
  const target = new URL(link.href);
  if (target.origin === location.origin && target.pathname !== location.pathname) {
    saveProgress();
    readyForProgress = false;
  }
}, true);
window.addEventListener("popstate", () => {
  if (location.pathname !== articleKey) {
    saveProgress();
    readyForProgress = false;
  }
}, true);
function openArticleUrl(url) {
  try {
    const target = new URL(url);
    if (target.origin === SITE_ORIGIN && /^\/(tech|essays)\/(en|zh-hans|zh-hant)(\/|$)/.test(target.pathname)) {
      saveProgress();
      readyForProgress = false;
      if (routeListener) routeListener(target.pathname);
      else pendingRoute = target.pathname;
    }
  } catch { /* Ignore URLs outside this blog. */ }
}
if (native) {
  App.addListener("appUrlOpen", ({ url }) => openArticleUrl(url));
  const launch = await App.getLaunchUrl();
  if (launch?.url) openArticleUrl(launch.url);
  App.addListener("backButton", ({ canGoBack }) => {
    const panel = document.querySelector(".mobile-categories[open], .reader-settings[open]");
    if (panel) panel.removeAttribute("open");
    else if (canGoBack) history.back();
    else if (location.pathname.split("/").filter(Boolean).length > 2) {
      routeListener?.("/" + location.pathname.split("/").filter(Boolean).slice(0, 2).join("/"));
    } else App.minimizeApp();
  });
  App.addListener("appStateChange", async ({ isActive }) => {
    if (!isActive) { saveProgress(); await pendingWrites; }
  });
}
const app = document.createElement("script");
app.src = "/app.js";
app.onerror = () => { document.getElementById("app").textContent = "Unable to start Young Blog. Please reopen the app."; };
document.body.append(app);
