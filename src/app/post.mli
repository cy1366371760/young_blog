open! Core

type t =
  { title : string
  ; section : Section.t
  ; date : Date.t
  ; tags : string list
  ; summary : string
  ; slug : string
  }
[@@deriving sexp_of]

val sample : t list
val visible_in : t list -> section:Section.t -> t list
