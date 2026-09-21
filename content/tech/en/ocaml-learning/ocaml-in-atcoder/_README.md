# OCaml in AtCoder

This folder is for English technical notes about solving AtCoder problems in OCaml.

Use this subcategory for:

- AtCoder problem write-ups.
- OCaml implementations and small library patterns.
- Notes about translating competitive-programming ideas into typed, readable
  OCaml.
- Reflections on mistakes, performance, parsing, data structures, and proof
  sketches.

## Frontmatter

Use this category path:

```toml
category = "ocaml-learning"
subcategory = "ocaml-in-atcoder"
```

Suggested tags:

```toml
tags = ["ocaml", "atcoder", "competitive-programming"]
```

## File Naming

Name posts with the usual date prefix:

```text
yyyy-mm-dd-atcoder-<contest-or-problem>-<short-slug>.md
```

Examples:

```text
2026-09-08-atcoder-abc086a-product.md
2026-09-08-atcoder-abc081a-placing-marbles.md
```

## Article Shape

Start from `_atcoder_template.md` when adding a new note. Keep the solution
write-up compact, then put the full OCaml implementation near the end.
