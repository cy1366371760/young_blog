+++
title = "AtCoder PracticeA: Welcome to AtCoder"
date = "2026-09-08"
category = "ocaml-learning"
subcategory = "ocaml-in-atcoder"
tags = ["ocaml", "atcoder", "beginner", "input-output"]
summary = "A first OCaml submission: parse three integers and a string, then print their sum with the string."
draft = false
comments = false
+++

# Problem

- Platform: AtCoder Beginners Selection
- Problem: PracticeA - Welcome to AtCoder
- Link: [AtCoder problem statement](https://atcoder.jp/contests/abs/tasks/practice_1?lang=en)

Given three integers and one string, print the sum of the integers followed by
the string.

## Idea

This is an input/output exercise. The only small wrinkle is that the input is
split across three lines, while `Scanf.scanf` can consume whitespace between
tokens regardless of the line boundaries.

## Algorithm

- Read `a`, `b`, `c`, and `s`.
- Compute `a + b + c`.
- Print the sum and `s`, separated by one space.

The running time and extra space are both constant.

## Reflection

This was my first example. It was a useful way to see the full contest loop in
OCaml: read standard input, compute a result, and print it in the required
format.

## OCaml Implementation

```ocaml
open Core

let () =
  Scanf.scanf "%d %d %d %s" (fun a b c s ->
    let sum = a + b + c in
    printf "%d %s\n" sum s)
```
