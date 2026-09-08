open! Core
open Bonsai_web.Cont
module Attr = Vdom.Attr
module Node = Vdom.Node

let classes names = Attr.class_ (String.concat names ~sep:" ")
let text = Node.text

let section_button ~active_section ~set_route section =
  let is_active = Section.equal active_section section in
  Bonsai_web_ui_nav_link.make
    ~attrs:[ classes [ "section-tab"; (if is_active then "is-active" else "") ] ]
    ~set_url:set_route
    ~page_to_string:Route.to_path
    (Route.Index section)
    (Section.label section)
;;

let tag_chip tag = Node.span ~attrs:[ Attr.class_ "tag-chip" ] [ text tag ]

let path_segment_label = function
  | "ocaml" -> "OCaml"
  | "ocaml-learning" -> "OCaml Learning"
  | "ocaml-in-atcoder" -> "OCaml in AtCoder"
  | "bonsai" -> "Bonsai"
  | "incremental" -> "Incremental"
  | "notes" -> "Notes"
  | "daily" -> "Daily"
  | segment -> String.substr_replace_all segment ~pattern:"-" ~with_:" "
;;

let unique_sorted values = List.dedup_and_sort values ~compare:String.compare

let posts_in_category posts category =
  List.filter posts ~f:(fun (post : Post.t) -> String.equal post.category category)
;;

let posts_in_subcategory posts category subcategory =
  List.filter posts ~f:(fun (post : Post.t) ->
    String.equal post.category category && String.equal post.subcategory subcategory)
;;

let category_card ~set_route ~section ~posts category =
  let category_posts = posts_in_category posts category in
  let note_count = List.length category_posts in
  let subcategory_count =
    List.map category_posts ~f:(fun (post : Post.t) -> post.subcategory)
    |> unique_sorted
    |> List.length
  in
  Node.create
    "article"
    ~attrs:[ Attr.class_ "browse-card" ]
    [ Bonsai_web_ui_nav_link.make
        ~attrs:[ Attr.class_ "browse-card-title" ]
        ~set_url:set_route
        ~page_to_string:Route.to_path
        (Route.Category { section; category })
        (path_segment_label category)
    ; Node.div
        ~attrs:[ Attr.class_ "browse-card-meta" ]
        [ text
            [%string "%{subcategory_count#Int} subcategories · %{note_count#Int} notes"]
        ]
    ]
;;

let subcategory_card ~set_route ~section ~category ~posts subcategory =
  let note_count = List.length (posts_in_subcategory posts category subcategory) in
  Node.create
    "article"
    ~attrs:[ Attr.class_ "browse-card" ]
    [ Bonsai_web_ui_nav_link.make
        ~attrs:[ Attr.class_ "browse-card-title" ]
        ~set_url:set_route
        ~page_to_string:Route.to_path
        (Route.Subcategory { section; category; subcategory })
        (path_segment_label subcategory)
    ; Node.div
        ~attrs:[ Attr.class_ "browse-card-meta" ]
        [ text [%string "%{note_count#Int} notes"] ]
    ]
;;

let post_card ~set_route (post : Post.t) =
  Node.create
    "article"
    ~attrs:[ Attr.class_ "post-card" ]
    [ Bonsai_web_ui_nav_link.make
        ~attrs:[ Attr.class_ "post-title" ]
        ~set_url:set_route
        ~page_to_string:Route.to_path
        (Route.of_post post)
        post.title
    ; Node.div
        ~attrs:[ Attr.class_ "post-meta" ]
        [ text
            (String.concat
               [ Date.to_string post.date; Section.short_label post.section ]
               ~sep:" · ")
        ]
    ; Node.p ~attrs:[ Attr.class_ "post-summary" ] [ text post.summary ]
    ; Node.div ~attrs:[ Attr.class_ "post-tags" ] (List.map post.tags ~f:tag_chip)
    ]
;;

let graph_node ~status label =
  Node.div ~attrs:[ classes [ "graph-node"; status ] ] [ text label ]
;;

let incremental_panel ~route ~article =
  let active_section = Route.section route in
  let section_name = Section.short_label active_section in
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
    [ Node.h2 [ text "Incremental Trace" ]
    ; Node.div
        ~attrs:[ Attr.class_ "graph-grid" ]
        [ graph_node ~status:"is-cold" "all posts"
        ; graph_node ~status:"is-hot" section_name
        ; graph_node ~status:"is-warm" route_status
        ; graph_node ~status:"is-hot" "filter"
        ; graph_node ~status:"is-warm" "sort"
        ; graph_node ~status:"is-hot" load_status
        ]
    ; Node.div
        ~attrs:[ Attr.class_ "comments-slot" ]
        [ text
            "Comments boundary reserved: article id, provider adapter, moderation state."
        ]
    ]
;;

