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

## Write From Review And Source Files

Use this workflow when the target folder contains `review.txt`, a name such as
`review-*.txt`, or another clearly designated review or draft text file.

1. Inventory the folder before drafting. Read the review file completely, find
   every path or source filename it mentions, and inspect the relevant `.ml`
   files in the same folder. Resolve relative references from the review file's
   directory. Do not invent content for a referenced file that is missing.
2. Determine the review file's primary language from its prose. Write and
   finish the article in that language first. A mixed-language filename, code
   sample, or technical term does not change the primary language.
3. Treat the review as source material, not publication-ready prose. Preserve
   its facts, conclusions, and authorial point of view while:
   - removing repetition and incidental scratch notes;
   - correcting grammar and unclear transitions;
   - ordering the argument so each section motivates the next;
   - preferring short, direct explanations over inflated prose;
   - adding only context that is supported by the review or inspected source.
4. Build a natural article structure for the material. A technical review will
   often flow through context, problem, key idea, implementation, review or
   improvement, and lessons learned, but do not force empty sections.
5. Include every meaningful `.ml` source file explicitly referenced by the
   review. Also include an unmentioned `.ml` file when it materially explains
   the article, such as a final implementation, an improved version, or a
   contrasting attempt. Do not add unrelated files merely because they share
   the folder.
6. Place each source listing beside the prose that explains it, rather than
   dumping all code at the end. Introduce the filename and its role, use an
   `ocaml` fenced block, and keep the source byte-for-byte unchanged. Include
   the complete file by default; if a file is generated or exceptionally large,
   use the smallest coherent excerpt and state clearly that it is an excerpt.
7. Do not translate, reformat, repair, or silently modernize source code or its
   comments while embedding it. If the code appears wrong, explain the issue in
   prose and preserve the source. Make code changes only when the user asks for
   them, then apply the identical change to every article language version.
8. Review the completed primary-language article on its own before translating:
   verify the logic, remove avoidable verbosity, confirm code placement, and
   check every factual statement against the review and source files.
9. Translate that finished article into the other maintained language. Preserve
   its structure and meaning, but rewrite sentences naturally for the target
   language. Copy every fenced code block and inline code value exactly from the
   primary-language article.
10. Use the same `translation_key`, date, category, and subcategory in both
    sources, then run the standard content validation and publishing lifecycle.

Review files are inputs, not generated article assets. Do not move, rewrite,
delete, or publish them unless the user explicitly asks. Include an untracked
review file in the PR only when the user asks to preserve it in the repository.

## Add An Article

1. Read nearby articles and templates to match their structure and tone. If a
   review-like text file is present, follow the source-file workflow above
   before drafting.
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
