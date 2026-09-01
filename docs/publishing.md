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
content/<section>/<category>/<subcategory>/<yyyy-mm-dd-slug>.md
```

Examples:

```text
content/tech/ocaml/ocaml-learning/2026-09-01-bonsai-first-note.md
content/zh/notes/daily/2026-09-01-first-travel-note.md
```

`content/inbox/` is for rough drafts that need sorting later.

## Mobile publishing through Codex

Send Codex the section, category, subcategory, title, tags, and body. Codex can
create the Markdown file and commit it through the GitHub plugin.

For content-only edits, this should be a fast deploy path: no opam switch, no
Dune rebuild, and no js_of_ocaml compilation.

## Article URLs

Generated article URLs follow the content hierarchy:

```text
/<section>/<category>/<subcategory>/<slug>
```

The generated article body lives under:

```text
/articles/<section>/<category>/<subcategory>/<slug>.html
```

Cloudflare Pages should publish the `deploy` branch and honor `_redirects` so
direct article URLs fall back to `index.html` and are handled by the Bonsai app.
