open! Core

type t =
  { tech : string
  ; essays : string
  ; library : string
  ; category : string
  ; browse : string
  ; all_articles : string
  ; browse_topic : string
  ; back_to : string
  ; loading_article : string
  ; article_unavailable : string
  ; comments_boundary : string
  }

val for_locale : Locale.t -> t
val locale_label : Locale.t -> string
val area_label : Locale.t -> Content_area.t -> string
val area_description : Locale.t -> Content_area.t -> string
val path_segment_label : Locale.t -> string -> string
val notes_count : Locale.t -> int -> string
