open! Core

type t =
  | Tech_en
  | Zh_notes
[@@deriving equal, sexp]

val all : t list
val label : t -> string
val short_label : t -> string
val path_segment : t -> string
val of_path_segment : string -> t option
val path_prefix : t -> string
val description : t -> string
