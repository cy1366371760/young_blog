#!/usr/bin/env bash
set -euo pipefail

dune build @site

rm -rf dist
mkdir -p dist

# Keep deploy output independent from Dune metadata.
cp _build/default/public/index.html dist/
cp _build/default/public/styles.css dist/
cp _build/default/public/app.js dist/
