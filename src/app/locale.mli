open! Core

type t =
  | En
  | Zh_hans
  | Zh_hant
[@@deriving equal, sexp]

val all : t list
val path_segment : t -> string
val of_path_segment : string -> t option
