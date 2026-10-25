# Chinese-First Diary Publishing

Diaries use the existing Essays / Notes / Daily section. Each date has two
maintained sources, English and Simplified Chinese, and an OpenCC-generated
Traditional Chinese variant. The source filename is `<date>-diary.md`; its
explicit slug is the date, so entries on different days never share a URL:

```text
/essays/zh-hans/notes/daily/2026-10-25
/essays/en/notes/daily/2026-10-25
/essays/zh-hant/notes/daily/2026-10-25
```

## Prepare An Entry

Use Node.js, Git, curl, GitHub CLI (`gh auth login`), and the repository's npm
dependencies (`npm ci`). Work from the latest `origin/main` in a clean checkout.
Always supply the intended diary date explicitly, especially after midnight.

```sh
node scripts/diary.mjs new 2026-10-25
```

This creates editable files in `content/inbox/diary/2026-10-25/`. The inbox is
excluded from generation, and diary drafts are ignored by Git. Unfinished
English translations cannot accidentally enter the published index.

Finish `zh-hans.md` first, keeping the author's voice and opinions. Then ask
Codex to translate the finished entry into `en.md`, or translate it manually.
Review both titles, summaries, and bodies. Preserve inline and fenced code
exactly, and retain the generated shared metadata. Translation deliberately
requires editorial work; the script does not call a translation API.

```sh
node scripts/diary.mjs prepare 2026-10-25
node scripts/diary.mjs check 2026-10-25
```

`prepare` rejects unfinished drafts and refuses to overwrite existing sources.
`check` runs the existing generator's bilingual metadata and code checks,
verifies all three generated assets, and checks whitespace. To revise an entry
after preparation, edit both maintained sources directly and run `check`
again. The normal article runbook applies to subsequent edits and deletions.

## Publish And Verify

Review the two prepared files before invoking the publishing command. It
authorizes committing, pushing, creating a PR, and merging it if GitHub allows:

```sh
BLOG_SITE_URL=https://young-blog.pages.dev node scripts/diary.mjs publish 2026-10-25
```

The command accepts only that day's two source files as working-tree changes
and requires an empty staging area and a HEAD matching the fetched
`origin/main`. It creates `codex/diary-2026-10-25`, stages only the two sources,
commits them, and opens a PR with an English description. It waits for reported
checks, uses a normal squash merge with an expected head commit and no bypass
flags, then waits for every discovered workflow associated with the merge.
It requires the expected publish workflows to succeed, regenerates the merged
diary, compares all three HTML files against `origin/deploy`, and checks the
deployed index for the three translations. It never force-pushes.

For a review stop, use:

```sh
node scripts/diary.mjs publish 2026-10-25 --pr-only
```

If checks, reviews, permissions, a merge queue, or deployment block progress,
the script exits with the failure and leaves the branch and PR available.
Fix the blocker, then resume without creating a duplicate PR:

```sh
node scripts/diary.mjs finish 2026-10-25 <PR-number-or-URL>
```

`finish` also accepts an already merged PR, but requires that it target `main`
and include both diary sources. Do not use it for unrelated PRs.

The script verifies GitHub Actions and the `deploy` branch. With `BLOG_SITE_URL`
set, it also waits for the three production HTML assets to match the deployed
files and confirms all three clean routes serve the application shell. Use the
same variable with `finish` when resuming after a blocker. Without it, the
script reports deploy-branch verification only. Review the rendered pages
before reporting the entry live. When Codex invokes the script, attach the
resulting PR to the current task and complete the handoff required by
`agent-content-workflow.md`. No generated output or raw diary draft belongs in
the PR. A first-time tooling change may share a focused PR with its example
diary; create that PR explicitly because `publish` only stages the two diary
sources.

Run the helper's failure-path tests with:

```sh
node --test scripts/diary.test.mjs
```
