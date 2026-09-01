#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";

const contentRoot = "content";
const outputPath = process.argv[2] ?? "public/posts.js";
const outputRoot = path.dirname(outputPath);
const articlesRoot = path.join(outputRoot, "articles");

function walk(dir) {
  return fs.readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
    const fullPath = path.join(dir, entry.name);

    if (entry.isDirectory()) {
      return entry.name === "inbox" ? [] : walk(fullPath);
    }

    if (!entry.isFile() || !entry.name.endsWith(".md") || entry.name.startsWith("_")) {
      return [];
    }

    return [fullPath];
  });
}

function parseFrontmatter(source, filePath) {
  if (!source.startsWith("+++\n")) {
    throw new Error(`${filePath}: missing TOML frontmatter`);
  }

  const end = source.indexOf("\n+++\n", 4);
  if (end < 0) {
    throw new Error(`${filePath}: unterminated TOML frontmatter`);
  }

  const rawFrontmatter = source.slice(4, end);
  const body = source.slice(end + 5).trim();
  const fields = {};

  for (const line of rawFrontmatter.split("\n")) {
    const trimmed = line.trim();
    if (trimmed === "" || trimmed.startsWith("#")) continue;

    const match = trimmed.match(/^([A-Za-z_][A-Za-z0-9_-]*)\s*=\s*(.+)$/);
    if (!match) {
      throw new Error(`${filePath}: invalid frontmatter line: ${line}`);
    }

    fields[match[1]] = parseValue(match[2], filePath);
  }

  return { fields, body };
}

function parseValue(raw, filePath) {
  const value = raw.trim();

  if (value.startsWith("[") || value.startsWith("\"")) {
    try {
      return JSON.parse(value);
    } catch {
      throw new Error(`${filePath}: only JSON-style TOML strings/arrays are supported`);
    }
  }

  return value;
}

function slugFromFilename(filePath) {
  const basename = path.basename(filePath, ".md");
  return basename.replace(/^\d{4}-\d{2}-\d{2}-/, "");
}

function dateFromFilename(filePath) {
  const match = path.basename(filePath).match(/^(\d{4}-\d{2}-\d{2})-/);
  return match?.[1];
}

