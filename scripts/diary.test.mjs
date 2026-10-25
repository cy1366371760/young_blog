import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { completedSource, diaryPaths, newDiary, prepareDiary, successfulRuns, verifyAssets } from "./diary.mjs";

const date = "2026-10-25";

function workspace(t) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "diary-test-"));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  return root;
}

function finishDrafts(root) {
  for (const file of diaryPaths(date).drafts) {
    const fullPath = path.join(root, file);
    fs.writeFileSync(fullPath, fs.readFileSync(fullPath, "utf8")
      .replace("TODO: Diary title", "A diary")
      .replace("TODO: Finish the Chinese diary first, then translate it into English.", "A finished entry.\n\n```ocaml\nlet x = 1\n```"));
  }
}

test("rejects invalid dates and traversal, with unique routes for successive days", () => {
  for (const invalid of ["2026-02-30", "2026-13-01", "../../file", "2026-1-1", ""]) {
    assert.throws(() => diaryPaths(invalid));
  }
  assert.notDeepEqual(diaryPaths(date).assets, diaryPaths("2026-10-26").assets);
});

test("unfinished translations stay in the inbox and cannot be prepared", (t) => {
  const root = workspace(t);
  newDiary(date, root);
  assert.throws(() => prepareDiary(date, root), /Finish both/);
  assert.ok(diaryPaths(date).sources.every((file) => !fs.existsSync(path.join(root, file))));
  assert.throws(() => newDiary(date, root), /already exists/);
});

test("prepares both reviewed sources byte-for-byte without overwriting existing files", (t) => {
  const root = workspace(t);
  newDiary(date, root);
  finishDrafts(root);
  prepareDiary(date, root);
  const { drafts, sources } = diaryPaths(date);
  sources.forEach((source, index) => assert.equal(fs.readFileSync(path.join(root, source), "utf8"), fs.readFileSync(path.join(root, drafts[index]), "utf8")));
  assert.throws(() => prepareDiary(date, root), /already exist/);
});

test("rejects metadata drift, duplicate fields, empty bodies, and incomplete English before copying either source", (t) => {
  const root = workspace(t);
  newDiary(date, root);
  finishDrafts(root);
  const english = path.join(root, diaryPaths(date).drafts[1]);
  const source = fs.readFileSync(english, "utf8");
  for (const invalid of [
    source.replace('date = "2026-10-25"', 'date = "2026-10-26"'),
    source.replace("draft = false", "draft = true"),
    source.replace('title = "A diary"', 'title = ""'),
    source.replace("comments = false", "comments = false\ncomments = false"),
    source.replace(/\n\+\+\+\n[\s\S]*$/, "\n+++\n"),
    source.replace("A finished entry.", "TODO: Translate this."),
  ]) {
    assert.throws(() => completedSource(invalid, date));
  }
  fs.writeFileSync(english, source.replace("A finished entry.", "TODO: Translate this."));
  assert.throws(() => prepareDiary(date, root));
  assert.ok(diaryPaths(date).sources.every((file) => !fs.existsSync(path.join(root, file))));
});

test("deployment verification fails for a missing locale or an empty asset", () => {
  const assets = diaryPaths(date).assets;
  assert.throws(() => verifyAssets(assets, (asset) => asset.includes("zh-hant") ? "" : "<p>Diary</p>"), /zh-hant/);
  assert.throws(() => verifyAssets(assets, () => { throw new Error("git show failed"); }), /git show failed/);
  verifyAssets(assets, () => "<p>Diary</p>");
});

test("deployment requires every expected workflow and rejects failure, cancellation, and pending runs", () => {
  const success = { workflowName: "Publish content", status: "completed", conclusion: "success", url: "https://example.com/run" };
  assert.throws(() => successfulRuns([], ["Publish content"]), /Missing/);
  assert.throws(() => successfulRuns([success], ["Publish content", "Publish blog"]), /Publish blog/);
  for (const conclusion of ["failure", "cancelled", null]) {
    assert.throws(() => successfulRuns([{ ...success, conclusion }], ["Publish content"]), /not succeeded/);
  }
  assert.throws(() => successfulRuns([{ ...success, status: "in_progress" }], ["Publish content"]));
  successfulRuns([success], ["Publish content"]);
});

test("the publishing command refuses unrelated or staged changes without creating a branch or staging diaries", (t) => {
  const root = workspace(t);
  const repository = fileURLToPath(new URL("../", import.meta.url));
  fs.mkdirSync(path.join(root, "scripts"));
  for (const script of ["diary.mjs", "generate_posts.mjs"]) {
    fs.copyFileSync(path.join(repository, "scripts", script), path.join(root, "scripts", script));
  }
  fs.symlinkSync(path.join(repository, "node_modules"), path.join(root, "node_modules"), "dir");
  fs.writeFileSync(path.join(root, ".gitignore"), "node_modules/\ncontent/inbox/\n");
  const git = (...args) => {
    const result = spawnSync("git", args, { cwd: root, encoding: "utf8" });
    assert.equal(result.status, 0, result.stderr);
    return result.stdout.trim();
  };
  git("init", "-b", "main");
  git("config", "user.name", "Diary Test");
  git("config", "user.email", "diary-test@example.com");
  git("add", ".");
  git("commit", "-m", "Set up fixture");
  newDiary(date, root);
  finishDrafts(root);
  prepareDiary(date, root);
  fs.writeFileSync(path.join(root, "unrelated.txt"), "Keep this work.\n");
  const publish = () => spawnSync(process.execPath, ["scripts/diary.mjs", "publish", date], { cwd: root, encoding: "utf8" });
  let result = publish();
  assert.equal(result.status, 1);
  assert.match(result.stderr, /Only this diary's two source files/);
  assert.equal(git("branch", "--show-current"), "main");
  assert.equal(git("diff", "--cached", "--name-only"), "");
  git("add", "unrelated.txt");
  result = publish();
  assert.equal(result.status, 1);
  assert.match(result.stderr, /Unstage existing changes/);
  assert.equal(git("diff", "--cached", "--name-only"), "unrelated.txt");
  assert.equal(fs.readFileSync(path.join(root, "unrelated.txt"), "utf8"), "Keep this work.\n");
});
