#!/usr/bin/env bash
set -euo pipefail

section="${1:-}"
category="${2:-}"
subcategory="${3:-}"
slug="${4:-}"

if [[ -z "$section" || -z "$category" || -z "$subcategory" || -z "$slug" ]]; then
  echo "usage: scripts/new_post.sh <tech|zh> <category> <subcategory> <slug>" >&2
  exit 2
fi

date="$(date +%F)"
path="content/$section/$category/$subcategory/$date-$slug.md"

mkdir -p "$(dirname "$path")"

if [[ -e "$path" ]]; then
  echo "$path already exists" >&2
  exit 1
fi

cat >"$path" <<EOF
+++
title = "TODO"
date = "$date"
section = "$section"
category = "$category"
subcategory = "$subcategory"
tags = []
draft = true
comments = false
+++

Write here.
EOF

echo "$path"
