open! Core
open Bonsai_web.Cont

type t =
  { query : string
  ; tag : string option
  ; saved_only : bool
  ; saved : string list
  ; font_size : int
  ; theme : string
  }
[@@deriving equal, sexp]

type action =
  | Query of string
  | Tag of string option
  | Saved_only of bool
  | Toggle_saved of string
  | Font of int
  | Theme of string
  | Clear_filters
[@@deriving sexp]

val saved_key : Post.t -> string
val is_saved : t -> Post.t -> bool
val component : Bonsai.graph -> t Bonsai.t * (action -> unit Effect.t) Bonsai.t
