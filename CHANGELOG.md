# Changelog

This project follows a lightweight version of Keep a Changelog. Dates use
`YYYY-MM-DD`.

## Unreleased

### Fixed

- Declared the pinned OCaml formatter as a development dependency and installed
  development dependencies in Android CI, fixing clean-runner format checks.

### Added

- Added a Capacitor Android reader with signed local APK/AAB builds, a custom
  launcher icon, native sharing, article intents, and system/keyboard insets.
- Added Bonsai search, tag filters, translated favorites, reading preferences,
  mobile topic navigation, a generated article outline, and code copying.
- Added first-launch offline content and atomic, verified content snapshots,
  including compatibility with the existing posts.js publishing format.
- Added pure OCaml expect tests, content synchronization tests, browser tests,
  native emulator smoke tests, Android CI, and architecture documentation.

- Added bilingual Jane Street video notes beginning with Why OCaml, including
  the Boolean evaluator transcription and examples of parameterized interpretation.

- Added the first Chinese-first diary and its English translation under
  Essays / Notes / Daily, with a generated Traditional Chinese variant.
- Added a diary helper for unpublished drafts, paired-source preparation,
  validation, PR creation, protected merging, and deploy-branch verification.
- Added diary workflow documentation and failure-path tests for the helper.
- Added independent content-area and locale route dimensions.
- Added English, Simplified Chinese, and Traditional Chinese UI localization.
- Added locale-aware article asset paths and an unavailable-translation state.
- Added English and Simplified Chinese versions of every existing article.
- Added OpenCC-based Traditional Chinese generation that preserves code.
- Added a mandatory AI article workflow covering translation, PR creation,
  merge, and deployment verification.
- Added rules for producing polished bilingual articles from review text and
  related OCaml source files.
- Added paired-source and shared-metadata validation for every article.
- Added a content validation helper and paired article skeleton generator.
- Added article detail routing and on-demand article body loading.
- Added generated per-article HTML assets under `articles/`.
- Added Cloudflare Pages SPA fallback support through `public/_redirects`.
- Added the `tech/ocaml-learning/ocaml-in-atcoder` content framework for
  AtCoder notes and OCaml implementations.
- Added an AtCoder note template and starter page.
- Added five published AtCoder beginner-problem notes with OCaml solutions and
  reviewed learning reflections.
- Added an OCaml write-up for AtCoder ABC085B, Kagami Mochi.
- Added an OCaml write-up for AtCoder ABC085C, Otoshidama, including an
  improved lazy-sequence implementation.

### Changed

- Refined the Why OCaml notes with a blog-filtering example, clearer terminology,
  and concise reflections on reusable rules and engineering tradeoffs.

- Displayed article lists directly in the main column and moved category and
  subcategory selection into a persistent right-hand navigation panel.
- Derived locale, content-area, and route filters through separate Bonsai
  incremental values so navigation changes only recompute affected lists.
- Moved source content under `content/<area>/<locale>/...`.
- Updated the content generator and new-post helper for locale-aware content.
- Kept one Chinese source per article by deriving Traditional Chinese at build
  time.
- Updated fast content publishing to deploy both `posts.js` and `articles/`.
- Humanized known category and subcategory labels on article cards.
- Replaced the flat section index with navigable category and subcategory pages.
- Refined the navigation and article-reading typography.

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
