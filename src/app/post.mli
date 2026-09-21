open! Core

type t =
  { title : string
  ; area : Content_area.t
  ; locale : Locale.t
  ; category : string
  ; subcategory : string
  ; date : Date.t
  ; tags : string list
  ; summary : string
  ; slug : string
  ; translation_key : string
  }
[@@deriving sexp]

val sample : t list
val load : unit -> t list
val visible_in : t list -> area:Content_area.t -> locale:Locale.t -> t list
