open! Core

type t =
  | En
  | Zh_hans
  | Zh_hant
[@@deriving equal, sexp]

let all = [ En; Zh_hans; Zh_hant ]

let path_segment = function
  | En -> "en"
  | Zh_hans -> "zh-hans"
  | Zh_hant -> "zh-hant"
;;

let of_path_segment = function
  | "en" -> Some En
  | "zh-hans" -> Some Zh_hans
  | "zh-hant" -> Some Zh_hant
  | _ -> None
;;
