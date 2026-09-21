+++
title = "AtCoder ABC081B：只做移位"
date = "2026-09-08"
category = "ocaml-learning"
subcategory = "ocaml-in-atcoder"
translation_key = "atcoder-abc081b-shift-only"
tags = ["ocaml", "atcoder", "beginner", "recursion", "bit-operations"]
summary = "递归统计每个数字包含多少个因子 2，再取最小值，得到所有数字能同时除以 2 的次数。"
draft = false
comments = false
+++

# 问题

- 平台：AtCoder Beginners Selection
- 题目：ABC081B - Shift only
- 链接：[AtCoder 题目说明](https://atcoder.jp/contests/abs/tasks/abc081_b?lang=en)

给定写在黑板上的若干正整数。只要所有整数都是偶数，就反复将每个整数除以二。求最多可以执行多少次操作。

## 思路

对于每个整数，统计它能连续被二整除多少次。整个黑板能执行的次数，取决于其中可除次数最少的元素，因此答案就是这些计数的最小值。

## 算法

- 递归地将一个数除以 `2`，直到它变为奇数，并统计除法次数。
- 对每个输入数字应用这个函数。
- 输出最小计数。

对于 `N` 个数字，时间复杂度是 `O(N log M)`，其中 `M` 是最大的输入值。列表变换使用 `O(N)` 的额外空间。

## 反思

函数应用的优先级高于除法，因此 `count_trailing_zeros (x / 2)` 中的括号不可省略。没有括号时，表达式将表示 `(count_trailing_zeros x) / 2`。

我最初选择递归，是为了练习这一思路。如果所选的 OCaml 库提供尾随零位操作，也可以用它完成每个数字的计算；本项目使用的 `Core.Int` API 并未提供 `Int.ctz`。

带标签的参数必须连同标签一起提供。例如，`List.map` 使用 `~f:` 传入函数参数，而没有标签的参数仍按位置传递。

## OCaml 实现

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
