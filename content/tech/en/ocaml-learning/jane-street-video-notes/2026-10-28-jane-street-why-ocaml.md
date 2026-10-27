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

This is the first entry in my notes on older Jane Street videos. After watching Yaron Minsky's [Why OCaml?](https://blog.janestreet.com/why-ocaml/), I wanted to keep the code that stayed with me and explain how I think about choosing OCaml.

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

`eval` handles Boolean structure such as conjunction, disjunction, and negation. At a `Base` leaf, it delegates the value to `eval_base`. The local function `eval'` fixes the current interpretation rule for recursive calls. Conjunction and disjunction retain short-circuit evaluation.

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

I initially thought of this as “two layers of polymorphism.” More precisely, it offers two layers of reuse: `'a` provides parametric polymorphism over types, and `eval_base` parameterizes behavior. The latter uses a higher-order function: two functions can both have type `string -> bool` and still behave differently. The [OCaml manual](https://ocaml.org/manual/5.4/coreexamples.html) introduces type variables and functions as values, matching these two parts.

## One Step Further: Leaves Can Be Business Conditions

If I add article filtering to my blog in the future, leaves could mean “has a particular tag” or “was written by a particular author.” Here is a small example I added to explore that idea:

```ocaml
type condition =
  | Author_is of string
  | Has_tag of string

type article =
  { author : string
  ; tags : string list
  }

let check_condition article = function
  | Author_is name -> String.equal article.author name
  | Has_tag tag -> List.exists (String.equal tag) article.tags

let query =
  And (Base (Has_tag "ocaml"), Not (Base (Author_is "anonymous")))

let matches article = eval (check_condition article) query

let () =
  assert (matches { author = "young"; tags = [ "ocaml" ] });
  assert (not (matches { author = "anonymous"; tags = [ "ocaml" ] }));
  assert (not (matches { author = "young"; tags = [ "travel" ] }))
```

This rule means: has the OCaml tag and was not written by an anonymous user. `query` describes how conditions combine, while `check_condition` checks each condition against the current article. The original evaluator needs no changes.

All leaves have type `condition`, but different constructors express different conditions. This shows me how the earlier number and string examples can grow into a small rule system.

More interestingly, the rule itself is now a data tree. Beyond executing it, I could write other functions to display it as text or simplify structures such as `And (True, x)`. [Real World OCaml](https://dev.realworldocaml.org/variants.html) also uses Boolean expressions to illustrate this design.

The type system checks that the expression and its interpreter agree. When I add a condition, exhaustiveness checking can also remind me to handle missing cases. Whether the conditions match the intended business rules is still up to me.

## The Sweet Spot as I Understand It

Stepping back from this example, my main impression is that OCaml finds an appealing sweet spot between expressive types, concise code, and execution efficiency. Abstraction and runtime efficiency can both be reasons to choose a language. Efficiency does not make abstraction free, though; actual programs still need measurement. The balance also depends on the team and the problem. The official introduction emphasizes Jane Street's own use case.

The [speaker's slides](https://slides.com/yaronminsky/why-ocaml) also discuss teaching, hiring, and tools. My own understanding is:

- Teaching: a language should be expressive while allowing newcomers to learn gradually and work together.
- Hiring: people willing to learn it may be a good fit, but the choice also affects the candidate pool.
- Tools: builds, editors, and libraries need maintenance, and the team needs the capacity to support that work.

I therefore think of OCaml as a “brilliant, but not brilliantly hard” choice. That is my summary, not a quotation from the speaker. It offers clever designs while letting me start with ordinary functions, data types, and pattern matching, learn by doing, and adopt more complex abstractions when I need them.

This small program gives me that feeling: the types can change, the interpretation rules can change, and the Boolean structure stays clear. One step further, it can describe business rules of my own.
