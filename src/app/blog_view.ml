open! Core
open Bonsai_web.Cont
module Attr = Vdom.Attr
module Node = Vdom.Node

let classes names = Attr.class_ (String.concat names ~sep:" ")
let text = Node.text

let nav_link ~classes ~set_route route label =
  Bonsai_web_ui_nav_link.make
    ~attrs:[ classes ]
    ~set_url:set_route
    ~page_to_string:Route.to_path
    route
    label
;;

let area_button ~route ~set_route area =
  let context = Route.context route in
  let active_area = context.area in
  let locale = context.locale in
  let is_active = Content_area.equal active_area area in
  nav_link
    ~classes:(classes [ "section-tab"; (if is_active then "is-active" else "") ])
    ~set_route
    (Route.index_for_area route area)
    (Copy.area_label locale area)
;;

let route_for_locale posts route locale =
  match route with
  | Route.Article article ->
    (match List.find posts ~f:(fun post -> Route.post_matches_article post article) with
     | None -> Route.with_locale route locale
     | Some post ->
       (match
          List.find posts ~f:(fun candidate ->
            Content_area.equal candidate.area post.area
            && Locale.equal candidate.locale locale
            && String.equal candidate.translation_key post.translation_key)
        with
        | Some translation -> Route.of_post translation
        | None -> Route.with_locale route locale))
  | Index _ | Category _ | Subcategory _ -> Route.with_locale route locale
;;

let locale_button ~route ~set_route ~posts locale =
  let active_locale = (Route.context route).locale in
  let is_active = Locale.equal active_locale locale in
  nav_link
    ~classes:(classes [ "locale-tab"; (if is_active then "is-active" else "") ])
    ~set_route
    (route_for_locale posts route locale)
    (Copy.locale_label locale)
;;

let tag_chip tag = Node.span ~attrs:[ Attr.class_ "tag-chip" ] [ text tag ]
let unique_sorted values = List.dedup_and_sort values ~compare:String.compare

let posts_in_category posts category =
  List.filter posts ~f:(fun (post : Post.t) -> String.equal post.category category)
;;

let posts_in_subcategory posts category subcategory =
  List.filter posts ~f:(fun (post : Post.t) ->
    String.equal post.category category && String.equal post.subcategory subcategory)
;;

let category_card ~set_route ~(context : Route.context) ~posts category =
  let category_posts = posts_in_category posts category in
  let note_count = List.length category_posts in
  let subcategory_count =
    List.map category_posts ~f:(fun (post : Post.t) -> post.subcategory)
    |> unique_sorted
    |> List.length
  in
  let area = context.area in
  let locale = context.locale in
  Node.create
    "article"
    ~attrs:[ Attr.class_ "browse-card" ]
    [ nav_link
        ~classes:(Attr.class_ "browse-card-title")
        ~set_route
        (Route.Category { area; locale; category })
        (Copy.path_segment_label locale category)
    ; Node.div
        ~attrs:[ Attr.class_ "browse-card-meta" ]
        [ text (Copy.subcategories_and_notes locale ~subcategory_count ~note_count) ]
    ]
;;

let subcategory_card ~set_route ~(context : Route.context) ~category ~posts subcategory =
  let note_count = List.length (posts_in_subcategory posts category subcategory) in
  let area = context.area in
  let locale = context.locale in
  Node.create
    "article"
    ~attrs:[ Attr.class_ "browse-card" ]
    [ nav_link
        ~classes:(Attr.class_ "browse-card-title")
        ~set_route
        (Route.Subcategory { area; locale; category; subcategory })
        (Copy.path_segment_label locale subcategory)
    ; Node.div
        ~attrs:[ Attr.class_ "browse-card-meta" ]
        [ text (Copy.notes_count locale note_count) ]
    ]
;;

let post_card ~set_route (post : Post.t) =
  Node.create
    "article"
    ~attrs:[ Attr.class_ "post-card" ]
    [ nav_link
        ~classes:(Attr.class_ "post-title")
        ~set_route
        (Route.of_post post)
        post.title
    ; Node.div ~attrs:[ Attr.class_ "post-meta" ] [ text (Date.to_string post.date) ]
    ; Node.p ~attrs:[ Attr.class_ "post-summary" ] [ text post.summary ]
    ; Node.div ~attrs:[ Attr.class_ "post-tags" ] (List.map post.tags ~f:tag_chip)
    ]
