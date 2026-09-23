+++
title = "AtCoder ABC325D：最早截止时间优先的打印调度"
date = "2026-09-23"
category = "ocaml-learning"
subcategory = "ocaml-in-atcoder"
translation_key = "atcoder-abc325d-printing-machine"
tags = ["ocaml", "atcoder", "greedy", "sweep-line", "map", "code-review"]
summary = "按进入时间扫描商品，用截止时间的有序多重集合维护候选，并始终打印最早离开的商品；再用函数式状态机整理 OCaml 实现。"
draft = false
comments = false
+++

# 问题

- 平台：AtCoder Beginner Contest 325
- 题目：D - Printing Machine
- 链接：[AtCoder 题目说明](https://atcoder.jp/contests/abc325/tasks/abc325_d?lang=en)

商品 `i` 在时刻 `T_i` 进入打印机范围，并在时刻 `T_i + D_i` 离开。打印一个商品是瞬间完成的，但两次打印之间至少要间隔 `1` 微秒。目标是选择打印对象和时刻，使打印过的商品数量最大。

每个商品都可以看成一个闭区间 `[T_i, T_i + D_i]`：只能在这个区间内为它安排一个整数打印时刻。于是问题变成了带释放时间和截止时间的单位任务调度。

# 贪心与扫描线

在当前时刻，所有已经进入、尚未离开且没有打印的商品都是候选。此时应选择截止时间最早的商品。

交换论证很直接：假设某个最优方案在当前时刻先打印截止时间较晚的商品 `b`，而截止时间更早的商品 `a` 在之后才打印。交换两者的打印时刻后，`a` 一定仍来得及；`b` 的截止时间不早于 `a`，也不会因为交换而失效。因此，总能得到一个同样最优、但当前先处理最早截止商品的方案。

实现时先按进入时间排序，再维护：

- 尚未进入的商品列表；
- 已进入商品的截止时间多重集合；
- 当前时刻；
- 已打印数量。

每一步执行以下一种操作：

1. 把所有进入时间不晚于当前时刻的商品逐个加入等待集合。
2. 若等待集合非空，取最小截止时间：未过期就打印并令时间加一，已过期就丢弃。
3. 若等待集合为空，直接跳到下一个商品的进入时间，避免逐微秒模拟空闲区间。

排序需要 `O(N log N)`，每个商品至多进入和离开有序集合各一次，因此总时间复杂度是 `O(N log N)`，空间复杂度是 `O(N)`。

# 第一版：把整个过程写进状态

`main.ml` 没有使用全局可变堆，而是把扫描过程表示为一个不可变状态。`solve` 每次根据“下一个商品是否已经到达”和“等待集合是否为空”选择一次状态转移，然后尾递归到下一步。

Core 的 `Map` 在这里充当按截止时间排序的多重集合。键是截止时间，值是拥有该截止时间的商品数量。`Map.min_elt` 找到最早截止时间；删除一个元素时，计数降到零才移除键。

```ocaml
open Core

let read_int () = Scanf.scanf " %d" (fun x -> x)
let read_pair_int () = Scanf.scanf " %d %d" (fun x y -> (x, y))

type state = {
  products : (int*int) List.t;
  waiting : (int, int, Int.comparator_witness) Map.t;
  now : int;
  printed : int;
}

let handle_product {products; waiting; now; printed} =
  match products with 
  | [] -> raise_s [%message "handle_product: empty products"]
  | (start, end_) :: rem -> 
    let waiting =
      Map.update waiting end_ ~f:(function
        | None -> 1
        | Some x -> x + 1) in
    {products = rem; waiting; now = Int.max now start; printed}

let handle_waiting {products; waiting; now; printed} =
  match Map.min_elt waiting with
  | None -> raise_s [%message "handle_waiting: empty waiting"]
  | Some (time, _) -> 
    let waiting = Map.change waiting time ~f:(function
    | Some 1 -> None
    | Some 0 | None -> raise_s [%message "invalid map value"]
    | Some x -> Some (x - 1)) in
    let now, printed = 
      if now <= time then (now + 1, printed + 1) 
      else (now, printed) in
    {products; waiting; now; printed}

let rec solve ({products; waiting; now; printed} as sta) =
  match products with
  | [] -> 
    if Map.is_empty waiting then printed
    else solve (handle_waiting sta)
  | (start, _) :: _ -> 
    if start <= now then solve (handle_product sta)
    else 
      if Map.is_empty waiting then
        solve (handle_product sta) 
      else 
        solve (handle_waiting sta)

let () =
  let n = read_int () in
  let products =
    List.init n ~f:(fun _ ->
      let start, duration = read_pair_int () in
      (start, start + duration))
  in
  let products = List.sort products ~compare:(fun (start1, _) (start2, _) -> 
    Int.compare start1 start2)
  in
  let waiting = Map.empty (module Int) in
  let ans = 
    solve {products; waiting; now = 0; printed = 0}
  in
  printf "%d\n" ans
```

这版的四个状态字段正好对应算法所需的信息。`handle_product` 负责扫描线的到达事件，`handle_waiting` 负责打印或清理过期商品，`solve` 只负责决定下一种事件。

类型 `(int, int, Int.comparator_witness) Map.t` 中，前两个参数分别是键和值。第三个参数记录这张 Map 使用的是整数比较器；这个“见证”让 Core 在类型层面阻止使用不兼容比较器的 Map 被混在一起。创建 `Map.empty (module Int)` 时，Core 同时取得整数比较函数和对应的见证类型。

还有两个边界值得留意：离开时刻也允许打印，所以判断是 `now <= time`；而 `T_i + D_i` 最大为 `2 × 10^18`，在 AtCoder 的 64 位 OCaml `int` 范围内。

# 整理版：为多重集合建立边界

`better.ml` 保留相同算法，但让命名和模块边界更贴近题意。

- `product` 明确区分 `start` 和 `deadline`，不再依赖二元组位置。
- `Deadline_multiset` 隐藏 Map 的计数实现，只暴露算法真正需要的操作。
- `pending`、`time` 和 `printed_count` 比较清楚地表达状态含义。
- 当最早截止时间已经过期时，`remove_all` 一次删除拥有同一截止时间的所有商品；既然当前时间只会继续前进，它们不可能再被打印。
- `read_products` 把递归读入集中在一个函数中，再统一按进入时间排序。

```ocaml
open Core

let read_int () =
  Scanf.scanf " %d" Fn.id

let read_int_pair () =
  Scanf.scanf " %d %d" (fun x y -> x, y)

type product =
  { start : int
  ; deadline : int
  }

module Deadline_multiset : sig
  type t

  val empty : t
  val is_empty : t -> bool
  val add : t -> int -> t
  val min_elt : t -> (int * int) option
  val remove_one : t -> int -> t
  val remove_all : t -> int -> t
end = struct
  type t = (int, int, Int.comparator_witness) Map.t

  let empty =
    Map.empty (module Int)

  let is_empty =
    Map.is_empty

  let min_elt =
    Map.min_elt

  let add t deadline =
    Map.update t deadline ~f:(function
      | None -> 1
      | Some count -> count + 1)

  let remove_one t deadline =
    Map.change t deadline ~f:(function
      | Some 1 -> None
      | Some count when count > 1 -> Some (count - 1)
      | Some _ | None -> failwith "invalid deadline multiset")

  let remove_all t deadline =
    Map.remove t deadline
end

type state =
  { pending : product list
  ; waiting : Deadline_multiset.t
  ; time : int
  ; printed_count : int
  }

let activate_next_product state =
  match state.pending with
  | [] ->
    failwith "activate_next_product: empty pending"
  | product :: pending ->
    { state with
      pending
    ; waiting =
        Deadline_multiset.add
          state.waiting
          product.deadline
    ; time = Int.max state.time product.start
    }

let process_earliest_waiting state =
  match Deadline_multiset.min_elt state.waiting with
  | None ->
    failwith "process_earliest_waiting: empty waiting"
  | Some (deadline, _) ->
    if state.time > deadline
    then
      { state with
        waiting =
          Deadline_multiset.remove_all
            state.waiting
            deadline
      }
    else
      { state with
        waiting =
          Deadline_multiset.remove_one
            state.waiting
            deadline
      ; time = state.time + 1
      ; printed_count = state.printed_count + 1
      }

let rec solve state =
  match state.pending with
  | [] ->
    if Deadline_multiset.is_empty state.waiting
    then state.printed_count
    else solve (process_earliest_waiting state)
  | product :: _ ->
    if
      product.start <= state.time
      || Deadline_multiset.is_empty state.waiting
    then
      solve (activate_next_product state)
    else
      solve (process_earliest_waiting state)

let rec read_products remaining acc =
  if remaining = 0
  then acc
  else (
    let start, duration = read_int_pair () in
    let product =
      { start
      ; deadline = start + duration
      }
    in
    read_products (remaining - 1) (product :: acc))

let () =
  let n = read_int () in

  let pending =
    read_products n []
    |> List.sort ~compare:(fun a b ->
      Int.compare a.start b.start)
  in

  let initial_state =
    { pending
    ; waiting = Deadline_multiset.empty
    ; time = 0
    ; printed_count = 0
    }
  in

  printf "%d\n" (solve initial_state)
```

# 小结

这道题的关键是把商品看成带开始时间和截止时间的单位任务：扫描到当前时刻已经可用的任务后，总选截止时间最早的一个。只要等待集合为空，就把时间跳到下一次到达，整个模拟便不会依赖时间轴的数值范围。

OCaml 实现里最有意思的是状态转移的组织方式。不可变记录与持久化 Map 让每一步都显式返回新状态；再把 Map 封装成 `Deadline_multiset` 后，主体代码几乎只剩题目语言。与第一版相比，整理版没有更换算法，却让不变量、边界条件和数据结构职责都更容易检查。
