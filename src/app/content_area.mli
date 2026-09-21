open! Core

type t =
  | Tech
  | Essays
[@@deriving equal, sexp]

val all : t list
val path_segment : t -> string
val of_path_segment : string -> t option
