open! Core
open Bonsai_web.Cont
module Attr = Vdom.Attr
module Node = Vdom.Node

let classes names = Attr.class_ (String.concat names ~sep:" ")
let text = Node.text

let section_button ~active_section ~set_active_section section =
  let is_active = Section.equal active_section section in
  Node.button
    ~attrs:
      [ classes [ "section-tab"; (if is_active then "is-active" else "") ]
      ; Attr.on_click (fun _ -> set_active_section section)
      ]
    [ text (Section.label section) ]
;;

let tag_chip tag = Node.span ~attrs:[ Attr.class_ "tag-chip" ] [ text tag ]

let post_card (post : Post.t) =
  let href = Section.path_prefix post.section ^ "/" ^ post.slug in
  let hierarchy = String.concat [ post.category; post.subcategory ] ~sep:" / " in
  Node.create
    "article"
    ~attrs:[ Attr.class_ "post-card" ]
    [ Node.a ~attrs:[ Attr.href href; Attr.class_ "post-title" ] [ text post.title ]
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

let incremental_panel ~active_section =
  let section_name = Section.short_label active_section in
  Node.create
    "aside"
    ~attrs:[ Attr.class_ "side-panel" ]
    [ Node.h2 [ text "Incremental Trace" ]
    ; Node.div
        ~attrs:[ Attr.class_ "graph-grid" ]
        [ graph_node ~status:"is-cold" "all posts"
        ; graph_node ~status:"is-hot" section_name
        ; graph_node ~status:"is-warm" "tags"
        ; graph_node ~status:"is-hot" "filter"
        ; graph_node ~status:"is-warm" "sort"
        ; graph_node ~status:"is-hot" "view"
        ]
    ; Node.div
        ~attrs:[ Attr.class_ "comments-slot" ]
        [ text
            "Comments boundary reserved: article id, provider adapter, moderation state."
        ]
    ]
;;

let page ~active_section ~set_active_section ~posts =
  let visible_posts = Post.visible_in posts ~section:active_section in
  Node.div
    ~attrs:[ Attr.class_ "app-shell" ]
    [ Node.header
        ~attrs:[ Attr.class_ "topbar" ]
        [ Node.div ~attrs:[ Attr.class_ "brand" ] [ text "春树与类型" ]
        ; Node.create
            "nav"
            ~attrs:[ Attr.class_ "section-tabs" ]
            (List.map Section.all ~f:(section_button ~active_section ~set_active_section))
        ]
    ; Node.main
        ~attrs:[ Attr.class_ "page-grid" ]
        [ Node.section
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
                (List.map visible_posts ~f:post_card)
            ]
        ; incremental_panel ~active_section
        ]
    ]
;;
