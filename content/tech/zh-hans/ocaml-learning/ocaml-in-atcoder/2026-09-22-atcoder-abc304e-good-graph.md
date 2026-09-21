+++
title = "AtCoder ABC304E：并查集与禁配连通分量"
date = "2026-09-22"
category = "ocaml-learning"
subcategory = "ocaml-in-atcoder"
translation_key = "atcoder-abc304e-good-graph"
tags = ["ocaml", "atcoder", "dsu", "hash-set", "code-review"]
summary = "把顶点压缩成连通分量，再用规范化的无序对记录不能连接的分量；也借三版实现复盘 OCaml 中的副作用、比较与模块封装。"
draft = false
comments = false
+++

# 问题

- 平台：AtCoder Beginner Contest 304
- 题目：E - Good Graph
- 链接：[AtCoder 题目说明](https://atcoder.jp/contests/abc304/tasks/abc304_e?lang=en)

给定一张无向图，以及若干对不能互相连通的顶点。每次询问独立地向原图加入一条边，判断加入后是否仍满足所有限制。

约束规模达到二十万，不能为每次询问重新遍历图。真正重要的并不是单个顶点，而是原图中已经形成的连通分量。

## 核心思路

先用并查集合并原图的所有边。对于每对禁止连通的顶点，分别找到它们所属分量的根，并把这两个根组成无序对，存入哈希集合。

回答询问时，同样把两个端点映射到分量根并规范化为无序对：如果它出现在禁配集合中，新增边会让某对受限顶点连通，答案是 No；否则答案是 Yes。

无序对必须使用统一表示。例如，总把较小的根放在前面。这样输入方向不会影响查找，也不必分别保存或查询两个方向。

并查集使用路径压缩和按秩合并。包括读入在内，整体时间复杂度是近似线性的 `O((N + M + K + Q) α(N))`，额外空间复杂度是 `O(N + K)`。

# 从第一版中发现的问题

最初的 `old_impl.ml` 已经抓住了并查集方向，但仍保留了不少可以简化或澄清的地方。

首先，Base 的 `List.init` 为了构造最终顺序正确的列表，会按 `n - 1` 到 `0` 的顺序调用 `f`。如果 `f` 内执行 `Scanf.scanf`，每次调用仍会消费下一行，因此生成列表中的值与输入顺序相反。后接 `List.rev` 可以恢复值的顺序，但这种写法依赖不直观的副作用时序；对于竞赛式顺序输入，直接使用 `for` 循环更清楚。

其次，记录表达式中的字段顺序不表示值的方向。`{ u; v }` 和 `{ v; u }` 都只是按字段名保存当前的 u、v；真正交换值需要写成 `{ u = v; v = u }`。不过与其每次查两个方向，更自然的办法是在创建时就规范化无序对。

最后，这一版用普通等号比较整数，也把输入、计算和输出分成多份列表。程序可以工作，但控制流比问题本身更复杂。题目还保证原图本来就是 good graph，因此额外的全局坏状态判断并不是解决询问所必需的。

```ocaml
open Core
module type DSU = sig
  type t
  val create : int -> t
  val find : t -> int -> int
  val union : t -> int -> int -> unit
end
module Dsu : DSU = struct
  type t = int Array.t
  let create n =
    Array.init n ~f:Fn.id
  let rec find t a = 
    if t.(a) = a then a 
    else 
      let fa = find t t.(a) in (
        t.(a) <- fa ;
        fa
      )
  let union t a b = 
    let fa = find t a in
    let fb = find t b in
    if fa = fb then ()
    else t.(fa) <- fb
end

type edge = {
  u : int;
  v : int;
}
[@@deriving compare, sexp]

let () = 
  let n, m = Scanf.scanf " %d %d" (fun n m -> n, m) in
  let edges = List.init m ~f:(fun _ -> Scanf.scanf " %d %d" (
    fun u v -> {u; v}
  )) |> List.rev
  in 
  let dsu = Dsu.create (n+1) in 
  List.iter edges ~f:(fun {u; v} ->
      Dsu.union dsu u v
    );
  let k = Scanf.scanf " %d" (fun k -> k) in
  let module ConditionSet = Set.Make (struct
    type t = edge
    [@@deriving compare, sexp]
  end
  ) in
  let conditions =
    List.init k ~f:(fun _ ->
      Scanf.scanf " %d %d" (fun u v -> { u = Dsu.find dsu u; v = Dsu.find dsu v }))
    |> List.rev
  in
  let always_bad = List.exists conditions ~f:(fun {u; v} -> u = v) in
  let condition_set =
    ConditionSet.of_list conditions
  in
  let q = Scanf.scanf " %d" (fun q -> q) in
  let qrys =
    List.init q ~f:(fun _ ->
      Scanf.scanf " %d %d" (fun u v -> {u; v}))
    |> List.rev
  in
  let ans = List.map qrys ~f:(fun {u; v} ->
      if always_bad then "No"
      else
        let u = Dsu.find dsu u in
        let v = Dsu.find dsu v in
        if Set.mem condition_set {u; v} ||
          Set.mem condition_set {u = v; v = u}
        then "No" else "Yes"
    ) in
  List.iter ans ~f:(fun s -> print_endline s)
```

# 手工改进：让数据结构表达问题

`main.ml` 做了几项关键调整：并查集加入按秩合并；输入和输出改成 `for` 循环；禁配关系改用 `Hash_set`；`OrderPair.create` 在入口处统一两个根的顺序。

`[@@deriving compare, sexp, hash]` 会为自定义类型生成容器所需的比较、序列化和哈希函数。这里不必手写容易出错的样板代码，也能直接把模块交给 Core 的集合接口。

整数比较也改为 `Ordering.of_int (Int.compare ...)` 后匹配 Less、Equal 和 Greater，避免依赖多态比较，并让三个分支的意图更明确。

```ocaml
open Core

let read_int () = Scanf.scanf " %d" (fun x -> x)
let read_pair_int() = Scanf.scanf " %d %d" (fun x y -> (x, y))

module type DSU = sig
  type t
  val create : int -> t
  val find : t -> int -> int
  val union : t -> int -> int -> unit
end
module Dsu : DSU = struct
  type t = {
    fa   : int Array.t;
    height : int Array.t; 
  }
  let create n =
    {
      fa = Array.init n ~f:Fn.id;
      height = Array.init n ~f:(Fn.const 1);
    }
  let rec find t a = 
    if Int.equal t.fa.(a) a then a 
    else 
      let root = find t t.fa.(a) in (
        t.fa.(a) <- root;
        root
      )
  let union t a b = 
    let root_a = find t a in
    let root_b = find t b in
    if Int.equal root_a root_b then ()
    else 
      let ht_a = t.height.(root_a) in
      let ht_b = t.height.(root_b) in
      match Ordering.of_int (Int.compare ht_a ht_b ) with
      | Less -> (t.fa.(root_a) <- root_b)
      | Greater -> (t.fa.(root_b) <- root_a)
      | Equal -> (t.fa.(root_b) <- root_a; t.height.(root_a) <- ht_a + 1)
end

module OrderPair = struct
  type t = {
    lo : int;
    hi : int;
  }
  [@@deriving compare, sexp, hash]
  let create a b =
    match Ordering.of_int (Int.compare a b) with
    | Less | Equal -> {lo = a; hi = b}
    | Greater -> {lo = b; hi = a}
end

let () = 
  let n, m = read_pair_int() in
  let dsu = Dsu.create (n+1) in 
  for _ = 1 to m do 
    let (a, b) = read_pair_int() in
    Dsu.union dsu a b
  done;
  let k = read_int() in
  let ban_set = Hash_set.create ~size:k (module OrderPair) in
  for _ = 1 to k do
    let (a, b) = read_pair_int() in
    let rt_a = Dsu.find dsu a in
    let rt_b = Dsu.find dsu b in 
    Hash_set.add ban_set (OrderPair.create rt_a rt_b)
  done;
  let q = read_int() in
  for _ = 1 to q do
    let (u, v) = read_pair_int() in
    let u = Dsu.find dsu u in
    let v = Dsu.find dsu v in
    if Hash_set.mem ban_set (OrderPair.create u v)
    then print_endline "No" else print_endline "Yes"
  done
```

# 最终整理：语义命名与封装

`gpt_optimize.ml` 没有改变算法，而是让实现更接近它表达的模型。

- parent 和 rank 比 fa 和 height 更直接；Component_pair 和 forbidden 也比泛化的 pair 与 ban_set 更贴近题意。
- `component_pair_of_vertices` 集中完成“查根并规范化”这一步，录入限制和回答询问不会各自重复逻辑。
- Dsu 与 Component_pair 都公开最小接口，内部数组和记录表示不会泄漏到调用处。
- `Array.create` 清楚地表达 rank 数组以零初始化，`Fn.id` 则让单整数读入保持简短。

在编辑器里一次写下带签名约束的模块时，尚未完成的实现可能暂时触发很多类型错误。学习阶段可以先定义 module type，再完成模块，最后补上约束；较大的项目则更适合把公共接口放进 mli。不过对这篇单文件竞赛代码，最终的内联签名足够紧凑，也能保留清晰的抽象边界。

```ocaml
open Core

let read_int () =
  Scanf.scanf " %d" Fn.id

let read_int_pair () =
  Scanf.scanf " %d %d" (fun a b -> a, b)

module Dsu : sig
  type t

  val create : int -> t
  val find : t -> int -> int
  val union : t -> int -> int -> unit
end = struct
  type t =
    { parent : int array
    ; rank : int array
    }

  let create n =
    { parent = Array.init n ~f:Fn.id
    ; rank = Array.create ~len:n 0
    }

  let rec find t x =
    if Int.equal t.parent.(x) x
    then x
    else (
      let root = find t t.parent.(x) in
      t.parent.(x) <- root;
      root)

  let union t a b =
    let root_a = find t a in
    let root_b = find t b in
    if not (Int.equal root_a root_b)
    then (
      let rank_a = t.rank.(root_a) in
      let rank_b = t.rank.(root_b) in
      match Ordering.of_int (Int.compare rank_a rank_b) with
      | Less ->
        t.parent.(root_a) <- root_b
      | Greater ->
        t.parent.(root_b) <- root_a
      | Equal ->
        t.parent.(root_b) <- root_a;
        t.rank.(root_a) <- rank_a + 1)
end

module Component_pair : sig
  type t
  [@@deriving compare, sexp, hash]

  val create : int -> int -> t
end = struct
  type t =
    { smaller : int
    ; larger : int
    }
  [@@deriving compare, sexp, hash]

  let create a b =
    match Ordering.of_int (Int.compare a b) with
    | Less | Equal -> { smaller = a; larger = b }
    | Greater -> { smaller = b; larger = a }
end

let component_pair_of_vertices dsu a b =
  Component_pair.create
    (Dsu.find dsu a)
    (Dsu.find dsu b)

let () =
  let n, m = read_int_pair () in
  let dsu = Dsu.create (n + 1) in

  for _ = 1 to m do
    let a, b = read_int_pair () in
    Dsu.union dsu a b
  done;

  let k = read_int () in
  let forbidden =
    Hash_set.create ~size:k (module Component_pair)
  in

  for _ = 1 to k do
    let a, b = read_int_pair () in
    Hash_set.add forbidden
      (component_pair_of_vertices dsu a b)
  done;

  let q = read_int () in
  for _ = 1 to q do
    let u, v = read_int_pair () in
    let pair =
      component_pair_of_vertices dsu u v
    in
    print_endline
      (if Hash_set.mem forbidden pair
       then "No"
       else "Yes")
  done
```

# 小结

这次改进的重点不是换一个更复杂的算法，而是让代码中的表示与题目中的概念一致：顶点先归入分量，受限关系存为规范化的分量无序对，每次询问只做两次查根和一次哈希查询。

同样重要的是把副作用写得明确，把比较限定在具体类型上，并让模块只暴露调用者需要的操作。三版代码放在一起看，算法几乎没有变化，但最终实现的控制流、命名和边界都更容易读懂。