;;

let graph_node ~status label =
  Node.div ~attrs:[ classes [ "graph-node"; status ] ] [ text label ]
;;

let incremental_panel ~route ~article =
  let context = Route.context route in
  let area = context.area in
  let locale = context.locale in
  let copy = Copy.for_locale locale in
  let route_status =
    match route with
    | Route.Index _ -> "index"
    | Route.Category _ -> "category"
    | Route.Subcategory _ -> "subcategory"
    | Route.Article _ -> "article"
  in
  let load_status =
    match article with
    | Article_loader.No_article -> "idle"
    | Article_loader.Loading -> "loading"
    | Article_loader.Loaded _ -> "loaded"
    | Article_loader.Failed _ -> "failed"
  in
  Node.create
    "aside"
    ~attrs:[ Attr.class_ "side-panel" ]
    [ Node.h2 [ text copy.incremental_trace ]
    ; Node.div
        ~attrs:[ Attr.class_ "graph-grid" ]
        [ graph_node ~status:"is-cold" (Copy.trace_node_label locale "all-posts")
        ; graph_node ~status:"is-hot" (Copy.area_label locale area)
        ; graph_node ~status:"is-warm" (Copy.trace_node_label locale route_status)
        ; graph_node ~status:"is-hot" (Copy.trace_node_label locale "filter")
        ; graph_node ~status:"is-warm" (Copy.trace_node_label locale "sort")
        ; graph_node ~status:"is-hot" (Copy.trace_node_label locale load_status)
        ]
    ; Node.div ~attrs:[ Attr.class_ "comments-slot" ] [ text copy.comments_boundary ]
    ]
;;

let back_link ~set_route route label =
  nav_link ~classes:(Attr.class_ "back-link") ~set_route route label
;;

let section_header (context : Route.context) =
  let area = context.area in
  let locale = context.locale in
  let copy = Copy.for_locale locale in
  Node.div
    ~attrs:[ Attr.class_ "section-header" ]
    [ Node.div ~attrs:[ Attr.class_ "section-kicker" ] [ text copy.library ]
    ; Node.h1 [ text (Copy.area_label locale area) ]
    ; Node.p [ text (Copy.area_description locale area) ]
    ]
;;

let article_header ~set_route (article : Route.article) post =
  let locale = article.Route.locale in
  let copy = Copy.for_locale locale in
  let title =
    Option.value_map post ~default:article.slug ~f:(fun (post : Post.t) -> post.title)
  in
  let summary =
    Option.value_map post ~default:"" ~f:(fun (post : Post.t) -> post.summary)
  in
  Node.div
    ~attrs:[ Attr.class_ "article-header" ]
    [ back_link
        ~set_route
        (Route.Subcategory
           { area = article.area
           ; locale = article.locale
           ; category = article.category
           ; subcategory = article.subcategory
           })
        [%string "%{copy.back_to} %{Copy.path_segment_label locale article.subcategory}"]
    ; Node.h1 [ text title ]
    ; (if String.is_empty summary
       then Node.none
       else Node.p ~attrs:[ Attr.class_ "article-lede" ] [ text summary ])
    ]
;;

let article_body ~locale ~article_exists article =
  let copy = Copy.for_locale locale in
  if not article_exists
  then Node.div ~attrs:[ Attr.class_ "article-state" ] [ text copy.article_unavailable ]
  else (
    match article with
    | Article_loader.No_article -> Node.none
    | Article_loader.Loading ->
      Node.div ~attrs:[ Attr.class_ "article-state" ] [ text copy.loading_article ]
    | Article_loader.Failed message ->
      Node.div ~attrs:[ classes [ "article-state"; "is-error" ] ] [ text message ]
    | Article_loader.Loaded html ->
      Node.inner_html
        ~tag:"div"
        ~attrs:[ Attr.class_ "article-body" ]
        ~this_html_is_sanitized_and_is_totally_safe_trust_me:html
        ())
