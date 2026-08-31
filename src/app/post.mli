open! Core

type t =
  { title : string
  ; section : Section.t
  ; category : string
  ; subcategory : string
  ; date : Date.t
  ; tags : string list
  ; summary : string
  ; slug : string
  }
[@@deriving sexp]

val sample : t list
val load : unit -> t list
val visible_in : t list -> section:Section.t -> t list
