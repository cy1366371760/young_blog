# Publishing Workflow

This project keeps publishing simple:

1. Write Markdown under `content/`.
2. Commit to `main`.
3. GitHub Actions updates the `deploy` branch.
4. Cloudflare Pages publishes the `deploy` branch.

There are two publish paths:

- `Publish content` runs for content-only changes. It regenerates `posts.js` and
  `articles/` without installing OCaml dependencies.
- `Publish blog` runs when application code changes. It rebuilds the
  OCaml/Bonsai bundle and publishes the full static site.

## Content hierarchy

Use this shape:

```text
content/<area>/<locale>/<category>/<subcategory>/<yyyy-mm-dd-slug>.md
```

Store English under `en` and Chinese under `zh-hans`. Do not create `zh-hant`
source files: the generator produces Traditional Chinese metadata and article
prose from each Simplified Chinese source. Fenced code blocks and inline code
are excluded from conversion.

Examples:

```text
content/tech/en/ocaml/ocaml-learning/2026-09-01-bonsai-first-note.md
content/tech/zh-hans/ocaml/ocaml-learning/2026-09-01-bonsai-first-note.md
content/essays/en/notes/daily/2026-09-01-first-travel-note.md
content/essays/zh-hans/notes/daily/2026-09-01-first-travel-note.md
```

`content/inbox/` is for rough drafts that need sorting later.

## Mobile publishing through Codex

Send Codex the content area, category, subcategory, title, tags, and body in
either English or Chinese. Codex must create or update both maintained language
sources, preserve code, validate the generated variants, open and merge a pull
request, and verify deployment according to `docs/agent-content-workflow.md`.

For content-only edits, this should be a fast deploy path: no opam switch, no
Dune rebuild, and no js_of_ocaml compilation.

## Article URLs

Generated article URLs follow the content hierarchy:

```text
/<area>/<locale>/<category>/<subcategory>/<slug>
```

The generated article body lives under:

```text
/articles/<area>/<locale>/<category>/<subcategory>/<slug>.html
```

Cloudflare Pages should publish the `deploy` branch and honor `_redirects` so
direct article URLs fall back to `index.html` and are handled by the Bonsai app.
