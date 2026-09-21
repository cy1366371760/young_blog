+++
title = "AtCoder ABC304E: DSU and Forbidden Component Pairs"
date = "2026-09-22"
category = "ocaml-learning"
subcategory = "ocaml-in-atcoder"
translation_key = "atcoder-abc304e-good-graph"
tags = ["ocaml", "atcoder", "dsu", "hash-set", "code-review"]
summary = "Compress vertices into connected components, then store forbidden component pairs in a canonical form, with an OCaml review of effects, comparison, and module boundaries."
draft = false
comments = false
+++

# Problem

- Platform: AtCoder Beginner Contest 304
- Problem: E - Good Graph
- Link: [AtCoder problem statement](https://atcoder.jp/contests/abc304/tasks/abc304_e?lang=en)

We are given an undirected graph and several pairs of vertices that must remain disconnected. Each query independently adds one edge to the original graph and asks whether every restriction still holds.

The limits reach two hundred thousand, so traversing the graph again for every query is too expensive. What matters is not each individual vertex, but the connected components already formed in the original graph.

## Core Idea

First, use a disjoint-set union structure to merge every original edge. For each forbidden pair of vertices, find the roots of their components, turn the two roots into an unordered pair, and insert it into a hash set.

For a query, map both endpoints to component roots and canonicalize them in the same way. If the pair is in the forbidden set, the new edge would connect a restricted pair of vertices, so the answer is No. Otherwise, it is Yes.

An unordered pair needs one canonical representation. For example, always store the smaller root first. Input direction then has no effect on lookup, and there is no need to store or test both directions.

With path compression and union by rank, the total running time, including input, is near-linear: `O((N + M + K + Q) α(N))`. The extra space usage is `O(N + K)`.

# Problems in the First Version

The initial `old_impl.ml` already found the DSU-based direction, but it left several details that could be simpler or more precise.

First, Base's `List.init` calls `f` from `n - 1` down to `0` while constructing a list whose final order is correct. If `f` calls `Scanf.scanf`, each call still consumes the next line, so the values in the resulting list are reversed relative to the input. A following `List.rev` restores their order, but this relies on subtle effect timing. A `for` loop makes sequential contest input clearer.

Second, field order in a record expression does not indicate value direction. Both `{ u; v }` and `{ v; u }` store the current u and v under their named fields; actually swapping the values requires `{ u = v; v = u }`. Rather than test both directions each time, it is cleaner to canonicalize the unordered pair when creating it.

Finally, this version compares integers with ordinary equality and separates input, computation, and output into several lists. It can work, but its control flow is more complicated than the problem. The statement also guarantees that the original graph is already good, so a separate global bad-state check is unnecessary for answering the queries.

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

# Manual Improvement: Make Data Structures Express the Problem

`main.ml` makes several important changes: the DSU gains union by rank; input and output use `for` loops; forbidden relations move to a `Hash_set`; and `OrderPair.create` establishes one root order at the boundary.

`[@@deriving compare, sexp, hash]` generates the comparison, serialization, and hashing functions that containers need. This avoids error-prone boilerplate and lets the module work directly with Core's collection interfaces.

Integer comparison now uses `Ordering.of_int (Int.compare ...)` and matches Less, Equal, and Greater. This avoids polymorphic comparison and makes the intent of all three branches explicit.

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

# Final Cleanup: Semantic Names and Encapsulation

`gpt_optimize.ml` does not change the algorithm. It makes the implementation better match the model it represents.

- parent and rank are more direct than fa and height; Component_pair and forbidden also match the problem better than generic pair and ban_set names.
- `component_pair_of_vertices` centralizes the “find roots and canonicalize” step, so reading restrictions and answering queries do not duplicate it.
- Dsu and Component_pair expose only their minimal interfaces, keeping their arrays and record representations private.
- `Array.create` clearly initializes every rank to zero, while `Fn.id` keeps the one-integer reader concise.

Writing a signature-constrained module all at once can make an editor show many temporary type errors while its implementation is incomplete. During exploration, one option is to define a module type first, finish the module, and add the constraint afterward; larger projects usually put the public interface in an mli file. For this single-file contest solution, the final inline signatures remain compact while preserving clear abstraction boundaries.

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

# Takeaways

The important improvement was not a more complicated algorithm, but making the code's representation match the problem: vertices first map to components, restricted relations become canonical unordered component pairs, and each query performs only two root lookups and one hash lookup.

It is equally useful to make effects explicit, restrict comparison to concrete types, and expose only the operations a caller needs. The algorithm barely changes across the three versions, but the final control flow, names, and boundaries are much easier to understand.
