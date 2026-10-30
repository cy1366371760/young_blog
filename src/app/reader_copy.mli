type t =
  { search : string
  ; search_hint : string
  ; clear : string
  ; save : string
  ; saved : string
  ; all : string
  ; only_saved : string
  ; refresh : string
  ; settings : string
  ; font : string
  ; system : string
  ; light : string
  ; dark : string
  ; share : string
  ; empty : string
  ; empty_hint : string
  ; offline : string
  ; categories : string
  ; reading : string
  ; library : string
  ; local : string
  ; retry : string
  }

val for_locale : Locale.t -> t
