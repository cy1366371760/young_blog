#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
temporary_root="$(mktemp -d)"
trap 'rm -rf "$temporary_root"' EXIT

cd "$repository_root"
node scripts/generate_posts.mjs "$temporary_root/posts.js"

article_count="$(find "$temporary_root/articles" -type f -name '*.html' | wc -l | tr -d ' ')"
echo "Validated $article_count generated article assets."
