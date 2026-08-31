open! Core

type t =
  | Tech_en
  | Zh_notes
[@@deriving equal, sexp_of]

val all : t list
val label : t -> string
val short_label : t -> string
val path_prefix : t -> string
val description : t -> string
