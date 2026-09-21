+++
title = "AtCoder ABC085B: Kagami Mochi"
date = "2026-09-10"
category = "ocaml-learning"
subcategory = "ocaml-in-atcoder"
tags = ["ocaml", "atcoder", "beginner", "sorting", "recursion"]
summary = "Sort the mochi diameters and count distinct values to find the largest possible kagami mochi stack."
draft = false
comments = false
+++

# Problem

- Platform: AtCoder Beginners Selection
- Problem: ABC085B - Kagami Mochi
- Link: [AtCoder problem statement](https://atcoder.jp/contests/abs/tasks/abc085_b?lang=en)

Given `N` round mochi with integer diameters, build the tallest stack in which
every mochi above another has a strictly smaller diameter. Find the maximum
number of layers.

## Idea

Every distinct diameter can appear once in a valid stack, while duplicate
diameters cannot both be used. The answer is therefore the number of distinct
diameters.

This solution sorts the list with a recursive quicksort, then scans the sorted
result and counts changes between adjacent values.

## Algorithm

- Read the `N` diameters.
- Sort them with quicksort.
- Traverse the sorted list and count each new value once.
- Print that count.

With random pivots, the quicksort has expected `O(N log N)` time. The counting
pass is `O(N)`, and the list-based implementation uses additional memory for
the sorted and partitioned lists.

## Reflection

For integers, `Int.compare` and `Int.equal` make the intended type-specific
comparison explicit. Polymorphic comparison operators such as `<` and `=` are
also correct for integers, but the `Core` helpers are a clearer habit. The
current `count_unique` implementation still uses `=`; using `Int.equal` there
would make the style consistent.

The quicksort can partition more efficiently by matching `pivot :: rest` and
using one `List.fold` to produce the less-than, equal-to, and greater-than
lists. This replaces the current three `List.filter` passes. It is not an
alternative to the `List` library: pattern matching exposes the head and tail,
while `List.fold` performs the single traversal.

In the distinct-counting recursion, an alias pattern such as
`x :: ((y :: _) as tail)` can reuse `tail` instead of reconstructing `y :: rem`
after each comparison. With the explicit integer comparison, the compact shape
is `if Int.equal x y then count_unique tail else 1 + count_unique tail`.

For this problem, whose input size is at most `100`, the current implementation
is already comfortably fast. `List.dedup_and_sort ~compare:Int.compare` would
be the most direct `Core` library solution once the underlying operations are
familiar.

## OCaml Implementation

```ocaml
open Core

let rec qsort a =
  let n = List.length a in
  if n <= 1 then a else
    let pos = Random.int n in
    let bas = List.nth_exn a pos in
    qsort (List.filter a ~f:(fun x -> Int.compare x bas < 0)) @
    (List.filter a ~f:(fun x -> Int.equal x bas)) @
    qsort (List.filter a ~f:(fun x -> Int.compare x bas > 0))

let () =
  let n = Scanf.scanf " %d" (fun x -> x) in
  let d = List.init n ~f:(fun _ -> Scanf.scanf " %d" (fun x -> x)) in
  let sorted_d = qsort d in
  let rec count_unique = function
  | [] -> 0
  | [_] -> 1
  | x :: y :: rem -> if x = y then count_unique (y :: rem) else 1 + count_unique (y :: rem) in
  let res = count_unique sorted_d in
  printf "%d\n" res
```
