+++
title = "AtCoder PracticeA：欢迎来到 AtCoder"
date = "2026-09-08"
category = "ocaml-learning"
subcategory = "ocaml-in-atcoder"
translation_key = "atcoder-practicea-welcome"
tags = ["ocaml", "atcoder", "beginner", "input-output"]
summary = "第一次提交 OCaml：解析三个整数和一个字符串，然后输出整数之和与字符串。"
draft = false
comments = false
+++

# 问题

- 平台：AtCoder Beginners Selection
- 题目：PracticeA - Welcome to AtCoder
- 链接：[AtCoder 题目说明](https://atcoder.jp/contests/abs/tasks/practice_1?lang=en)

给定三个整数和一个字符串，输出整数之和，后面再输出该字符串。

## 思路

这是一道输入输出练习。唯一需要稍加注意的是，输入分布在三行中，而 `Scanf.scanf` 可以跨越行边界读取由空白分隔的标记。

## 算法

- 读取 `a`、`b`、`c` 和 `s`。
- 计算 `a + b + c`。
- 输出总和与 `s`，中间以一个空格分隔。

时间复杂度和额外空间复杂度都是常数。

## 反思

这是我的第一个示例。它适合用来了解 OCaml 竞赛程序的完整流程：读取标准输入、计算结果，再按要求的格式输出。

## OCaml 实现

```ocaml
open Core

let () =
  Scanf.scanf "%d %d %d %s" (fun a b c s ->
    let sum = a + b + c in
    printf "%d %s\n" sum s)
```
