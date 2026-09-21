# ADR 0003: Generate Traditional Chinese at Build Time

## Status

Accepted.

## Context

The blog supports English, Simplified Chinese, and Traditional Chinese. Keeping
separate Simplified and Traditional Markdown files would duplicate content and
make later corrections easy to miss. Converting the rendered page in the
browser would add a runtime dependency and leave static article assets with the
wrong language before JavaScript runs.

OpenCC provides phrase-aware conversion between Simplified and Traditional
Chinese. The `opencc-js` package can run in the existing Node.js publishing
pipeline without a native system dependency.

## Decision

Store Chinese article sources under `zh-hans` only. During content generation,
use OpenCC's standard Simplified-to-Traditional conversion to emit a parallel
`zh-hant` post record and article asset.

Convert titles, summaries, tags, and Markdown prose. Preserve fenced code blocks
and inline code exactly. When both English and Chinese sources exist, the
generator also verifies that their fenced code blocks are identical.

## Consequences

- Authors maintain one Chinese source per article.
- Both Chinese locales still have independent static URLs and HTML assets.
- Readers do not download conversion code or dictionaries in the browser.
- Traditional Chinese is a script conversion, not a Taiwan- or Hong Kong-style
  editorial translation. Wording can still require human review.
- Publishing requires `npm ci` before running the content generator.
