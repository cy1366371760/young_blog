+++
title = "AtCoder ABC086A：乘积"
date = "2026-09-08"
category = "ocaml-learning"
subcategory = "ocaml-in-atcoder"
translation_key = "atcoder-abc086a-product"
tags = ["ocaml", "atcoder", "beginner", "arithmetic"]
summary = "判断两个整数的乘积是偶数还是奇数，并说明 OCaml 中的结构相等。"
draft = false
comments = false
+++

# 问题

- 平台：AtCoder Beginners Selection
- 题目：ABC086A - Product
- 链接：[AtCoder 题目说明](https://atcoder.jp/contests/abs/tasks/abc086_a?lang=en)

给定两个正整数，判断它们的乘积是偶数还是奇数。

## 思路

一个乘积是偶数，当且仅当它除以 `2` 的余数为零。先计算乘积，可以让判断条件直接而易读。

## 算法

- 读取 `a` 和 `b`。
- 计算 `a * b`。
- 如果乘积能被 `2` 整除，输出 `Even`；否则输出 `Odd`。

时间复杂度和额外空间复杂度都是常数。

## 反思

在 OCaml 中判断值是否相等，应使用单个等号：`=`。运算符 `==` 判断物理相等，也就是两个值是否由同一个对象表示。对于整数这样的立即值，它恰好可能与 `=` 得到相同结果，但不应把它作为比较值时的默认选择。

## OCaml 实现

```ocaml
open Core

let () =
  Scanf.scanf "%d %d" (fun a b ->
    let product = a * b in
    if product mod 2 = 0 then printf "Even\n"
    else printf "Odd\n")
```
