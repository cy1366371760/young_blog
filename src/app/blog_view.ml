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

let post_card ~set_route (post : Post.t) =
  let hierarchy = String.concat [ post.category; post.subcategory ] ~sep:" / " in
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
               [ Date.to_string post.date; Section.short_label post.section; hierarchy ]
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
        (Route.Index article.section)
        ("Back to " ^ Section.short_label article.section)
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

let page ~route ~set_route ~posts ~article =
  let active_section = Route.section route in
  Node.div
    ~attrs:[ Attr.class_ "app-shell" ]
    [ Node.header
        ~attrs:[ Attr.class_ "topbar" ]
        [ Node.div ~attrs:[ Attr.class_ "brand" ] [ text "春树与类型" ]
        ; Node.create
            "nav"
            ~attrs:[ Attr.class_ "section-tabs" ]
            (List.map Section.all ~f:(section_button ~active_section ~set_route))
        ]
    ; Node.main
        ~attrs:[ Attr.class_ "page-grid" ]
        [ (match route with
           | Route.Index _ ->
             Node.section
               ~attrs:[ Attr.class_ "main-copy" ]
               [ Node.h1 [ text "把日常的细光，放进可维护的结构里。" ]
               ; Node.p [ text (Section.description active_section) ]
               ; Node.div
                   ~attrs:[ Attr.class_ "tools-row" ]
                   [ Node.div
                       ~attrs:[ Attr.class_ "searchbox" ]
                       [ text "Search and tag filters land in the next step." ]
                   ; Node.div
                       ~attrs:[ Attr.class_ "tags" ]
                       [ tag_chip "OCaml"; tag_chip "Bonsai"; tag_chip "随记" ]
                   ]
               ; Node.div
                   ~attrs:[ Attr.class_ "article-list" ]
                   (List.map posts ~f:(post_card ~set_route))
               ]
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