function summaryFromBody(body) {
  return body
    .split(/\n\s*\n/)
    .map((paragraph) => paragraph.replace(/^#+\s+/, "").replace(/\s+/g, " ").trim())
    .find((paragraph) => paragraph !== "")
    ?? "";
}

function assertPathSegment(value, field, filePath) {
  if (!/^[A-Za-z0-9._-]+$/.test(value)) {
    throw new Error(`${filePath}: ${field} must be a URL-safe path segment`);
  }
}

function sectionConstructor(section) {
  switch (section) {
    case "tech":
      return "Tech_en";
    case "zh":
      return "Zh_notes";
    default:
      throw new Error(`unknown section: ${section}`);
  }
}

function escapeHtml(value) {
  return value
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

function escapeAttribute(value) {
  return escapeHtml(value).replace(/`/g, "&#96;");
}

function renderInline(source) {
  const token = /(`([^`]+)`)|\[([^\]]+)\]\((https?:\/\/[^)\s]+|\/[^)\s]+)\)/g;
  let html = "";
  let lastIndex = 0;
  let match;

  while ((match = token.exec(source)) !== null) {
    html += escapeHtml(source.slice(lastIndex, match.index));

    if (match[2] !== undefined) {
      html += `<code>${escapeHtml(match[2])}</code>`;
    } else {
      html += `<a href="${escapeAttribute(match[4])}">${escapeHtml(match[3])}</a>`;
    }

    lastIndex = token.lastIndex;
  }

  html += escapeHtml(source.slice(lastIndex));
  return html;
}

function renderMarkdown(source) {
  const lines = source.split("\n");
  const html = [];
  let paragraph = [];
  let inList = false;
  let inCode = false;
  let codeLanguage = "";
  let codeLines = [];

  function flushParagraph() {
    if (paragraph.length === 0) return;
    html.push(`<p>${renderInline(paragraph.join(" "))}</p>`);
    paragraph = [];
  }

  function closeList() {
    if (!inList) return;
    html.push("</ul>");
    inList = false;
  }

  function closeCode() {
    const languageClass = codeLanguage === "" ? "" : ` class="language-${escapeAttribute(codeLanguage)}"`;
    html.push(`<pre><code${languageClass}>${escapeHtml(codeLines.join("\n"))}</code></pre>`);
    codeLanguage = "";
    codeLines = [];
    inCode = false;
  }

  for (const line of lines) {
    const fence = line.match(/^```([A-Za-z0-9_-]*)\s*$/);
    if (fence) {
      if (inCode) {
        closeCode();
      } else {
        flushParagraph();
        closeList();
        inCode = true;
        codeLanguage = fence[1] ?? "";
      }
      continue;
    }

    if (inCode) {
      codeLines.push(line);
      continue;
    }

    if (line.trim() === "") {
      flushParagraph();
      closeList();
      continue;
    }

    const heading = line.match(/^(#{1,3})\s+(.+)$/);
    if (heading) {
      flushParagraph();
      closeList();
      html.push(`<h${heading[1].length}>${renderInline(heading[2].trim())}</h${heading[1].length}>`);
      continue;
    }

    const quote = line.match(/^>\s?(.+)$/);
    if (quote) {
      flushParagraph();
      closeList();
      html.push(`<blockquote>${renderInline(quote[1].trim())}</blockquote>`);
      continue;
    }

    const item = line.match(/^[-*]\s+(.+)$/);
    if (item) {
      flushParagraph();
      if (!inList) {
        html.push("<ul>");
        inList = true;
      }
      html.push(`<li>${renderInline(item[1].trim())}</li>`);
      continue;
    }

    paragraph.push(line.trim());
  }

  if (inCode) closeCode();
  flushParagraph();
  closeList();

  return html.join("\n");
}

function sexpAtom(value) {
  if (/^[A-Za-z0-9_./:-]+$/.test(value)) {
    return value;
  }

  return JSON.stringify(value)
    .replace(/\\/g, "\\\\")
    .replace(/\(/g, "\\(")
    .replace(/\)/g, "\\)");
}

function sexpString(value) {
  return JSON.stringify(value);
}

function sexpList(values) {
  return `(${values.map((value) => sexpString(value)).join(" ")})`;
}

function postFromFile(filePath) {
  const relPath = path.relative(contentRoot, filePath);
  const [sectionFromPath, categoryFromPath, subcategoryFromPath] = relPath.split(path.sep);
  const { fields, body } = parseFrontmatter(fs.readFileSync(filePath, "utf8"), filePath);

  const section = fields.section ?? sectionFromPath;
  const date = fields.date ?? dateFromFilename(filePath);
  const category = fields.category ?? categoryFromPath;
  const subcategory = fields.subcategory ?? subcategoryFromPath;

  for (const [name, value] of Object.entries({ title: fields.title, section, date, category, subcategory })) {
    if (typeof value !== "string" || value === "") {
      throw new Error(`${filePath}: missing required field: ${name}`);
    }
  }

  const tags = fields.tags ?? [];
  if (!Array.isArray(tags) || tags.some((tag) => typeof tag !== "string")) {
    throw new Error(`${filePath}: tags must be a string array`);
  }

  return {
    title: fields.title,
    section: sectionConstructor(section),
    sectionPath: section,
    category,
    subcategory,
    date,
    tags,
    summary: fields.summary ?? summaryFromBody(body),
    slug: fields.slug ?? slugFromFilename(filePath),
    body,
    filePath,
  };
}

function validatePostPath(post) {
  assertPathSegment(post.sectionPath, "section", post.filePath);
  assertPathSegment(post.category, "category", post.filePath);
  assertPathSegment(post.subcategory, "subcategory", post.filePath);
  assertPathSegment(post.slug, "slug", post.filePath);
}

function postToSexp(post) {
  return [
    "(",
    `(title ${sexpString(post.title)})`,
    `(section ${post.section})`,
    `(category ${sexpString(post.category)})`,
    `(subcategory ${sexpString(post.subcategory)})`,
    `(date ${sexpAtom(post.date)})`,
    `(tags ${sexpList(post.tags)})`,
    `(summary ${sexpString(post.summary)})`,
    `(slug ${sexpString(post.slug)})`,
    ")",
  ].join(" ");
}

function writeArticle(post) {
  validatePostPath(post);

  const html = renderMarkdown(post.body);
  const outputFile = path.join(
    articlesRoot,
    post.sectionPath,
    post.category,
    post.subcategory,
    `${post.slug}.html`,
  );

  fs.mkdirSync(path.dirname(outputFile), { recursive: true });
  fs.writeFileSync(outputFile, `${html}\n`);
}

const posts = walk(contentRoot)
  .map(postFromFile)
  .sort((left, right) => right.date.localeCompare(left.date) || left.title.localeCompare(right.title));

const sexp = `(${posts.map(postToSexp).join("\n ")})`;
const output = `globalThis.BLOG_POSTS_SEXP = ${JSON.stringify(sexp)};\n`;

fs.mkdirSync(path.dirname(outputPath), { recursive: true });
fs.rmSync(articlesRoot, { recursive: true, force: true });
fs.writeFileSync(outputPath, output);
posts.forEach(writeArticle);
console.log(`Generated ${posts.length} posts in ${outputPath} and ${articlesRoot}`);
