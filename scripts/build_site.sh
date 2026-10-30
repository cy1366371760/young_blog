#!/usr/bin/env bash
set -euo pipefail

node scripts/generate_posts.mjs public/posts.js
node scripts/build_reader.mjs
dune build --profile release @site

rm -rf dist
mkdir -p dist

# Keep deploy output independent from Dune metadata.
cp _build/default/public/index.html dist/
cp _build/default/public/posts.js dist/
cp _build/default/public/styles.css dist/
cp _build/default/public/app.js dist/
cp public/_redirects dist/
cp public/reader.js public/content-index.json dist/
cp -R public/articles dist/
