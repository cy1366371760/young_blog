+++
title = "Jane Street Video Notes: Why OCaml"
date = "2026-10-28"
category = "ocaml-learning"
subcategory = "jane-street-video-notes"
translation_key = "jane-street-why-ocaml"
tags = ["ocaml", "jane-street", "polymorphism", "video-notes"]
summary = "A Boolean expression evaluator illustrates reuse across types and interpretation rules, followed by reflections on OCaml’s expressiveness, efficiency, and engineering tradeoffs."
draft = false
comments = false
+++

# Understanding Why OCaml Through a Boolean Expression Evaluator

This is the first entry in my notes on older Jane Street videos. After watching Yaron Minsky's [Why OCaml?](https://blog.janestreet.com/why-ocaml/), I wanted to keep the code that stayed with me and explain what it taught me about choosing OCaml. The official introduction places the talk in the 2015 internship program; the blog post appeared in 2016.

What I like most is that the structure of Boolean operations can stay fixed while users choose both the values at the leaves and how to interpret them as true or false.

## The Code in the Screenshot

This transcribes the screenshot with whitespace and layout tidied up, preserving its type, constructors, and evaluation logic. The later examples are my additions. They use the OCaml standard library and do not require opening Core.

```ocaml
type 'a expr =
  | True
  | False
  | And of 'a expr * 'a expr
  | Or of 'a expr * 'a expr
  | Not of 'a expr
  | Base of 'a

let rec eval eval_base expr =
  let eval' x = eval eval_base x in
  match expr with
  | True -> true
  | False -> false
  | Base base -> eval_base base
  | And (x, y) -> eval' x && eval' y
  | Or (x, y) -> eval' x || eval' y
  | Not x -> not (eval' x)
```

The expression type contains truth, falsehood, conjunction, disjunction, negation, and a leaf holding a custom value. `eval` recursively handles the Boolean structure. At `Base`, it delegates the value to `eval_base`. The local function `eval'` simply fixes the current interpretation rule for recursive calls. Conjunction and disjunction retain short-circuit evaluation.

Its inferred type makes that division of responsibility explicit:

```ocaml
val eval : ('a -> bool) -> 'a expr -> bool
```

The first argument interprets a leaf as a Boolean, the second is an expression over the corresponding type, and the final result is always Boolean.

## The First Layer: Polymorphism Over Leaf Types

My first observation is that `'a` lets the same Boolean system work with different types. Leaves can contain `int` or `float` values without rewriting the expression structure or evaluator. This is parametric polymorphism.

For example, I can treat integer zero as false and every other integer as true. For floating-point numbers, I can treat an absolute value below a threshold as false:

```ocaml
let eval_int expr =
  if expr = 0 then false else true

let epsilon = 1e-6

let eval_float expr =
  if Float.abs expr < epsilon then false else true

let () =
  assert (not (eval eval_int (Base 0)));
  assert (eval eval_int (And (Base 3, Not (Base 0))));
  assert (not (eval eval_float (Base 1e-8)));
  assert (eval eval_float (Base 0.1))
```

The floating-point rule is a deliberate semantic choice: in this example, “close enough to zero” means false. It is not a built-in truthiness conversion. The example considers only finite floating-point values and uses a positive threshold.

The type parameter does not mean that a single expression can freely mix integers and strings. Here, an `int expr` has `int` leaves throughout, and its interpretation function must also accept `int`.

## The Second Layer: Different Interpretations of One Type

What interests me even more is that fixing the leaf type to `string` still leaves room to change its interpretation.

One rule treats only the literal `"false"` as false. Another treats only the empty string `""` as false. Passing the same expression to different interpretation functions can produce different results:

```ocaml
let eval_string_false expr =
  if String.equal expr "false" then false else true

let eval_string_empty expr =
  if String.equal expr "" then false else true

let same_expr = Base "false"

let () =
  assert (not (eval eval_string_false same_expr));
  assert (eval eval_string_empty same_expr);
  assert (eval eval_string_false (Base ""));
  assert (not (eval eval_string_empty (Base "")))
```

Both rules accept `string` and return `bool`, so both satisfy the type checker. Which one fits the application depends on the meaning I want.

I therefore think of this design as having “two layers of reuse”: changing the leaf type, and changing the interpretation while keeping the type fixed. More precisely, the former is parametric polymorphism; the latter is behavior parameterized through a higher-order function. It does not introduce a second, independent type-polymorphism mechanism. The [OCaml manual](https://ocaml.org/manual/5.4/coreexamples.html) introduces type variables and functions as values, which correspond to these two parts.

This example makes the benefit of separating structure from interpretation tangible. A small amount of code leaves many possibilities open while the compiler checks that the expression and its interpreter agree.

## The Sweet Spot as I Understand It

Stepping back from this example, my main impression of the video is that OCaml strikes an appealing balance between expressive types, concise code, and efficient compiled execution. Abstraction and runtime efficiency can both be reasons to choose a language. This code is not itself a benchmark, though, and cannot establish the performance of a particular program.

Choosing a language also involves more than its type system. The [speaker's slides](https://slides.com/yaronminsky/why-ocaml) raise questions about teaching, hiring, and tools. My own reflections on those questions are:

- Teaching: a language should offer expressive power while remaining something newcomers can learn and use collaboratively.
- Hiring: people willing to learn the language may be a good fit, but the choice also affects the pool of candidates.
- Tools: even a good language needs investment in builds, editors, and libraries. A convenient ecosystem takes work.

For now, I think of OCaml as a “brilliant, but not brilliantly hard” choice: cleverly designed and expressive, with capabilities I can imagine learning gradually and putting to practical use. That is my personal summary, not a quotation from the speaker or a claim that learning it is effortless.

This small program captures that impression well. A type parameter leaves the data type open, a function parameter leaves the interpretation open, and the Boolean structure stays clear and stable.
