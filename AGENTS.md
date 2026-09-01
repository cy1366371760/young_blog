# Agent Guide

This repository is a learning-oriented personal blog built with OCaml, Bonsai,
and a static publishing pipeline.

## Project Goals

- Build a bilingual personal blog while learning Jane Street-style OCaml web
  development.
- Use Bonsai and Incremental deliberately, especially for filtering, search,
  cached article loading, and eventually an interactive computation trace.
- Keep the code small, readable, and reviewable. Prefer narrow PRs over large
  rewrites.
- Keep all project files, comments, docs, commit messages, and PR descriptions
  in English.

## Product Shape

- Top-level sections:
  - English technical learning notes.
  - Chinese reflections, notes, and literary writing.
- Content hierarchy:
  `content/<section>/<category>/<subcategory>/<yyyy-mm-dd-slug>.md`
- Comments are intentionally not implemented yet, but the UI reserves a
  boundary for a future comments provider.

## Engineering Conventions

- Use Dune and opam as the source of truth for OCaml builds.
- Prefer Core and Jane Street ppx conventions already present in the project.
- Keep OCaml modules typed and small. Add `.mli` files for public boundaries.
- Use short English comments only where they clarify non-obvious decisions.
- Use `ocamlformat` with the Jane Street profile.
- Do not commit generated build outputs:
  - `_build/`
  - `_opam/`
  - `dist/`
  - `public/articles/`
  - `public/posts.js`

## Useful Commands

```sh
opam exec -- dune build @fmt
opam exec -- scripts/build_site.sh
node scripts/generate_posts.mjs public/posts.js
```

For a local static smoke test:

```sh
python3 -m http.server 8891 --directory dist
```

## Publishing Model

- `main` contains source code and Markdown content.
- `deploy` contains static output for Cloudflare Pages.
- `Publish blog` rebuilds the OCaml/Bonsai app for application changes.
- `Publish content` updates `posts.js` and `articles/` for content-only changes
  without installing OCaml dependencies.

Cloudflare Pages should point at the `deploy` branch with:

- Framework preset: `None`
- Build command: `exit 0`
- Build output directory: `.`
- Root directory: empty

## Current Architecture

- `src/app/` contains the Bonsai frontend.
- `scripts/generate_posts.mjs` reads Markdown frontmatter and generates
  `posts.js` plus per-article HTML files in `public/articles/`.
- `public/index.html` loads `posts.js` before `app.js`.
- `Post.load` reads `globalThis.BLOG_POSTS_SEXP`, parses it with sexp support,
  and falls back to sample data if the generated data is unavailable.
- `Route` owns clean blog URLs and parses them into typed OCaml route values.
- `Article_loader` fetches generated article HTML when the route selects an
  article. It uses a Bonsai state machine so stale responses do not overwrite
  newer navigation.

## Known Gaps

- Search and tag filters are UI placeholders.
- The Incremental trace panel is still illustrative, not wired to real
  computation events.
- The JavaScript bundle is large because this is an early js_of_ocaml/Bonsai
  build with no size optimization pass yet.

## Before Opening A PR

- Run `opam exec -- dune build @fmt`.
- Run `opam exec -- scripts/build_site.sh` for application changes.
- For content-only changes, run `node scripts/generate_posts.mjs public/posts.js`.
- Smoke test generated article assets when Markdown rendering changes.
- Update `CHANGELOG.md` and `docs/project-status.md` when the project state
  changes.
- Add an ADR under `docs/adr/` when a durable architectural decision is made.
