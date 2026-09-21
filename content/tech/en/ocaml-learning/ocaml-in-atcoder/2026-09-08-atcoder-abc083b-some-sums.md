+++
title = "AtCoder ABC083B: Some Sums"
date = "2026-09-08"
category = "ocaml-learning"
subcategory = "ocaml-in-atcoder"
translation_key = "atcoder-abc083b-some-sums"
tags = ["ocaml", "atcoder", "beginner", "fold", "recursion"]
summary = "Sum numbers whose decimal digit sums lie in a given range, using a string-based digit scan and a functional fold."
draft = false
comments = false
+++

# Problem

- Platform: AtCoder Beginners Selection
- Problem: ABC083B - Some Sums
- Link: [AtCoder problem statement](https://atcoder.jp/contests/abs/tasks/abc083_b?lang=en)

For every integer from `1` to `N`, include it in the answer when the sum of its
decimal digits is between `A` and `B`, inclusive.

## Idea

The constraint on `N` is small enough to inspect every candidate. Convert each
candidate to a string, add its digit characters, and fold the accepted
candidates into the final sum.

## Algorithm

- Parse `N`, `A`, and `B` from the first input line.
- For every integer in `1 .. N`, compute its decimal digit sum.
- Add the integer to the accumulator exactly when that sum is in `[A, B]`.

The running time is `O(N log N)`, due to processing the decimal digits of each
candidate. `List.range` materializes the candidates, so this implementation
uses `O(N)` extra space.

## Reflection

Converting a number to a string and enumerating its characters is clear and
fully sufficient for these constraints. An arithmetic digit-sum function that
repeatedly takes the final digit would avoid the temporary string allocation.

Matching a split input line is explicit but can feel verbose. For more general
contest input, it is worth building a small whitespace-token reader. `Scanf`
can also be convenient for simple fixed formats.

`List.fold (List.range 1 (n + 1))` avoids a mutable `for`-loop accumulator, but
the intermediate list costs space. That trade-off is harmless here, yet it is a
useful habit to notice.

`function` is shorthand for `fun x -> match x with ...`: the `x` is a fresh
function parameter, not an existing variable from the surrounding scope.

## OCaml Implementation

```ocaml
open Core

let count_sum_digits x = x
 |> Int.to_string
 |> String.fold ~init:0 ~f:(fun acc c -> acc + Char.to_int c - Char.to_int '0')

let () =
  let n, a, b = In_channel.input_line_exn In_channel.stdin
  |> String.split ~on:' '
  |> function
  | [n; a; b] -> Int.of_string n, Int.of_string a, Int.of_string b
  | _ -> failwith "gg"
  in
  let ans = List.fold (List.range 1 (n+1)) ~init:0 ~f:(fun acc x ->
    let digit_sum = count_sum_digits x in
    if a <= digit_sum && digit_sum <= b then acc + x
    else acc) in
  printf "%d\n" ans
```
