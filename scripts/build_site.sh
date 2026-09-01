#!/usr/bin/env bash
set -euo pipefail

node scripts/generate_posts.mjs public/posts.js
dune build @site

rm -rf dist
mkdir -p dist

# Keep deploy output independent from Dune metadata.
cp _build/default/public/index.html dist/
cp _build/default/public/posts.js dist/
cp _build/default/public/styles.css dist/
cp _build/default/public/app.js dist/
cp public/_redirects dist/
cp -R public/articles dist/
