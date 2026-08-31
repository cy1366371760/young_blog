open! Core

type t =
  | Tech_en
  | Zh_notes
[@@deriving equal, sexp]

let all = [ Tech_en; Zh_notes ]

let label = function
  | Tech_en -> "EN Tech Learning"
  | Zh_notes -> "中文随记与创作"
;;

let short_label = function
  | Tech_en -> "Tech"
  | Zh_notes -> "中文"
;;

let path_prefix = function
  | Tech_en -> "/tech"
  | Zh_notes -> "/zh"
;;

let description = function
  | Tech_en ->
    "Typed notes on OCaml, systems, and frontend architecture, written as a learning \
     trail."
  | Zh_notes -> "给日常、阅读、记忆和虚构留下空间；更重视语气、节奏和回看时的余温。"
;;
