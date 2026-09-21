+++
title = "AtCoder ABC081A：放置弹珠"
date = "2026-09-08"
category = "ocaml-learning"
subcategory = "ocaml-in-atcoder"
translation_key = "atcoder-abc081a-placing-marbles"
tags = ["ocaml", "atcoder", "beginner", "strings"]
summary = "统计一个三字符二进制字符串中 1 的数量，同时练习格式化输入和 unit 入口。"
draft = false
comments = false
+++

# 问题

- 平台：AtCoder Beginners Selection
- 题目：ABC081A - Placing Marbles
- 链接：[AtCoder 题目说明](https://atcoder.jp/contests/abs/tasks/abc081_a?lang=en)

输入是一个由三个 `0` 或 `1` 组成的字符串。统计其中有多少个位置是 `1`。

## 思路

输入本身已经是字符串，因此只需扫描其中的字符，并统计等于 `'1'` 的字符数量。`String.count` 可以直接表达这个任务。

## 算法

- 读取二进制字符串。
- 统计等于 `'1'` 的字符。
- 输出计数。

时间复杂度是 `O(|s|)`，额外空间为常数。这里 `|s| = 3`。

## 反思

这里需要使用 `Scanf.scanf`，因为它是格式化输入解析器：它接收一个格式字符串，以及一个消费解析结果的延续函数。相比之下，在打开 `Core` 后，可以直接使用 `printf` 进行格式化输出。

`let () = ...` 中的模式要求右侧表达式产生 `unit`。因此，对于主要作用是执行输入输出效果的程序，它很适合作为顶层入口。

## OCaml 实现

```ocaml
open Core

let () =
  Scanf.scanf "%s" (fun s ->
    printf "%d\n" (String.count s ~f:(Char.equal '1'))
  )
```
