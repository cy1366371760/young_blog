+++
title = "AtCoder ABC085C: Otoshidama"
date = "2026-09-11"
category = "ocaml-learning"
subcategory = "ocaml-in-atcoder"
translation_key = "atcoder-abc085c-otoshidama"
tags = ["ocaml", "atcoder", "beginner", "math", "sequence"]
summary = "Enumerate the number of 10000-yen bills, then solve the remaining two-bill equation directly."
draft = false
comments = false
+++

# Problem

- Platform: AtCoder Beginners Selection
- Problem: ABC085C - Otoshidama
- Link: [AtCoder problem statement](https://atcoder.jp/contests/abs/tasks/abc085_c?lang=en)

Given `N` bills worth a total of `Y` yen, find a possible number of `10000`-,
`5000`-, and `1000`-yen bills. Print `-1 -1 -1` when no such combination
exists.

## Idea

Choose the number of `10000`-yen bills first. After that choice, only the
number and value of `5000`- and `1000`-yen bills remain. Those two unknowns
are determined by two equations, so there is no need for a second nested loop.

For `a` `5000`-yen bills and `b` `1000`-yen bills, with `num` bills and
`total` yen remaining:

```text
5000a + 1000b = total
a + b = num
```

Subtracting `1000 * (a + b)` from the first equation gives:

```text
4000a = total - 1000 * num
```

The right-hand side must be non-negative and divisible by `4000`. Then `b` is
simply `num - a`.

## Algorithm

- Enumerate `n10000` from `0` through `N`.
- Let the remaining bill count be `N - n10000` and subtract the chosen bills'
  value from `Y`.
- Solve the two-equation remainder and validate that both counts are
  non-negative.
- Return the first valid triple, or `-1 -1 -1` if none exists.

The running time is `O(N)`. The `better.ml` implementation uses `Sequence`, so
it produces candidates lazily rather than allocating a list of `N + 1` values.

## Reflection

`Sequence.range` is a good fit here because candidates are consumed one at a
time and the search stops at the first answer. In contrast, `List.init` builds
the entire candidate list before `List.find_map` begins searching. The
asymptotic running time is unchanged, but the sequence version uses less
intermediate space.

The labeled arguments in `solve_remaining ~num ~total` make two integer inputs
with different meanings harder to swap accidentally. They also make the call
site read like the equation it represents.

`find_map` does more than identify a matching input: it returns the first
non-`None` value produced by the mapping function. That makes it natural to
keep the solved `n10000`, `n5000`, and `n1000` counts together as the final
triple.

## Original OCaml Implementation

```ocaml
open Core

(* 5000a + 1000b = tot, a + b = num *)
let solve num tot =
  let a_4000 = tot - num * 1000 in
  if a_4000 < 0 || a_4000 mod 4000 <> 0 then None
  else let a = a_4000 / 4000 in
  let b = num - a in
  if a < 0 || b < 0 then None
  else Some(a, b)

let () =
  let n,y = Scanf.scanf " %d %d" (fun x y -> (x, y)) in
  List.init (n + 1) ~f:(fun x -> x)
  |> List.find_map ~f:(fun x -> solve (n - x) (y - 10000 * x))
  |> function
  | None -> printf "-1 -1 -1\n"
  | Some(a,b) -> printf "%d %d %d\n" (n-a-b) a b
```

## Improved OCaml Implementation

```ocaml
open Core

let solve_remaining ~num ~total =
  let excess = total - (num * 1000) in
  if excess < 0 || excess mod 4000 <> 0 then
    None
  else
    let n5000 = excess / 4000 in
    let n1000 = num - n5000 in
    if n5000 <= num then
      Some (n5000, n1000)
    else
      None

let () =
  let n, y = Scanf.scanf " %d %d" (fun n y -> n, y) in

  Sequence.range 0 (n + 1)
  |> Sequence.find_map ~f:(fun n10000 ->
    solve_remaining
      ~num:(n - n10000)
      ~total:(y - (10000 * n10000))
    |> Option.map ~f:(fun (n5000, n1000) ->
      n10000, n5000, n1000))
  |> function
  | Some (a, b, c) ->
      printf "%d %d %d\n" a b c
  | None ->
      printf "-1 -1 -1\n"
```
