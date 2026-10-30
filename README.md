# Young Blog

A bilingual personal blog built with OCaml, Bonsai, and a static publishing
pipeline.

The same Bonsai reader is available as an Android application. Run
`npm run build:android` to generate a signed installable APK and AAB. See
[`docs/android-reader.md`](docs/android-reader.md) for environment setup,
offline behavior, signing, and tests.

Content type and language are independent. Source files use:

```text
content/<tech|essays>/<en|zh-hans>/<category>/<subcategory>/<date>-<slug>.md
```

The corresponding public URLs begin with the same content type and locale, for
example `/tech/en/...` or `/essays/zh-hans/...`. English and Simplified Chinese
are stored as Markdown sources. Traditional Chinese is generated from the
Simplified Chinese source with OpenCC, while fenced and inline code remains
unchanged. Each translation keeps the same `translation_key`.

Application changes rebuild the OCaml/Bonsai bundle. Content-only changes use a
lighter publish path that only regenerates post data.

Project context for future maintainers and AI agents starts in `AGENTS.md`.
The complete AI article workflow is documented in
`docs/agent-content-workflow.md`.
Current status is tracked in `docs/project-status.md`, and durable architecture
decisions live under `docs/adr/`.

For Chinese-first diaries, use `node scripts/diary.mjs --help` and follow
`docs/diary-workflow.md`. The helper prepares paired sources, validates all
three variants, and can create a PR, merge it, and verify deployment after
editorial review and translation.
