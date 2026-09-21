+++
title = "AtCoder ABC083B：若干个数之和"
date = "2026-09-08"
category = "ocaml-learning"
subcategory = "ocaml-in-atcoder"
translation_key = "atcoder-abc083b-some-sums"
tags = ["ocaml", "atcoder", "beginner", "fold", "recursion"]
summary = "使用字符串扫描十进制数字，并通过函数式折叠，求各位数字之和落在指定范围内的整数总和。"
draft = false
comments = false
+++

# 问题

- 平台：AtCoder Beginners Selection
- 题目：ABC083B - Some Sums
- 链接：[AtCoder 题目说明](https://atcoder.jp/contests/abs/tasks/abc083_b?lang=en)

对于从 `1` 到 `N` 的每个整数，如果它的十进制各位数字之和位于 `A` 与 `B` 之间（包含两端），就把它加入答案。

## 思路

`N` 的约束足够小，可以检查每个候选数。把候选数转换成字符串，将其中的数字字符相加，再把满足条件的候选数折叠到最终总和中。

## 算法

- 从第一行输入解析 `N`、`A` 和 `B`。
- 对 `1 .. N` 中的每个整数，计算它的十进制各位数字之和。
- 仅当这个和位于 `[A, B]` 时，才把该整数加入累加器。

由于需要处理每个候选数的十进制数字，时间复杂度是 `O(N log N)`。`List.range` 会把候选数具体化，因此这个实现使用 `O(N)` 的额外空间。

## 反思

把数字转换为字符串并遍历字符，表达清晰，也完全足以应对这里的约束。另一种做法是使用算术方式反复取末位数字，这样可以避免临时字符串分配。

对拆分后的输入行进行模式匹配很明确，但可能显得冗长。面对更通用的竞赛输入，值得编写一个小型的空白标记读取器。对于简单的固定格式，`Scanf` 也很方便。

`List.fold (List.range 1 (n + 1))` 避免了带可变累加器的 `for` 循环，但中间列表会占用空间。这里的代价无关紧要，不过注意到这种权衡是一个好习惯。

`function` 是 `fun x -> match x with ...` 的简写：其中的 `x` 是一个新的函数参数，并不是外围作用域中的已有变量。

## OCaml 实现

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
