open! Core
open! Bonsai_web.Cont

type t =
  | No_article
  | Loading
  | Loaded of string
  | Failed of string
[@@deriving equal, sexp]

val component
  :  string option Bonsai.t
  -> revision:int Bonsai.t
  -> Bonsai.graph
  -> t Bonsai.t
