+++
title = "AtCoder ABC325D: Earliest-Deadline-First Printing"
date = "2026-09-23"
category = "ocaml-learning"
subcategory = "ocaml-in-atcoder"
translation_key = "atcoder-abc325d-printing-machine"
tags = ["ocaml", "atcoder", "greedy", "sweep-line", "map", "code-review"]
summary = "Sweep products by arrival time, keep candidates in an ordered deadline multiset, and always print the one that leaves first, then organize the OCaml solution as a functional state machine."
draft = false
comments = false
+++

# Problem

- Platform: AtCoder Beginner Contest 325
- Problem: D - Printing Machine
- Link: [AtCoder problem statement](https://atcoder.jp/contests/abc325/tasks/abc325_d?lang=en)

Product `i` enters the printer's range at time `T_i` and leaves at time `T_i + D_i`. Printing one product is instantaneous, but consecutive prints must be at least `1` microsecond apart. The goal is to choose products and print times that maximize the number printed.

Each product can be viewed as a closed interval `[T_i, T_i + D_i]`: it must receive one integer print time inside that interval. The problem is therefore unit-task scheduling with release times and deadlines.

# Greedy Choice and Sweep Line

At the current time, every product that has arrived, has not left, and has not been printed is a candidate. We should choose the one with the earliest deadline.

The exchange argument is direct. Suppose an optimal schedule prints a later-deadline product `b` now and prints an earlier-deadline product `a` later. Swap their print times. Product `a` still meets its deadline, and because b's deadline is no earlier than `a`'s, `b` remains valid as well. Therefore, there is always an equally good optimal schedule that processes the earliest deadline now.

After sorting by arrival time, maintain:

- the products that have not arrived;
- an ordered multiset of deadlines for products that have arrived;
- the current time;
- the number already printed.

Each step performs one of these actions:

1. Add products whose arrival time is no later than the current time to the waiting set.
2. If the waiting set is nonempty, take its smallest deadline: print and advance time if it is still valid, or discard it if it has expired.
3. If the waiting set is empty, jump directly to the next arrival instead of simulating every idle microsecond.

Sorting costs `O(N log N)`. Each product enters and leaves the ordered set at most once, so the total time complexity is `O(N log N)` and the space complexity is `O(N)`.

# First Version: Put the Whole Process in the State

`main.ml` avoids a global mutable heap and represents the sweep as an immutable state. On each call, `solve` uses the next product's arrival and the emptiness of the waiting set to choose one transition, then tail-recurses.

Core's `Map` acts as an ordered deadline multiset here. A key is a deadline and its value is the number of products sharing it. `Map.min_elt` finds the earliest deadline; removing one element deletes the key only when its count reaches zero.

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

The four fields correspond exactly to the information the algorithm needs. `handle_product` processes an arrival event, `handle_waiting` prints or removes an expired product, and `solve` only decides which kind of event comes next.

In `(int, int, Int.comparator_witness) Map.t`, the first two parameters are the key and value types. The third records that this Map uses the integer comparator. This witness lets Core prevent Maps built with incompatible comparators from being mixed at the type level. When `Map.empty (module Int)` creates the Map, Core receives both the integer comparison function and its witness type.

Two boundary details also matter. Printing is allowed at the exact departure time, so the test is `now <= time`. Also, the largest `T_i + D_i` is `2 × 10^18`, which fits in AtCoder's 64-bit OCaml `int`.

# Cleaned-Up Version: Give the Multiset a Boundary

`better.ml` keeps the same algorithm while making its names and module boundaries match the problem more closely.

- `product` distinguishes `start` and `deadline` without relying on tuple positions.
- `Deadline_multiset` hides the Map-and-count representation and exposes only the operations required by the algorithm.
- `pending`, `time`, and `printed_count` state their roles more clearly.
- When the earliest deadline has expired, `remove_all` removes every product with that deadline at once. Time only moves forward, so none of them can ever be printed.
- `read_products` keeps recursive input in one function before sorting all products by arrival time.

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

# Takeaways

The key is to treat each product as a unit task with a release time and a deadline. After sweeping in every task currently available, always select the earliest deadline. Whenever the waiting set is empty, jump to the next arrival so the simulation does not depend on the numeric size of the time axis.

The most interesting OCaml choice is how the state transitions are organized. Immutable records and a persistent Map make every step return its next state explicitly. Once the Map is wrapped as `Deadline_multiset`, the main algorithm reads almost entirely in the language of the problem. The cleaned-up version does not change the algorithm, but it makes the invariants, boundaries, and data-structure responsibilities much easier to inspect.
