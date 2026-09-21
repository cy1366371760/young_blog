open! Core

type context =
  { area : Content_area.t
  ; locale : Locale.t
  }
[@@deriving equal, sexp]

type article =
  { area : Content_area.t
  ; locale : Locale.t
  ; category : string
  ; subcategory : string
  ; slug : string
  }
[@@deriving equal, sexp]

type category =
  { area : Content_area.t
  ; locale : Locale.t
  ; category : string
  }
[@@deriving equal, sexp]

type subcategory =
  { area : Content_area.t
  ; locale : Locale.t
  ; category : string
  ; subcategory : string
  }
[@@deriving equal, sexp]

type t =
  | Index of context
  | Category of category
  | Subcategory of subcategory
  | Article of article
[@@deriving equal, sexp]

val context : t -> context
val of_post : Post.t -> t
val with_locale : t -> Locale.t -> t
val index_for_area : t -> Content_area.t -> t
val to_path : t -> string
val article_asset_path_for_route : t -> string option
val post_matches_article : Post.t -> article -> bool
val url_var : t Bonsai_web_ui_url_var.t
