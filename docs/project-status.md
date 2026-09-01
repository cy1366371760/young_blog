# Project Status

Last updated: 2026-09-01.

## Current State

The project has an OCaml/Bonsai single-page blog shell with two top-level
sections. The UI uses the selected bilingual journal style and reserves a future
comments boundary.

The repository is connected to GitHub at:

```text
https://github.com/cy1366371760/young_blog
```

Cloudflare Pages should deploy from the `deploy` branch. The `deploy` branch is
static-only and should contain only browser assets such as `index.html`,
`styles.css`, `posts.js`, and `app.js`.

## Recent PRs

- `#1 Add fast content publishing path`
  - Branch: `pr/fast-content-publish`
  - Status: merged.
  - Purpose: separate content publishing from full OCaml/Bonsai rebuilds.

## Implemented

- Dune/opam project skeleton.
- Bonsai frontend entry point.
- Two top-level blog sections.
- Initial post model and typed section model.
- Static build script that emits `dist/`.
- GitHub Actions publishing to `deploy`.
- Fast content publishing design.
- Markdown frontmatter to generated post index.

## Next Steps

1. Add article body output:
   - generate per-article static pages, or
   - generate Markdown/HTML assets loaded on demand.
2. Add Bonsai state for query, tags, category, subcategory, and selected post.
3. Replace the illustrative Incremental trace panel with real state-driven
   highlights.
4. Add a small smoke test script for generated assets.

## Known Risks

- The initial `app.js` bundle is large. This is acceptable for the MVP but should
  be revisited after article loading and the basic UX are stable.
- `scripts/generate_posts.mjs` supports a small JSON-style subset of TOML
  frontmatter. If richer frontmatter is needed, add a parser deliberately rather
  than expanding ad hoc parsing too far.
- The current UI links to article URLs, but article body pages are not generated
  yet.

## Operational Notes

- Content-only updates should not require opam, Dune, or js_of_ocaml.
- Application updates should run the full OCaml/Bonsai build.
- If Cloudflare reports submodule errors, inspect the `deploy` branch tree first;
  it should not contain `_opam`, `_build`, or `.gitmodules`.
