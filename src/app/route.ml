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

let section = function
  | Index section -> section
  | Article article -> article.section
;;

let of_post (post : Post.t) =
  Article
    { section = post.section
    ; category = post.category
    ; subcategory = post.subcategory
    ; slug = post.slug
    }
;;

let path_segments = function
  | Index section -> [ Section.path_segment section ]
  | Article { section; category; subcategory; slug } ->
    [ Section.path_segment section; category; subcategory; slug ]
;;

let to_path route = "/" ^ String.concat (path_segments route) ~sep:"/"

let article_asset_path { section; category; subcategory; slug } =
  String.concat
    [ "/articles"; Section.path_segment section; category; subcategory; slug ^ ".html" ]
    ~sep:"/"
;;

let article_asset_path_for_route = function
  | Index _ -> None
  | Article article -> Some (article_asset_path article)
;;

let post_matches_article (post : Post.t) article =
  Section.equal post.section article.section
  && String.equal post.category article.category
  && String.equal post.subcategory article.subcategory
  && String.equal post.slug article.slug
;;

let parse_path path = String.split path ~on:'/' |> List.filter ~f:(Fn.non String.is_empty)

let parse_exn components =
  match parse_path components.Bonsai_web_ui_url_var.Components.path with
  | [] -> Index Section.Tech_en
  | [ section ] ->
    (match Section.of_path_segment section with
     | Some section -> Index section
     | None -> raise_s [%message "Unknown section" (section : string)])
  | [ section; category; subcategory; slug ] ->
    (match Section.of_path_segment section with
     | Some section -> Article { section; category; subcategory; slug }
     | None -> raise_s [%message "Unknown section" (section : string)])
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
    ~fallback:(Index Section.Tech_en)
;;
