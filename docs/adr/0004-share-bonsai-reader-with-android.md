# ADR 0004: Share the Bonsai Reader with Android

## Status

Accepted.

## Context

The blog needs an installable Android reader with offline content while retaining
its role as an OCaml/Bonsai learning project. Reimplementing its UI in a second
framework would duplicate routing, filtering, localization, and reading behavior.

## Decision

- Package the existing release-mode Dune output in Capacitor 8, targeting Android
  SDK 36 with a minimum SDK of 24. Load packaged assets from the local HTTPS origin.
- Keep UI state and derived filters in Bonsai v0.17. Define pure search and
  request-reduction logic in `src/reader_core/`, with expect tests.
- Put platform effects behind `Reader_platform.mli`. The JavaScript adapter
  implements storage, content transport, code copying, progress, and system share.
- Bundle every generated language variant for first-launch offline reading.
- Generate a versioned content manifest with SHA-256 hashes. Download and verify
  every article before atomically replacing one IndexedDB snapshot. An interrupted
  refresh leaves the previous snapshot available. Sanitize HTML before rendering.
- Support the existing `posts.js` format by decoding its data assignment without
  evaluating remote JavaScript. Legacy snapshots lack body hashes and are fetched
  again on each explicit refresh.
- Scope favorites to content area and translation key. Scope reading positions
  to the language-specific article route. Android preferences use the native
  Preferences store, with an in-memory read view; browser preferences use
  localStorage. Use Capacitor's native SystemBars inset handling instead of
  applying an additional independent layer of native padding.
- Keep signing keys and passwords outside Git. Local release builds reuse the
  identity in `~/.local/share/young-blog/`; CI produces debug artifacts only.

## Consequences

Website and Android behavior share the Bonsai implementation. Article publishing
does not require rebuilding the APK. Shell changes are distributed in a new APK.
The native wrapper handles keyboard and system-bar insets and exposes registered
HTTPS article intents. Automatic verified App Links additionally require a hosted
Digital Asset Links association for the distribution certificate.

The reader stores a complete downloaded snapshot. This is appropriate for the
current small text library; a substantially larger collection should adopt
per-article downloads and an explicit storage budget. Native-system behavior
still needs device testing in addition to browser and pure-model tests.

## Design references

- [Jane Street: Thinking in Bonsai](https://github.com/janestreet/bonsai_web/blob/master/docs/thinking_in_bonsai.md)
  motivates explicit dependencies and state lifecycle boundaries.
- [Jane Street: Incremental computation and the web](https://blog.janestreet.com/incrementality-and-the-web/)
  informs the separately derived context, filtering, and presentation values.
- [Jane Street: Testing with expectations](https://blog.janestreet.com/testing-with-expectations/)
  informs scenario-based tests, including the A/B/A delayed-response regression.
- [Jane Street: Ironing out your development style](https://blog.janestreet.com/ironing-out-your-development-style/)
  informs reviewable changes and behavior traces.
- [Capacitor configuration](https://capacitorjs.com/docs/config) and
  [Android edge-to-edge guidance](https://developer.android.com/develop/ui/views/layout/edge-to-edge)
  describe the platform integration. Newer Bonsai documentation is conceptual
  guidance; code uses the installed v0.17 interfaces.
