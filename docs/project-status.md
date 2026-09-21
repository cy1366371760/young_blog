# Project Status

Last updated: 2026-09-21.

## Current State

The project has an OCaml/Bonsai single-page blog shell. Content area (`Tech` or
`Essays`) and locale (`English`, `简体中文`, or `繁體中文`) are independent route
dimensions. The UI localizes its navigation and supporting copy, and reserves a
future comments boundary.

The English technical area now has an `ocaml-learning` category with an
`ocaml-in-atcoder` subcategory for AtCoder examples, OCaml solutions, and
problem-solving reflections.

The repository is connected to GitHub at:

```text
https://github.com/cy1366371760/young_blog
```

Cloudflare Pages should deploy from the `deploy` branch. The `deploy` branch is
static-only and should contain only browser assets such as `index.html`,
`styles.css`, `posts.js`, `articles/`, `_redirects`, and `app.js`.

## Recent PRs

- `#1 Add fast content publishing path`
  - Branch: `pr/fast-content-publish`
  - Status: merged.
  - Purpose: separate content publishing from full OCaml/Bonsai rebuilds.
- `#2 Add project context documents`
  - Branch: `pr/fast-content-publish`
  - Status: merged.
  - Purpose: add lightweight project memory for future maintainers and AI agents.

## Implemented

- Dune/opam project skeleton.
- Bonsai frontend entry point.
- Independent typed content-area and locale models.
- URL-driven language selection for English, Simplified Chinese, and
  Traditional Chinese.
- Localized navigation and UI copy, including an explicit message when an
  article translation has not been published yet.
- English and Simplified Chinese versions of every current article.
- Build-time generation of Traditional Chinese with OpenCC from a single
  Simplified Chinese source, preserving code spans and code blocks.
- Repository-level AI runbook for translating, validating, opening and merging
  content PRs, and verifying deployment.
- Source-material workflow for turning review text and related `.ml` files into
  polished bilingual articles with naturally placed, unchanged code listings.
- Build-time validation that every article has paired English and Simplified
  Chinese sources with shared routing metadata and unchanged code.
- Static build script that emits `dist/`.
- GitHub Actions publishing to `deploy`.
- Fast content publishing design.
- Markdown frontmatter to generated post index.
- Generated article HTML assets.
- URL-driven article detail pages.
- URL-driven category and subcategory index pages.
- Bonsai article loading state machine for article body fetches.
- Cloudflare Pages SPA fallback file.
- OCaml in AtCoder content framework, starter note, and seven beginner-problem
  write-ups with OCaml implementations.

## Next Steps

1. Configure Cloudflare Pages to serve the `deploy` branch and honor `_redirects`.
2. Review the initial article translations for tone and terminology.
3. Add Bonsai state for query, tags, category, and subcategory filters.
4. Replace the illustrative Incremental trace panel with real state-driven
   highlights.
5. Add a small smoke test script for generated assets.

## Known Risks

- The initial `app.js` bundle is large. This is acceptable for the MVP but should
  be revisited after article loading and the basic UX are stable.
- `scripts/generate_posts.mjs` supports a small JSON-style subset of TOML
  frontmatter. If richer frontmatter is needed, add a parser deliberately rather
  than expanding ad hoc parsing too far.
- The Markdown renderer intentionally supports only a small safe subset.
- Clean article URLs need Cloudflare Pages fallback behavior from `_redirects` in
  production. Basic static servers may return 404 for direct deep links.

## Operational Notes

- Content-only updates should not require opam, Dune, or js_of_ocaml.
- Application updates should run the full OCaml/Bonsai build.
- If Cloudflare reports submodule errors, inspect the `deploy` branch tree first;
  it should not contain `_opam`, `_build`, or `.gitmodules`.
