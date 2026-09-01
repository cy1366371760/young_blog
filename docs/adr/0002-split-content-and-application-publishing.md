# ADR 0002: Split Content and Application Publishing

## Status

Accepted.

## Context

The first publishing workflow rebuilt the full OCaml/Bonsai application for
every change. That is acceptable for application development but too slow for
travel writing, phone-based updates, and small content edits.

## Decision

Split publishing into two workflows:

- `Publish blog` rebuilds the full OCaml/Bonsai bundle when application or
  static-shell files change.
- `Publish content` regenerates post data for `content/**` changes and updates
  the `deploy` branch without installing OCaml dependencies.

The generated post index is loaded before the Bonsai app through `posts.js`.

## Consequences

- Content-only updates are much faster and better suited to mobile publishing
  through the GitHub connector.
- The frontend bundle can remain stable while post metadata changes.
- The generated data format becomes a compatibility boundary between content
  tooling and the Bonsai app.
- Full rebuilds are still available when code or shell assets change.

## Alternatives Considered

- Rebuild the full app for every content update. This is simple but too slow for
  frequent writing.
- Store all posts in the OCaml source. This gives strong typing but makes every
  article edit a code rebuild.
- Fetch raw Markdown directly from GitHub at runtime. This would add external
  runtime coupling and make Cloudflare deployment less self-contained.
