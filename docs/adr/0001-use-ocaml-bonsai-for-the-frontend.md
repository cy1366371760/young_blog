# ADR 0001: Use OCaml and Bonsai for the Frontend

## Status

Accepted.

## Context

The project is both a personal blog and a learning vehicle for Jane
Street-style OCaml frontend development. The owner wants to learn Bonsai and
Incremental by building a real, maintainable site rather than a toy demo.

## Decision

Use OCaml, Bonsai, Virtual_dom, and js_of_ocaml for the frontend. Keep the first
version small: a Bonsai single-page shell, typed post metadata, two top-level
sections, and static deployment.

## Consequences

- The project can demonstrate Bonsai state and Incremental-style derived
  computations in normal blog interactions such as filtering and search.
- The OCaml dependency graph is heavier than a plain static site generator.
- Content publishing needs a fast path so writing Markdown does not require a
  full js_of_ocaml rebuild.
- Future work should make Bonsai's strengths visible through keyed lists,
  cached article loading, and a real computation trace panel.

## Alternatives Considered

- A conventional JavaScript static site generator would be faster to bootstrap
  but would not serve the OCaml learning goal.
- Pure static HTML would be simpler but would not exercise Bonsai or
  Incremental.