let article_header ~set_route (article : Route.article) (post : Post.t option) =
  let title =
    Option.value_map post ~default:article.slug ~f:(fun (post : Post.t) -> post.title)
  in
  let summary =
    Option.value_map post ~default:"" ~f:(fun (post : Post.t) -> post.summary)
  in
  Node.div
    ~attrs:[ Attr.class_ "article-header" ]
    [ Bonsai_web_ui_nav_link.make
        ~attrs:[ Attr.class_ "back-link" ]
        ~set_url:set_route
        ~page_to_string:Route.to_path
        (Route.Subcategory
           { section = article.section
           ; category = article.category
           ; subcategory = article.subcategory
           })
        ("Back to " ^ path_segment_label article.subcategory)
    ; Node.h1 [ text title ]
    ; (if String.is_empty summary
       then Node.none
       else Node.p ~attrs:[ Attr.class_ "article-lede" ] [ text summary ])
    ]
;;

let article_body article =
  match article with
  | Article_loader.No_article -> Node.none
  | Article_loader.Loading ->
    Node.div ~attrs:[ Attr.class_ "article-state" ] [ text "Loading article..." ]
  | Article_loader.Failed message ->
    Node.div ~attrs:[ classes [ "article-state"; "is-error" ] ] [ text message ]
  | Article_loader.Loaded html ->
    (* The build script escapes Markdown before producing this HTML. *)
    Node.inner_html
      ~tag:"div"
      ~attrs:[ Attr.class_ "article-body" ]
      ~this_html_is_sanitized_and_is_totally_safe_trust_me:html
      ()
;;

let back_link ~set_route route label =
  Bonsai_web_ui_nav_link.make
    ~attrs:[ Attr.class_ "back-link" ]
    ~set_url:set_route
    ~page_to_string:Route.to_path
    route
    label
;;

let section_header section =
  Node.div
    ~attrs:[ Attr.class_ "section-header" ]
    [ Node.div ~attrs:[ Attr.class_ "section-kicker" ] [ text "Library" ]
    ; Node.h1 [ text (Section.label section) ]
    ; Node.p [ text (Section.description section) ]
    ]
;;

let category_page ~set_route ~section ~posts category =
  let subcategories =
    posts_in_category posts category
    |> List.map ~f:(fun (post : Post.t) -> post.subcategory)
    |> unique_sorted
  in
  Node.section
    ~attrs:[ Attr.class_ "main-copy" ]
    [ back_link ~set_route (Route.Index section) ("Back to " ^ Section.label section)
    ; Node.div
        ~attrs:[ Attr.class_ "section-header" ]
        [ Node.div ~attrs:[ Attr.class_ "section-kicker" ] [ text "Category" ]
        ; Node.h1 [ text (path_segment_label category) ]
        ; Node.p [ text "Choose a topic to see its notes." ]
        ]
    ; Node.div
        ~attrs:[ Attr.class_ "browse-list" ]
        (List.map
           subcategories
           ~f:(subcategory_card ~set_route ~section ~category ~posts))
    ]
;;

let subcategory_page ~set_route ~section ~posts ~category ~subcategory =
  let notes = posts_in_subcategory posts category subcategory in
  Node.section
    ~attrs:[ Attr.class_ "main-copy" ]
    [ back_link
        ~set_route
        (Route.Category { section; category })
        ("Back to " ^ path_segment_label category)
    ; Node.div
        ~attrs:[ Attr.class_ "section-header" ]
        [ Node.div
            ~attrs:[ Attr.class_ "section-kicker" ]
            [ text (path_segment_label category) ]
        ; Node.h1 [ text (path_segment_label subcategory) ]
        ; Node.p [ text "Problem notes, implementations, and reflections." ]
        ]
    ; Node.div
        ~attrs:[ Attr.class_ "article-list" ]
        (List.map notes ~f:(post_card ~set_route))
    ]
;;

let page ~route ~set_route ~posts ~article =
  let active_section = Route.section route in
  Node.div
    ~attrs:[ Attr.class_ "app-shell" ]
    [ Node.header
        ~attrs:[ Attr.class_ "topbar" ]
        [ Node.create
            "nav"
            ~attrs:[ Attr.class_ "section-tabs" ]
            (List.map Section.all ~f:(section_button ~active_section ~set_route))
        ]
    ; Node.main
        ~attrs:[ Attr.class_ "page-grid" ]
        [ (match route with
           | Route.Index section ->
             let categories =
               posts
               |> List.map ~f:(fun (post : Post.t) -> post.category)
               |> unique_sorted
             in
             Node.section
               ~attrs:[ Attr.class_ "main-copy" ]
               [ section_header section
               ; Node.div
                   ~attrs:[ Attr.class_ "browse-list" ]
                   (List.map categories ~f:(category_card ~set_route ~section ~posts))
               ]
           | Route.Category { section; category } ->
             category_page ~set_route ~section ~posts category
           | Route.Subcategory { section; category; subcategory } ->
             subcategory_page ~set_route ~section ~posts ~category ~subcategory
           | Route.Article article_route ->
             let post =
               List.find posts ~f:(fun post ->
                 Route.post_matches_article post article_route)
             in
             Node.create
               "article"
               ~attrs:[ Attr.class_ "article-page" ]
               [ article_header ~set_route article_route post; article_body article ])
        ; incremental_panel ~route ~article
        ]
    ]
;;
