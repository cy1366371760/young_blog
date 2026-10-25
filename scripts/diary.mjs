#!/usr/bin/env node

import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";
import { setTimeout as delay } from "node:timers/promises";

const repositoryRoot = fileURLToPath(new URL("../", import.meta.url));
const locales = ["en", "zh-hans", "zh-hant"];

export function diaryPaths(date) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date) || new Date(`${date}T00:00:00Z`).toISOString().slice(0, 10) !== date) {
    throw new Error("Use a real calendar date in YYYY-MM-DD format.");
  }
  return {
    drafts: ["zh-hans", "en"].map((locale) => `content/inbox/diary/${date}/${locale}.md`),
    sources: ["zh-hans", "en"].map((locale) => `content/essays/${locale}/notes/daily/${date}-diary.md`),
    assets: locales.map((locale) => `articles/essays/${locale}/notes/daily/${date}.html`),
    routes: locales.map((locale) => `/essays/${locale}/notes/daily/${date}`),
  };
}

function run(command, args, { cwd = repositoryRoot, capture = false } = {}) {
  const result = spawnSync(command, args, {
    cwd,
    encoding: "utf8",
    stdio: capture ? ["ignore", "pipe", "pipe"] : "inherit",
  });
  if (result.error) throw result.error;
  if (result.status !== 0) {
    throw new Error(`${command} ${args.join(" ")} failed${result.stderr ? `: ${result.stderr.trim()}` : "."}`);
  }
  return capture ? result.stdout.trimEnd() : "";
}

const git = (...args) => run("git", args, { capture: true });
const ghJson = (...args) => JSON.parse(run("gh", args, { capture: true }));

function skeleton(date, title) {
  return `+++\ntitle = ${JSON.stringify(title)}\ndate = "${date}"\ncategory = "notes"\nsubcategory = "daily"\nslug = "${date}"\ntranslation_key = "diary-${date}"\ntags = ["diary"]\ndraft = false\ncomments = false\n+++\n\nTODO: Finish the Chinese diary first, then translate it into English.\n`;
}

export function newDiary(date, root = repositoryRoot) {
  const { drafts } = diaryPaths(date);
  if (drafts.some((file) => fs.existsSync(path.join(root, file)))) {
    throw new Error("A diary draft already exists for this date; edit it instead.");
  }
  for (const file of drafts) {
    fs.mkdirSync(path.dirname(path.join(root, file)), { recursive: true });
    fs.writeFileSync(path.join(root, file), skeleton(date, "TODO: Diary title"), { flag: "wx" });
  }
  console.log(drafts.join("\n"));
}

export function completedSource(source, date) {
  const match = source.match(/^\+\+\+\n([\s\S]*?)\n\+\+\+\n([\s\S]*)$/);
  if (!match || /\bTODO\b|\bTBD\b|待翻译|待填写/i.test(source)) {
    throw new Error("Finish both diary drafts, including their titles and translation, before preparing them.");
  }
  const fields = {};
  for (const line of match[1].split("\n")) {
    if (!line.trim() || line.trim().startsWith("#")) continue;
    const field = line.match(/^([a-z_]+)\s*=\s*(.+)$/);
    if (!field || Object.hasOwn(fields, field[1])) throw new Error("Invalid or duplicate diary metadata.");
    fields[field[1]] = JSON.parse(field[2]);
  }
  const expected = { date, category: "notes", subcategory: "daily", slug: date, translation_key: `diary-${date}`, draft: false, comments: false };
  for (const [name, value] of Object.entries(expected)) {
    if (fields[name] !== value) throw new Error(`Diary metadata must use ${name} = ${JSON.stringify(value)}.`);
  }
  if (typeof fields.title !== "string" || !fields.title.trim() || !match[2].trim()) {
    throw new Error("Each diary needs a title and a nonempty body.");
  }
  return source;
}

export function prepareDiary(date, root = repositoryRoot) {
  const { drafts, sources } = diaryPaths(date);
  const contents = drafts.map((file) => completedSource(fs.readFileSync(path.join(root, file), "utf8"), date));
  if (sources.some((file) => fs.existsSync(path.join(root, file)))) {
    throw new Error("Published-source files already exist; edit the paired sources directly instead of overwriting them.");
  }
  sources.forEach((file, index) => {
    fs.mkdirSync(path.dirname(path.join(root, file)), { recursive: true });
    fs.writeFileSync(path.join(root, file), contents[index], { flag: "wx" });
  });
  console.log(sources.join("\n"));
}

