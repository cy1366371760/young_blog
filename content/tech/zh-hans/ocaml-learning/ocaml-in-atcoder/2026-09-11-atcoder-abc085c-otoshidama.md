+++
title = "AtCoder ABC085C：压岁钱"
date = "2026-09-11"
category = "ocaml-learning"
subcategory = "ocaml-in-atcoder"
translation_key = "atcoder-abc085c-otoshidama"
tags = ["ocaml", "atcoder", "beginner", "math", "sequence"]
summary = "枚举一万日元纸币的数量，再直接求解剩余两种纸币的方程。"
draft = false
comments = false
+++

# 问题

- 平台：AtCoder Beginners Selection
- 题目：ABC085C - Otoshidama
- 链接：[AtCoder 题目说明](https://atcoder.jp/contests/abs/tasks/abc085_c?lang=en)

给定总价值为 `Y` 日元的 `N` 张纸币，求一种由 `10000`、`5000` 和 `1000` 日元纸币组成的可能数量。如果不存在这样的组合，输出 `-1 -1 -1`。

## 思路

先选定 `10000` 日元纸币的数量。做出这个选择后，只剩下 `5000` 与 `1000` 日元纸币的数量和值。这两个未知数由两个方程决定，因此不需要第二层嵌套循环。

设有 `a` 张 `5000` 日元纸币和 `b` 张 `1000` 日元纸币，剩余纸币数量为 `num`，剩余金额为 `total`：

```text
5000a + 1000b = total
a + b = num
```

用第一个方程减去 `1000 * (a + b)`，得到：

```text
4000a = total - 1000 * num
```

右侧必须非负并且能被 `4000` 整除。随后，`b` 就是 `num - a`。

## 算法

- 从 `0` 到 `N` 枚举 `n10000`。
- 剩余纸币数量为 `N - n10000`，并从 `Y` 中减去已经选定纸币的价值。
- 求解剩余的二元方程，并验证两个数量都非负。
- 返回第一个有效三元组；如果不存在，则返回 `-1 -1 -1`。

时间复杂度是 `O(N)`。`better.ml` 实现使用 `Sequence`，因此会惰性地产生候选值，而不是分配一个包含 `N + 1` 个值的列表。

## 反思

`Sequence.range` 很适合这里，因为候选值会逐个消费，而且找到第一个答案后搜索就会停止。相比之下，`List.init` 会在 `List.find_map` 开始搜索之前构建完整的候选列表。两者的渐近时间复杂度相同，但序列版本使用的中间空间更少。

`solve_remaining ~num ~total` 中的标签参数，让含义不同的两个整数输入更不容易被意外交换。调用处读起来也更像它所表达的方程。

`find_map` 不只是找出匹配的输入：它会返回映射函数产生的第一个非 `None` 值。因此，可以自然地把求出的 `n10000`、`n5000` 和 `n1000` 数量作为最终三元组保存在一起。

## 原始 OCaml 实现

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

## 改进后的 OCaml 实现

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
