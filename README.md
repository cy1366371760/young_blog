# Young Blog

A bilingual personal blog built with OCaml, Bonsai, and a static publishing
pipeline.

Content type and language are independent. Source files use:

```text
content/<tech|essays>/<en|zh-hans|zh-hant>/<category>/<subcategory>/<date>-<slug>.md
```

The corresponding public URLs begin with the same content type and locale, for
example `/tech/en/...` or `/essays/zh-hans/...`. Each translated article keeps
the same `translation_key`; add its localized Markdown source when it is ready.

Application changes rebuild the OCaml/Bonsai bundle. Content-only changes use a
lighter publish path that only regenerates post data.

Project context for future maintainers and AI agents starts in `AGENTS.md`.
Current status is tracked in `docs/project-status.md`, and durable architecture
decisions live under `docs/adr/`.