function checkDiary(date) {
  const { sources, assets, routes } = diaryPaths(date);
  sources.forEach((file) => completedSource(fs.readFileSync(path.join(repositoryRoot, file), "utf8"), date));
  const temporaryRoot = fs.mkdtempSync(path.join(os.tmpdir(), "blog-diary-"));
  try {
    run(process.execPath, ["scripts/generate_posts.mjs", path.join(temporaryRoot, "posts.js")]);
    for (const asset of assets) {
      if (!fs.statSync(path.join(temporaryRoot, asset)).size) throw new Error(`Empty generated asset: ${asset}`);
    }
    run("git", ["diff", "--check"]);
  } finally {
    fs.rmSync(temporaryRoot, { recursive: true, force: true });
  }
  console.log(`Validated all three diary variants:\n${routes.join("\n")}`);
}

export function verifyAssets(expectedAssets, readAsset) {
  for (const asset of expectedAssets) {
    if (!readAsset(asset).trim()) throw new Error(`Missing or empty deployed diary asset: ${asset}`);
  }
}

export function successfulRuns(runs, expectedNames) {
  for (const name of expectedNames) {
    if (!runs.some((run) => run.workflowName === name)) throw new Error(`Missing deployment workflow: ${name}`);
  }
  for (const run of runs) {
    if (run.status !== "completed" || run.conclusion !== "success") {
      throw new Error(`Workflow has not succeeded: ${run.url}`);
    }
  }
}

async function finishDiary(pr, date) {
  const { assets, routes } = diaryPaths(date);
  let info = ghJson("pr", "view", pr, "--json", "url,state,headRefOid,mergeCommit,statusCheckRollup,baseRefName,files");
  if (info.baseRefName !== "main") throw new Error("The diary PR must target main.");
  if (!diaryPaths(date).sources.every((file) => info.files.some((entry) => entry.path === file))) {
    throw new Error("The PR must contain both diary sources for this date.");
  }
  console.log(`PR: ${info.url}`);
  if (info.state === "OPEN") {
    if (info.statusCheckRollup.length) run("gh", ["pr", "checks", pr, "--watch", "--fail-fast", "--interval", "10"]);
    run("gh", ["pr", "merge", pr, "--squash", "--match-head-commit", info.headRefOid]);
    info = ghJson("pr", "view", pr, "--json", "url,state,mergeCommit");
  }
  if (info.state !== "MERGED" || !info.mergeCommit?.oid) {
    throw new Error(`PR is not merged. Resolve required reviews, checks, or merge-queue requirements, then rerun finish: ${info.url}`);
  }
  const sha = info.mergeCommit.oid;
  console.log(`Merge commit: ${sha}`);
  const changes = ghJson("pr", "view", pr, "--json", "files").files.map((file) => file.path);
  const expectedNames = ["Publish content"];
  if (changes.some((file) => /^(src\/|public\/|scripts\/(build_site\.sh|generate_posts\.mjs)$|\.github\/workflows\/publish\.yml$|\.ocamlformat$|dune$|dune-project$|ocaml_blog\.opam$)/.test(file))) {
    expectedNames.push("Publish blog");
  }
  let runs = [];
  for (let attempt = 0; attempt < 24; attempt++) {
    runs = ghJson("run", "list", "--branch", "main", "--commit", sha, "--limit", "100", "--json", "databaseId,workflowName,status,conclusion,url");
    if (expectedNames.every((name) => runs.some((run) => run.workflowName === name))) break;
    await delay(5000);
  }
  for (const workflow of runs) {
    console.log(`Workflow: ${workflow.url}`);
    if (workflow.status !== "completed") run("gh", ["run", "watch", String(workflow.databaseId), "--exit-status", "--interval", "10"]);
  }
  runs = ghJson("run", "list", "--branch", "main", "--commit", sha, "--limit", "100", "--json", "databaseId,workflowName,status,conclusion,url");
  successfulRuns(runs, expectedNames);
  run("git", ["fetch", "origin", "main", "deploy"]);
  verifyAssets(assets, (asset) => git("show", `origin/deploy:${asset}`));
  const temporaryRoot = fs.mkdtempSync(path.join(os.tmpdir(), "blog-diary-deploy-"));
  try {
    // Regenerate from the merged sources so stale same-date assets cannot pass.
    for (const file of diaryPaths(date).sources) {
      const destination = path.join(temporaryRoot, file);
      fs.mkdirSync(path.dirname(destination), { recursive: true });
      fs.writeFileSync(destination, `${git("show", `${sha}:${file}`)}\n`);
    }
    run(process.execPath, [path.join(repositoryRoot, "scripts/generate_posts.mjs"), path.join(temporaryRoot, "posts.js")], { cwd: temporaryRoot });
    for (const asset of assets) {
      if (fs.readFileSync(path.join(temporaryRoot, asset), "utf8").trimEnd() !== git("show", `origin/deploy:${asset}`)) {
        throw new Error(`Deployed asset differs from the merged diary: ${asset}`);
      }
    }
    const index = git("show", "origin/deploy:posts.js");
    if ((index.match(new RegExp(`diary-${date}`, "g")) ?? []).length !== 3) {
      throw new Error("The deploy post index must contain all three diary variants.");
    }
  } finally {
    fs.rmSync(temporaryRoot, { recursive: true, force: true });
  }
  console.log(`Deployment verified on origin/deploy.\n${routes.join("\n")}`);
  if (process.env.BLOG_SITE_URL) {
    const site = new URL(process.env.BLOG_SITE_URL);
    if (site.protocol !== "https:") throw new Error("BLOG_SITE_URL must use HTTPS.");
    let lastError;
    for (let attempt = 0; attempt < 24; attempt++) {
      try {
        for (const [index, asset] of assets.entries()) {
          const liveAsset = run("curl", ["--fail", "--silent", "--show-error", "--location", "--max-time", "15", new URL(`/${asset}?diary=${sha}`, site).href], { capture: true });
          if (liveAsset !== git("show", `origin/deploy:${asset}`)) {
            throw new Error(`Production asset is not current: ${asset}`);
          }
          const route = new URL(routes[index], site);
          const page = run("curl", ["--fail", "--silent", "--show-error", "--location", "--max-time", "15", route.href], { capture: true });
          if (!page.includes("app.js")) throw new Error(`Production route is unavailable: ${route}`);
        }
        console.log(`Production verified:\n${routes.map((route) => new URL(route, site).href).join("\n")}`);
        return;
      } catch (error) {
        lastError = error;
        if (attempt < 23) await delay(5000);
      }
    }
    throw lastError;
  }
  console.log("Set BLOG_SITE_URL to verify the production routes and assets before reporting the site live.");
}

