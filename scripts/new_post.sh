#!/usr/bin/env bash
set -euo pipefail

content_area="${1:-}"
locale="${2:-}"
category="${3:-}"
subcategory="${4:-}"
slug="${5:-}"

if [[ -z "$content_area" || -z "$locale" || -z "$category" || -z "$subcategory" || -z "$slug" ]]; then
  echo "usage: scripts/new_post.sh <tech|essays> <en|zh-hans> <category> <subcategory> <slug>" >&2
  echo "example: scripts/new_post.sh tech en ocaml-learning ocaml-in-atcoder atcoder-abc086a-product" >&2
  exit 2
fi

if [[ "$locale" == "zh-hant" ]]; then
  echo "zh-hant is generated from the zh-hans source; create or edit the zh-hans post instead" >&2
  exit 2
fi

date="$(date +%F)"
path="content/$content_area/$locale/$category/$subcategory/$date-$slug.md"

mkdir -p "$(dirname "$path")"

if [[ -e "$path" ]]; then
  echo "$path already exists" >&2
  exit 1
fi

cat >"$path" <<EOF
+++
title = "TODO"
date = "$date"
category = "$category"
subcategory = "$subcategory"
translation_key = "$slug"
tags = []
draft = true
comments = false
+++

Write here.
EOF

echo "$path"
