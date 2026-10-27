+++
title = "Jane Street 老视频观后感：Why OCaml"
date = "2026-10-28"
category = "ocaml-learning"
subcategory = "jane-street-video-notes"
translation_key = "jane-street-why-ocaml"
tags = ["ocaml", "jane-street", "polymorphism", "video-notes"]
summary = "从一个布尔表达式求值器出发，理解类型参数与解释函数带来的两层可复用性，以及 OCaml 在表达力、效率和工程取舍之间的平衡。"
draft = false
comments = false
+++

# 从一段布尔表达式代码理解 Why OCaml

这是 Jane Street 老视频观后感系列的第一篇，记下我看完 Yaron Minsky 的 [Why OCaml?](https://blog.janestreet.com/why-ocaml/) 后最有感觉的一段代码，以及我对选择 OCaml 这件事的理解。官方介绍说明，这场分享来自 2015 年的实习生项目，博客于 2016 年发布。

我最喜欢的地方是：布尔运算的结构可以固定下来，而叶子上放什么、怎样把叶子解释为真假，都可以留给使用者决定。

## 图片里的代码

下面按截图抄录代码，只整理空白与排版，保留原来的类型、构造器和求值逻辑。后面的示例是我据此补充的，使用 OCaml 标准库，不需要打开 Core。

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

这个表达式类型包含真、假、与、或、非，以及一个存放自定义值的叶子。`eval` 负责递归处理布尔结构，遇到 `Base` 时，把具体值交给 `eval_base`。局部函数 `eval'` 只是把当前解释规则固定下来，方便递归调用。与和或仍然保留短路求值。

它的推导类型把这个分工写得很清楚：

```ocaml
val eval : ('a -> bool) -> 'a expr -> bool
```

第一项是把叶子解释为布尔值的函数，第二项是对应类型的表达式，最终结果总是布尔值。

## 第一层：对叶子类型的多态

我的第一个理解是，`'a` 让同一套布尔系统适用于不同类型。叶子可以是 `int`，也可以是 `float`，而表达式结构和求值器不需要跟着重写。这就是参数多态。

比如，我可以规定整数零为假，其他整数为真；对于浮点数，则把绝对值小于某个阈值的数视为假：

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

这里的浮点规则是我主动选择的语义：在这个例子里，“足够接近零”算假，它不是语言自带的真假转换规则。示例只考虑有限浮点数，阈值取正数。

类型参数也不是说同一个表达式可以随意混装整数和字符串。在这里，一棵 `int expr` 的叶子统一使用 `int`，对应的解释函数也必须接受 `int`。

## 第二层：同一种类型，也可以有不同的解释

我更感兴趣的是，即使把叶子固定为 `string`，仍然可以继续改变它的解释规则。

一种规则是只有字面值 `"false"` 算假；另一种规则是只有空字符串 `""` 算假。把同一棵表达式交给不同的解释函数，就可以得到不同的结果：

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

这两条规则都接受 `string`，返回 `bool`，所以类型系统都允许。至于哪条规则适合当前业务，取决于我想表达什么。

因此，我愿意把这个设计理解成“两层可复用性”：一层更换叶子的类型，另一层在类型不变时更换解释规则。严格说，前者是参数多态，后者是通过高阶函数实现的行为参数化；这里并没有引入第二种独立的类型多态机制。[OCaml 手册](https://ocaml.org/manual/5.4/coreexamples.html) 对类型变量和函数作为值的介绍，也对应着这两部分。

这个例子让我直观地看到，把结构与解释分开之后，一小段代码就能保留很多使用空间，同时让编译器检查表达式和解释函数是否匹配。

## 我理解的 sweet spot

从这个例子回到整个视频，我的主要感受是：OCaml 在强大的类型表达能力、简洁的代码和编译后程序的执行效率之间，找到了一个很吸引我的平衡点。抽象能力和运行效率可以同时成为选语言的理由。当然，这段代码本身不是性能测试，不能单凭它推导出某个具体程序的性能结论。

而选择语言也不只是看类型系统。[讲者的幻灯片](https://slides.com/yaronminsky/why-ocaml) 还列出了教学、招聘和工具方面的问题。沿着这些问题，我自己的理解是：

- 教学：语言足够有表达力，也要考虑新人能否学会并用来协作。
- 招聘：愿意学习这门语言的人可能很合拍，但候选人的范围也会受到影响。
- 工具：语言本身再好，构建、编辑器和库也需要投入精力，生态的便利并不是免费的。

所以，我暂时把 OCaml 记成一个 “brilliant, but not brilliantly hard” 的选择：设计聪明，有足够强的表达能力，同时又让我觉得这些能力可以逐步学会、实际用起来。这是我的观后感概括，不是讲者原话，也不是说学习它毫无门槛。

这段小程序正好承载了这种感受：类型参数负责开放数据类型，函数参数负责开放解释规则，剩下的布尔结构保持清楚而稳定。