async function publishDiary(date, prOnly) {
  const { sources } = diaryPaths(date);
  checkDiary(date);
  if (git("diff", "--cached", "--name-only")) throw new Error("Unstage existing changes before publishing a diary.");
  const changed = git("status", "--porcelain", "--untracked-files=all").split("\n").filter(Boolean);
  if (!changed.length || changed.some((line) => !sources.includes(line.slice(3)))) {
    throw new Error("Only this diary's two source files may be changed; commit other work separately first.");
  }
  run("git", ["fetch", "origin", "main"]);
  if (git("rev-parse", "HEAD") !== git("rev-parse", "origin/main")) {
    throw new Error("Start from the latest origin/main before publishing; preserve your current work first.");
  }
  run("git", ["switch", "-c", `codex/diary-${date}`]);
  run("git", ["add", "--", ...sources]);
  run("git", ["commit", "-m", `Add diary for ${date}`]);
  run("git", ["push", "-u", "origin", `codex/diary-${date}`]);
  const temporaryRoot = fs.mkdtempSync(path.join(os.tmpdir(), "blog-diary-pr-"));
  let pr;
  try {
    const bodyFile = path.join(temporaryRoot, "body.md");
    fs.writeFileSync(bodyFile, `Add the Chinese-first diary for ${date} and its English translation to Essays / Notes / Daily. Traditional Chinese is generated with OpenCC.\n\nValidation: paired-source checks, generation of all three diary variants, and git diff --check.\n`);
    pr = run("gh", ["pr", "create", "--base", "main", "--head", `codex/diary-${date}`, "--title", `Add diary for ${date}`, "--body-file", bodyFile], { capture: true });
  } finally {
    fs.rmSync(temporaryRoot, { recursive: true, force: true });
  }
  console.log(`PR: ${pr}`);
  console.log(`Resume publishing if needed: node scripts/diary.mjs finish ${date} ${pr}`);
  if (!prOnly) await finishDiary(pr, date);
}

async function main() {
  const [command, date, option, ...extra] = process.argv.slice(2);
  if (extra.length || (option && !((command === "publish" && option === "--pr-only") || command === "finish"))) {
    throw new Error("Unexpected arguments. See node scripts/diary.mjs --help.");
  }
  if (!command || command === "--help") {
    console.log("Usage: node scripts/diary.mjs <new|prepare|check|publish> YYYY-MM-DD [--pr-only]\n       node scripts/diary.mjs finish YYYY-MM-DD <PR-number-or-URL>\n\nWrite and review Chinese first, translate English manually or with Codex, then prepare, check, and publish. Dates are explicit so entries written after midnight keep their intended day. Publishing creates a PR, merges without bypass flags, waits for workflows, and verifies the deploy branch. Use --pr-only to stop for review.");
    return;
  }
  diaryPaths(date ?? "");
  if (command === "new") newDiary(date);
  else if (command === "prepare") prepareDiary(date);
  else if (command === "check") checkDiary(date);
  else if (command === "publish") await publishDiary(date, option === "--pr-only");
  else if (command === "finish" && option) await finishDiary(option, date);
  else throw new Error("Unknown command or missing PR. See node scripts/diary.mjs --help.");
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main().catch((error) => {
    console.error(error.message);
    process.exitCode = 1;
  });
}
