#!/usr/bin/env bash
set -euo pipefail

content_area="${1:-}"
category="${2:-}"
subcategory="${3:-}"
slug="${4:-}"

if [[ -z "$content_area" || -z "$category" || -z "$subcategory" || -z "$slug" ]]; then
  echo "usage: scripts/new_post.sh <tech|essays> <category> <subcategory> <slug>" >&2
  echo "example: scripts/new_post.sh tech ocaml-learning ocaml-in-atcoder atcoder-abc086a-product" >&2
  exit 2
fi

date="$(date +%F)"
english_path="content/$content_area/en/$category/$subcategory/$date-$slug.md"
chinese_path="content/$content_area/zh-hans/$category/$subcategory/$date-$slug.md"

for path in "$english_path" "$chinese_path"; do
  if [[ -e "$path" ]]; then
    echo "$path already exists" >&2
    exit 1
  fi
done

mkdir -p "$(dirname "$english_path")" "$(dirname "$chinese_path")"

write_post () {
  local path="$1"
  local title="$2"
  local body="$3"

  cat >"$path" <<EOF
+++
title = "$title"
date = "$date"
category = "$category"
subcategory = "$subcategory"
translation_key = "$slug"
tags = []
draft = true
comments = false
+++

$body
EOF
}

write_post "$english_path" "TODO: English title" "Write the English version here."
write_post "$chinese_path" "TODO：中文标题" "在这里编写简体中文版本。"

printf '%s\n%s\n' "$english_path" "$chinese_path"
