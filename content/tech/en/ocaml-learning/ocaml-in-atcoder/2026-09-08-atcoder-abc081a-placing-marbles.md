+++
title = "AtCoder ABC081A: Placing Marbles"
date = "2026-09-08"
category = "ocaml-learning"
subcategory = "ocaml-in-atcoder"
translation_key = "atcoder-abc081a-placing-marbles"
tags = ["ocaml", "atcoder", "beginner", "strings"]
summary = "Count the ones in a three-character binary string, while practising formatted input and a unit entry point."
draft = false
comments = false
+++

# Problem

- Platform: AtCoder Beginners Selection
- Problem: ABC081A - Placing Marbles
- Link: [AtCoder problem statement](https://atcoder.jp/contests/abs/tasks/abc081_a?lang=en)

The input is a string of three `0` or `1` characters. Count how many positions
contain `1`.

## Idea

The input is already a string, so scan its characters and count the characters
equal to `'1'`. `String.count` expresses the task directly.

## Algorithm

- Read the binary string.
- Count characters equal to `'1'`.
- Print the count.

The running time is `O(|s|)` and the extra space is constant. Here `|s| = 3`.

## Reflection

`Scanf.scanf` is needed because it is the formatted-input parser: it receives a
format string and a continuation that consumes the parsed values. In contrast,
after opening `Core`, `printf` is directly available for formatted output.

The pattern in `let () = ...` requires the expression on its right-hand side to
produce `unit`. This makes it a natural top-level entry point for a program
whose purpose is its input/output effects.

## OCaml Implementation

```ocaml
open Core

let () =
  Scanf.scanf "%s" (fun s ->
    printf "%d\n" (String.count s ~f:(Char.equal '1'))
  )
```
