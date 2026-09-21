# AI Content Publishing Runbook

This runbook is mandatory for AI-assisted article additions, edits, and
deletions. Unless the user explicitly asks for local-only or draft-only work,
finish the complete lifecycle: translate, validate, open a pull request, merge,
and verify deployment.

GitHub calls a merge request a pull request (PR). Use the term PR in commit and
repository-facing text.

## Source Model

Every article has exactly two maintained source files:

```text
content/<area>/en/<category>/<subcategory>/<date>-<slug>.md
content/<area>/zh-hans/<category>/<subcategory>/<date>-<slug>.md
```

The generator derives `zh-hant` from `zh-hans` with OpenCC. Never create or edit
a `content/<area>/zh-hant/` source file.

Both sources must use the same:

- `translation_key`
- `date`
- `category`
- `subcategory`
- fenced code blocks
- inline code values

Titles, summaries, prose, and display tags may be localized. Keep slugs stable
unless the user explicitly requests localized slugs.

## Translation Rules

- If the user supplies one language, write the other language in the same
  change.
- Translate meaning and tone naturally; do not translate sentence by sentence
  mechanically when that produces awkward prose.
- Do not translate or rewrite fenced code blocks, inline code, identifiers,
  commands, paths, URLs, data, or required program output.
- Keep product and library names such as OCaml, Bonsai, Core, Jane Street, and
  AtCoder unchanged.
- Preserve Markdown structure, links, heading levels, and list organization.
- Traditional Chinese is generated script conversion, not a separate editorial
  translation. Review generated output when terminology is sensitive.

The generator enforces source pairing, shared metadata, unique locale variants,
and unchanged code. Treat any validation failure as a content error; do not
bypass the check.

## Add An Article

1. Read nearby articles and templates to match their structure and tone.
2. Create both source files. The helper creates a paired skeleton:

   ```sh
   scripts/new_post.sh <tech|essays> <category> <subcategory> <slug>
   ```

3. Fill in both languages and use the same `translation_key`.
4. Keep all code byte-for-byte identical in both files.
5. Run the validation commands below.

## Edit An Article

1. Locate every source with its `translation_key`.
2. Apply the semantic change to both `en` and `zh-hans` in the same PR.
3. If code changes, copy the exact updated code to both versions.
4. Do not edit generated `zh-hant`, `public/posts.js`, or `public/articles/`.
5. Run the validation commands below.

## Delete An Article

1. Locate the pair by `translation_key`.
2. Delete both `en` and `zh-hans` source files in the same PR.
3. Search for links or indexes that reference the deleted article and update
   them.
4. Run the validation commands below. The content deployment replaces the
   generated article directory, so the three published variants are removed.

## Validation

Install JavaScript dependencies first:

```sh
npm ci
```

For every content change, run:

```sh
scripts/check_content.sh
git diff --check
```

For application or generator changes, also run:

```sh
opam exec -- dune build @fmt
opam exec -- scripts/build_site.sh
```

Do not commit `_build/`, `_opam/`, `dist/`, `public/articles/`, or
`public/posts.js`.

## Pull Request And Merge

Use a narrow branch prefixed with `codex/`. Do not mix unrelated working-tree
changes into the content PR.

```sh
git fetch origin
git switch -c codex/<short-content-name> origin/main
git add <only-the-intended-files>
git commit -m "<short English description>"
git push -u origin codex/<short-content-name>
gh pr create --base main --head codex/<short-content-name> --title "<English title>" --body "<English summary and validation>"
gh pr checks --watch
gh pr merge --squash --delete-branch
```

If repository rules require review or block automatic merging, stop after the
PR is ready and report the exact blocker. Never bypass branch protection.

## Deployment Verification

A merge to `main` triggers one or both GitHub Actions workflows:

- `Publish content` for Markdown changes.
- `Publish blog` for application, generator, or public-shell changes.

Wait for every workflow triggered by the merge commit. A push is not a finished
publication.

```sh
gh run list --branch main --limit 10
gh run watch <run-id> --exit-status
```

Then fetch and inspect the generated branch:

```sh
git fetch origin deploy
git ls-tree -r --name-only origin/deploy
```

For an added or edited article, confirm that `deploy` contains the expected
`en`, `zh-hans`, and `zh-hant` HTML assets. For a deletion, confirm that all
three are absent. If a production URL is configured and discoverable, open the
three public routes and verify the rendered article. Otherwise, explicitly
report that deployment succeeded but the repository does not record a live
site URL.

The final handoff must include:

- PR URL and merge result
- merge commit
- workflow result and URL
- public routes for all three locales
- any remaining deployment or hosting blocker
