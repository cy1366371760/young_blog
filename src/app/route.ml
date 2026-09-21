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

let context = function
  | Index context -> context
  | Category { area; locale; _ }
  | Subcategory { area; locale; _ }
  | Article { area; locale; _ } -> { area; locale }
;;

let of_post (post : Post.t) =
  Article
    { area = post.area
    ; locale = post.locale
    ; category = post.category
    ; subcategory = post.subcategory
    ; slug = post.slug
    }
;;

let with_locale route locale =
  match route with
  | Index { area; _ } -> Index { area; locale }
  | Category { area; category; _ } -> Category { area; locale; category }
  | Subcategory { area; category; subcategory; _ } ->
    Subcategory { area; locale; category; subcategory }
  | Article { area; category; subcategory; slug; _ } ->
    Article { area; locale; category; subcategory; slug }
;;

let index_for_area route area =
  let locale = (context route).locale in
  Index { area; locale }
;;

let path_segments = function
  | Index { area; locale } ->
    [ Content_area.path_segment area; Locale.path_segment locale ]
  | Category { area; locale; category } ->
    [ Content_area.path_segment area; Locale.path_segment locale; category ]
  | Subcategory { area; locale; category; subcategory } ->
    [ Content_area.path_segment area; Locale.path_segment locale; category; subcategory ]
  | Article { area; locale; category; subcategory; slug } ->
    [ Content_area.path_segment area
    ; Locale.path_segment locale
    ; category
    ; subcategory
    ; slug
    ]
;;

let to_path route = "/" ^ String.concat (path_segments route) ~sep:"/"

let article_asset_path { area; locale; category; subcategory; slug } =
  String.concat
    [ "/articles"
    ; Content_area.path_segment area
    ; Locale.path_segment locale
    ; category
    ; subcategory
    ; slug ^ ".html"
    ]
    ~sep:"/"
;;

let article_asset_path_for_route = function
  | Article article -> Some (article_asset_path article)
  | Index _ | Category _ | Subcategory _ -> None
;;

let post_matches_article (post : Post.t) (article : article) =
  Content_area.equal post.area article.area
  && Locale.equal post.locale article.locale
  && String.equal post.category article.category
  && String.equal post.subcategory article.subcategory
  && String.equal post.slug article.slug
;;

let parse_path path = String.split path ~on:'/' |> List.filter ~f:(Fn.non String.is_empty)

let parse_context area locale =
  match Content_area.of_path_segment area, Locale.of_path_segment locale with
  | Some area, Some locale -> { area; locale }
  | _ ->
    raise_s [%message "Unknown content area or locale" (area : string) (locale : string)]
;;

let parse_exn components =
  match parse_path components.Bonsai_web_ui_url_var.Components.path with
  | [] -> Index { area = Content_area.Tech; locale = Locale.En }
  | [ area; locale ] -> Index (parse_context area locale)
  | [ area; locale; category ] ->
    let context = parse_context area locale in
    Category { area = context.area; locale = context.locale; category }
  | [ area; locale; category; subcategory ] ->
    let context = parse_context area locale in
    Subcategory { area = context.area; locale = context.locale; category; subcategory }
  | [ area; locale; category; subcategory; slug ] ->
    let context = parse_context area locale in
    Article { area = context.area; locale = context.locale; category; subcategory; slug }
  | parts -> raise_s [%message "Invalid route" (parts : string list)]
;;

let unparse route = Bonsai_web_ui_url_var.Components.create ~path:(to_path route) ()

let url_var =
  Bonsai_web_ui_url_var.create_exn
    (module struct
      type nonrec t = t [@@deriving equal, sexp]

      let parse_exn = parse_exn
      let unparse = unparse
    end)
    ~fallback:(Index { area = Content_area.Tech; locale = Locale.En })
;;
