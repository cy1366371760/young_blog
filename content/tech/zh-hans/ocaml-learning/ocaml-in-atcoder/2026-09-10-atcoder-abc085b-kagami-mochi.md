+++
title = "AtCoder ABC085B：镜饼"
date = "2026-09-10"
category = "ocaml-learning"
subcategory = "ocaml-in-atcoder"
translation_key = "atcoder-abc085b-kagami-mochi"
tags = ["ocaml", "atcoder", "beginner", "sorting", "recursion"]
summary = "对年糕直径排序并统计不同的值，从而求出镜饼最多可以堆多少层。"
draft = false
comments = false
+++

# 问题

- 平台：AtCoder Beginners Selection
- 题目：ABC085B - Kagami Mochi
- 链接：[AtCoder 题目说明](https://atcoder.jp/contests/abs/tasks/abc085_b?lang=en)

给定 `N` 个直径为整数的圆形年糕。要求堆出尽可能高的一叠，并且每个年糕的直径都必须严格小于它下面的年糕。求最多可以堆多少层。

## 思路

每一种不同的直径都可以在合法堆叠中出现一次，而相同直径的年糕不能同时使用。因此，答案就是不同直径的数量。

这个解法先使用递归快速排序对列表排序，然后扫描排序结果，统计相邻值发生变化的次数。

## 算法

- 读取 `N` 个直径。
- 使用快速排序对它们排序。
- 遍历排序后的列表，每个新值只计数一次。
- 输出计数。

使用随机枢轴时，快速排序的期望时间复杂度是 `O(N log N)`。计数过程是 `O(N)`，基于列表的实现还会为排序和分区后的列表使用额外内存。

## 反思

对于整数，`Int.compare` 和 `Int.equal` 可以明确表达预期的类型专用比较。像 `<` 和 `=` 这样的多态比较运算符对整数也正确，但养成使用 `Core` 辅助函数的习惯会更清晰。当前的 `count_unique` 实现仍使用 `=`；在那里改用 `Int.equal` 会让风格保持一致。

快速排序可以通过匹配 `pivot :: rest`，再使用一次 `List.fold` 同时生成小于、等于和大于枢轴的列表，从而更高效地完成分区。这可以替代当前的三次 `List.filter` 遍历。它并不是 `List` 库的替代方案：模式匹配负责暴露头部与尾部，`List.fold` 负责完成单次遍历。

在不同值计数的递归中，`x :: ((y :: _) as tail)` 这样的别名模式可以直接复用 `tail`，而不用在每次比较后重新构造 `y :: rem`。配合显式整数比较，可以写成紧凑的 `if Int.equal x y then count_unique tail else 1 + count_unique tail`。

这道题的输入规模最多为 `100`，因此当前实现已经足够快。熟悉底层操作后，`List.dedup_and_sort ~compare:Int.compare` 会是最直接的 `Core` 库解法。

## OCaml 实现

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