;;

let category_page ~set_route ~(context : Route.context) ~posts category =
  let area = context.area in
  let locale = context.locale in
  let copy = Copy.for_locale locale in
  let subcategories =
    posts_in_category posts category
    |> List.map ~f:(fun (post : Post.t) -> post.subcategory)
    |> unique_sorted
  in
  Node.section
    ~attrs:[ Attr.class_ "main-copy" ]
    [ back_link
        ~set_route
        (Route.Index context)
        [%string "%{copy.back_to} %{Copy.area_label locale area}"]
    ; Node.div
        ~attrs:[ Attr.class_ "section-header" ]
        [ Node.div ~attrs:[ Attr.class_ "section-kicker" ] [ text copy.category ]
        ; Node.h1 [ text (Copy.path_segment_label locale category) ]
        ; Node.p [ text copy.choose_topic ]
        ]
    ; Node.div
        ~attrs:[ Attr.class_ "browse-list" ]
        (List.map
           subcategories
           ~f:(subcategory_card ~set_route ~context ~category ~posts))
    ]
;;

let subcategory_page ~set_route ~(context : Route.context) ~posts ~category ~subcategory =
  let area = context.area in
  let locale = context.locale in
  let copy = Copy.for_locale locale in
  let notes = posts_in_subcategory posts category subcategory in
  Node.section
    ~attrs:[ Attr.class_ "main-copy" ]
    [ back_link
        ~set_route
        (Route.Category { area; locale; category })
        [%string "%{copy.back_to} %{Copy.path_segment_label locale category}"]
    ; Node.div
        ~attrs:[ Attr.class_ "section-header" ]
        [ Node.div
            ~attrs:[ Attr.class_ "section-kicker" ]
            [ text (Copy.path_segment_label locale category) ]
        ; Node.h1 [ text (Copy.path_segment_label locale subcategory) ]
        ; Node.p [ text copy.browse_topic ]
        ]
    ; Node.div
        ~attrs:[ Attr.class_ "article-list" ]
        (List.map notes ~f:(post_card ~set_route))
    ]
;;

let page ~route ~set_route ~posts ~all_posts ~article =
  let context = Route.context route in
  let article_exists =
    match route with
    | Route.Article article_route ->
      List.exists posts ~f:(fun post -> Route.post_matches_article post article_route)
    | Index _ | Category _ | Subcategory _ -> true
  in
  Node.div
    ~attrs:[ Attr.class_ "app-shell" ]
    [ Node.header
        ~attrs:[ Attr.class_ "topbar" ]
        [ Node.create
            "nav"
            ~attrs:[ Attr.class_ "section-tabs" ]
            (List.map Content_area.all ~f:(area_button ~route ~set_route))
        ; Node.create
            "nav"
            ~attrs:[ Attr.class_ "locale-tabs" ]
            (List.map Locale.all ~f:(locale_button ~route ~set_route ~posts:all_posts))
        ]
    ; Node.main
        ~attrs:[ Attr.class_ "page-grid" ]
        [ (match route with
           | Route.Index _ ->
             let categories =
               posts
               |> List.map ~f:(fun (post : Post.t) -> post.category)
               |> unique_sorted
             in
             Node.section
               ~attrs:[ Attr.class_ "main-copy" ]
               [ section_header context
               ; Node.div
                   ~attrs:[ Attr.class_ "browse-list" ]
                   (List.map categories ~f:(category_card ~set_route ~context ~posts))
               ]
           | Route.Category { category; _ } ->
             category_page ~set_route ~context ~posts category
           | Route.Subcategory { category; subcategory; _ } ->
             subcategory_page ~set_route ~context ~posts ~category ~subcategory
           | Route.Article article_route ->
             let post =
               List.find posts ~f:(fun post ->
                 Route.post_matches_article post article_route)
             in
             Node.create
               "article"
               ~attrs:[ Attr.class_ "article-page" ]
               [ article_header ~set_route article_route post
               ; article_body ~locale:context.locale ~article_exists article
               ])
        ; incremental_panel ~route ~article
        ]
    ]
;;
