open! Core

type t =
  | Tech
  | Essays
[@@deriving equal, sexp]

let all = [ Tech; Essays ]

let path_segment = function
  | Tech -> "tech"
  | Essays -> "essays"
;;

let of_path_segment = function
  | "tech" -> Some Tech
  | "essays" -> Some Essays
  | _ -> None
;;
