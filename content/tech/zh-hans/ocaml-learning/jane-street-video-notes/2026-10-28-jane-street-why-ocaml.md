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

这是 Jane Street 老视频观后感系列的第一篇，记下我看完 Yaron Minsky 的 [Why OCaml?](https://blog.janestreet.com/why-ocaml/) 后最有感觉的一段代码，以及我对选择 OCaml 的理解。

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

`eval` 负责与、或、非这些布尔结构，遇到叶子 `Base`，就把具体值交给 `eval_base`。局部函数 `eval'` 固定当前解释规则，方便递归调用。与和或保留短路求值。

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

我一开始把这理解成“两重 polymorphism”。更准确地说，是两层可复用性：`'a` 负责类型上的参数多态，`eval_base` 负责行为上的参数化。后者靠的是高阶函数：传入的两个函数即使都是 `string -> bool`，行为仍然可以不同。[OCaml 手册](https://ocaml.org/manual/5.4/coreexamples.html) 对类型变量和函数作为值的介绍，正好对应这两部分。

## 再往前一步：叶子也可以是业务条件

拿我的博客举例，如果以后做文章筛选，叶子可以表示“带有某个标签”或“作者是某个人”。下面是我据此补充的小例子：

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

这条规则表示：带有 OCaml 标签，并且作者不是匿名用户。`query` 只描述条件怎样组合，`check_condition` 结合当前文章判断每个条件，原来的求值器完全不用改。

这里所有叶子的类型都是 `condition`，但可以使用不同的构造器表达不同条件。这让我看到，前面的数字、字符串例子还可以进一步变成一个小型规则系统。

更有意思的是，规则本身已经是一棵数据树。除了执行它，我还可以另外写函数，把它显示成文字，或者简化 `And (True, x)` 这样的结构。《[Real World OCaml](https://dev.realworldocaml.org/variants.html)》也用布尔表达式展示了这种设计。

类型系统在这里帮我检查表达式和解释函数是否匹配；增加新的条件时，完整性检查也能提醒我补上遗漏的分支。至于条件是不是符合业务意图，仍然要由我确认。

## 我理解的 sweet spot

从这个例子回到整个视频，我的主要感受是：OCaml 在类型表达能力、代码简洁和执行效率之间，找到了一个很吸引我的 sweet spot。抽象能力和运行效率可以同时成为选语言的理由。不过，高效不等于抽象没有成本，具体程序还是要测量。这个平衡点也要放在团队和问题里看，官方介绍强调的就是 Jane Street 自己的使用场景。

[讲者的幻灯片](https://slides.com/yaronminsky/why-ocaml) 还讨论了教学、招聘和工具。我自己的理解是：

- 教学：表达能力要强，新人也要能逐步学会，用来协作。
- 招聘：愿意学这门语言的人可能很合拍，候选范围也会受到影响。
- 工具：构建、编辑器和库都需要维护，团队要有能力承担这些投入。

所以，我把 OCaml 记成一个 “brilliant, but not brilliantly hard” 的选择。这是我的概括，不是讲者原话。它有聪明的设计，也允许我从普通函数、数据类型和模式匹配开始，边学边用，需要时再采用更复杂的抽象。

这段小程序就让我有这种感觉：类型可以换，解释规则可以换，布尔结构仍然清楚。再往前一步，它就能用来描述我自己的业务规则。
