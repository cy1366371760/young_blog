+++
title = "AtCoder ABC086A: Product"
date = "2026-09-08"
section = "tech"
category = "ocaml-learning"
subcategory = "ocaml-in-atcoder"
tags = ["ocaml", "atcoder", "beginner", "arithmetic"]
summary = "Determine whether the product of two integers is even or odd, with a note on structural equality in OCaml."
draft = false
comments = false
+++

# Problem

- Platform: AtCoder Beginners Selection
- Problem: ABC086A - Product
- Link: [AtCoder problem statement](https://atcoder.jp/contests/abs/tasks/abc086_a?lang=en)

Given two positive integers, determine whether their product is even or odd.

## Idea

A product is even exactly when its remainder modulo `2` is zero. Computing the
product first makes the condition direct and readable.

## Algorithm

- Read `a` and `b`.
- Compute `a * b`.
- Print `Even` when the product is divisible by `2`; otherwise print `Odd`.

The running time and extra space are both constant.

## Reflection

For value equality in OCaml, use a single equals sign: `=`. The operator `==`
tests physical equality, meaning whether two values are represented by the same
object. It happens to agree with `=` for immediate values such as integers, but
it is the wrong default for comparing values.

## OCaml Implementation

```ocaml
open Core

let () =
  Scanf.scanf "%d %d" (fun a b ->
    let product = a * b in
    if product mod 2 = 0 then printf "Even\n"
    else printf "Odd\n")
```
