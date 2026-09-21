+++
title = "AtCoder ABC081B: Shift only"
date = "2026-09-08"
category = "ocaml-learning"
subcategory = "ocaml-in-atcoder"
translation_key = "atcoder-abc081b-shift-only"
tags = ["ocaml", "atcoder", "beginner", "recursion", "bit-operations"]
summary = "Count each number's factors of two recursively and take the minimum to find the number of simultaneous divisions."
draft = false
comments = false
+++

# Problem

- Platform: AtCoder Beginners Selection
- Problem: ABC081B - Shift only
- Link: [AtCoder problem statement](https://atcoder.jp/contests/abs/tasks/abc081_b?lang=en)

Given positive integers on a board, repeatedly divide every integer by two while
all of them are even. Find the maximum number of operations.

## Idea

For each integer, count how many times it is divisible by two. The whole board
can be divided only as many times as the least divisible-by-two element allows,
so the answer is the minimum of those counts.

## Algorithm

- Recursively divide one number by `2` until it becomes odd, counting divisions.
- Apply that function to every input number.
- Print the minimum count.

For `N` numbers, the running time is `O(N log M)`, where `M` is the largest
input value. The list transformations use `O(N)` extra space.

## Reflection

Function application has higher precedence than division, so the parentheses in
`count_trailing_zeros (x / 2)` are necessary. Without them, the expression
would mean `(count_trailing_zeros x) / 2`.

I first chose recursion to practise the idea. A trailing-zero bit operation can
also solve the per-number step when the selected OCaml library provides one;
the `Core.Int` API used in this project does not expose `Int.ctz`.

Labeled parameters must be supplied with their labels. For example, `List.map`
uses `~f:` for its function argument, while unlabeled arguments remain
positional.

## OCaml Implementation

```ocaml
open Core

let rec count_trailing_zeros x =
  if x mod 2 = 0 then 1 + count_trailing_zeros (x / 2)  else 0

let () =
  let _n = In_channel.input_line_exn In_channel.stdin |> Int.of_string in
  let ans = In_channel.input_line_exn In_channel.stdin
  |> String.split ~on:' '
  |> List.map ~f:int_of_string
  |> List.map ~f:count_trailing_zeros
  |> List.fold ~init:Int.max_value ~f:(Int.min) in
  printf "%d" ans
```
