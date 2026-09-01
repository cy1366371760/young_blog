# Changelog

This project follows a lightweight version of Keep a Changelog. Dates use
`YYYY-MM-DD`.

## Unreleased

### Added

- Added article detail routing and on-demand article body loading.
- Added generated per-article HTML assets under `articles/`.
- Added Cloudflare Pages SPA fallback support through `public/_redirects`.

### Changed

- Updated fast content publishing to deploy both `posts.js` and `articles/`.

## 2026-09-01

### Added

- Bootstrapped the OCaml/Bonsai blog MVP.
- Added two top-level sections: English technical notes and Chinese notes or
  writing.
- Added initial Markdown content examples.
- Added Cloudflare Pages publishing through a `deploy` branch.
- Added a generated `posts.js` data file so the Bonsai app can load post indexes
  without baking content into the OCaml bundle.
- Added a fast content publishing workflow for Markdown-only updates.
- Added category and subcategory metadata to post cards.
- Added project context documents for future maintainers and AI agents.

### Changed

- Limited the full OCaml/Bonsai publish workflow to application and static-shell
  changes.
- Updated the build script to emit a clean `dist/` directory.

### Fixed

- Cleaned the `deploy` branch so Cloudflare does not see `_opam` or `_build` as
  deployable content.
