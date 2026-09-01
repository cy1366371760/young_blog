open! Core

type article =
  { section : Section.t
  ; category : string
  ; subcategory : string
  ; slug : string
  }
[@@deriving equal, sexp]

type t =
  | Index of Section.t
  | Article of article
[@@deriving equal, sexp]

val url_var : t Bonsai_web_ui_url_var.t
val section : t -> Section.t
val of_post : Post.t -> t
val to_path : t -> string
val article_asset_path : article -> string
val article_asset_path_for_route : t -> string option
val post_matches_article : Post.t -> article -> bool
