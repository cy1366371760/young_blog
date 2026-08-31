# Publishing Workflow

This project keeps publishing simple:

1. Write Markdown under `content/`.
2. Commit to `main`.
3. GitHub Actions builds the OCaml/Bonsai site.
4. The workflow pushes static output to the `deploy` branch.
5. Cloudflare Pages publishes the `deploy` branch.

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
