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

let action_button ?(active = false) ~label ~on_click () =
  Node.button
    ~attrs:
      [ Attr.class_ (if active then "reader-button is-active" else "reader-button")
      ; Attr.type_ "button"
      ; Attr.on_click (fun _ -> on_click)
      ; Attr.create "aria-pressed" (Bool.to_string active)
      ]
    [ text label ]
;;

let post_card ~set_route ~controls ~inject (post : Post.t) =
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
    ; Node.div
        ~attrs:[ Attr.class_ "card-footer" ]
        [ Node.div ~attrs:[ Attr.class_ "post-tags" ] (List.map post.tags ~f:tag_chip)
        ; action_button
            ~active:(Reader_controls.is_saved controls post)
            ~label:
              (let copy = Reader_copy.for_locale post.locale in
               if Reader_controls.is_saved controls post then copy.saved else copy.save)
            ~on_click:
              (inject (Reader_controls.Toggle_saved (Reader_controls.saved_key post)))
            ()
        ]
    ]
;;

let route_selects_category route category =
  match route with
  | Route.Category selected -> String.equal selected.category category
  | Subcategory selected -> String.equal selected.category category
  | Article selected -> String.equal selected.category category
  | Index _ -> false
;;

let route_selects_subcategory route category subcategory =
  match route with
  | Route.Subcategory selected ->
    String.equal selected.category category
    && String.equal selected.subcategory subcategory
  | Article selected ->
    String.equal selected.category category
    && String.equal selected.subcategory subcategory
  | Index _ | Category _ -> false
;;

let category_navigation ~route ~set_route ~posts =
  let context = Route.context route in
  let area = context.area in
  let locale = context.locale in
  let copy = Copy.for_locale locale in
  let categories =
    List.map posts ~f:(fun (post : Post.t) -> post.category) |> unique_sorted
  in
  Node.create
    "aside"
    ~attrs:[ Attr.class_ "category-navigation" ]
    [ Node.h2 [ text copy.browse ]
    ; nav_link
        ~classes:
          (classes
             [ "category-navigation-all"
             ; (match route with
                | Route.Index _ -> "is-active"
                | Category _ | Subcategory _ | Article _ -> "")
             ])
        ~set_route
        (Route.Index context)
        [%string "%{copy.all_articles} · %{List.length posts#Int}"]
    ; Node.div
        ~attrs:[ Attr.class_ "category-navigation-groups" ]
        (List.map categories ~f:(fun category ->
           let category_posts = posts_in_category posts category in
           let subcategories =
             List.map category_posts ~f:(fun (post : Post.t) -> post.subcategory)
             |> unique_sorted
           in
           Node.section
             ~attrs:[ Attr.class_ "category-navigation-group" ]
             [ nav_link
                 ~classes:
                   (classes
                      [ "category-navigation-primary"
                      ; (if route_selects_category route category then "is-active" else "")
                      ])
                 ~set_route
                 (Route.Category { area; locale; category })
                 [%string
                   "%{Copy.path_segment_label locale category} · %{List.length \
                    category_posts#Int}"]
             ; Node.div
                 ~attrs:[ Attr.class_ "category-navigation-secondary" ]
                 (List.map subcategories ~f:(fun subcategory ->
                    let note_count =
                      List.length (posts_in_subcategory posts category subcategory)
                    in
                    nav_link
                      ~classes:
                        (classes
                           [ "category-navigation-link"
                           ; (if route_selects_subcategory route category subcategory
                              then "is-active"
                              else "")
                           ])
                      ~set_route
                      (Route.Subcategory { area; locale; category; subcategory })
                      [%string
                        "%{Copy.path_segment_label locale subcategory} · \
                         %{note_count#Int}"]))
             ]))
    ]
;;

let back_link ~set_route route label =
  nav_link ~classes:(Attr.class_ "back-link") ~set_route route label
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

let article_list_header ~(context : Route.context) route note_count =
  let locale = context.locale in
  let copy = Copy.for_locale locale in
  let kicker, title, description =
    match route with
    | Route.Index _ ->
      ( copy.library
      , Copy.area_label locale context.area
      , Copy.area_description locale context.area )
    | Category { category; _ } ->
      copy.category, Copy.path_segment_label locale category, copy.browse_topic
    | Subcategory { category; subcategory; _ } ->
      ( Copy.path_segment_label locale category
      , Copy.path_segment_label locale subcategory
      , copy.browse_topic )
    | Article _ -> assert false
  in
  Node.div
    ~attrs:[ Attr.class_ "section-header" ]
    [ Node.div ~attrs:[ Attr.class_ "section-kicker" ] [ text kicker ]
    ; Node.h1 [ text title ]
    ; Node.p [ text description ]
    ; Node.div
        ~attrs:[ Attr.class_ "result-count" ]
        [ text (Copy.notes_count locale note_count) ]
    ]
;;

let filter_toolbar ~locale ~(controls : Reader_controls.t) ~inject ~posts =
  let copy = Reader_copy.for_locale locale in
  let tags =
    List.concat_map posts ~f:(fun (post : Post.t) -> post.tags) |> unique_sorted
  in
  Node.div
    ~attrs:[ Attr.class_ "filter-toolbar" ]
    [ Node.div
        ~attrs:[ Attr.class_ "search-field" ]
        [ Node.label ~attrs:[ Attr.for_ "article-search" ] [ text copy.search ]
        ; Node.input
            ~attrs:
              [ Attr.id "article-search"
              ; Attr.type_ "search"
              ; Attr.placeholder copy.search_hint
              ; Attr.value_prop controls.query
              ; Attr.create "autocomplete" "off"
              ; Attr.on_input (fun _ value -> inject (Reader_controls.Query value))
              ]
            ()
        ]
    ; Node.div
        ~attrs:[ Attr.class_ "library-tabs" ]
        [ action_button
            ~active:(not controls.saved_only)
            ~label:copy.all
            ~on_click:(inject (Reader_controls.Saved_only false))
            ()
        ; action_button
            ~active:controls.saved_only
            ~label:copy.only_saved
            ~on_click:(inject (Reader_controls.Saved_only true))
            ()
        ; action_button
            ~label:copy.clear
            ~on_click:(inject Reader_controls.Clear_filters)
            ()
        ]
    ; Node.div
        ~attrs:[ Attr.class_ "filter-tags"; Attr.create "aria-label" "Tags" ]
        (List.map tags ~f:(fun tag ->
           action_button
             ~active:(Option.equal String.equal controls.tag (Some tag))
             ~label:tag
             ~on_click:
               (inject
                  (Reader_controls.Tag
                     (if Option.equal String.equal controls.tag (Some tag)
                      then None
                      else Some tag)))
             ()))
    ]
;;

let article_list_page
      ~set_route
      ~(context : Route.context)
      ~route
      ~posts
      ~navigation_posts
      ~controls
      ~inject
  =
  Node.section
    ~attrs:[ Attr.class_ "main-copy" ]
    [ article_list_header ~context route (List.length posts)
    ; filter_toolbar ~locale:context.locale ~controls ~inject ~posts:navigation_posts
    ; (if List.is_empty posts
       then (
         let copy = Reader_copy.for_locale context.locale in
         Node.div
           ~attrs:[ Attr.class_ "empty-library" ]
           [ Node.h2 [ text copy.empty ]; Node.p [ text copy.empty_hint ] ])
       else
         Node.div
           ~attrs:[ Attr.class_ "article-list" ]
           (List.map posts ~f:(post_card ~set_route ~controls ~inject)))
    ]
;;

let reading_settings ~locale ~(controls : Reader_controls.t) ~inject =
  let copy = Reader_copy.for_locale locale in
  Node.create
    "details"
    ~attrs:[ Attr.class_ "reader-settings" ]
    [ Node.create
        "summary"
        ~attrs:[ Attr.create "aria-label" copy.settings ]
        [ text "Aa" ]
    ; Node.div
        ~attrs:[ Attr.class_ "settings-panel" ]
        [ Node.h2 [ text copy.settings ]
        ; Node.div
            ~attrs:[ Attr.class_ "font-controls" ]
            [ action_button
                ~label:"A−"
                ~on_click:(inject (Reader_controls.Font (controls.font_size - 1)))
                ()
            ; Node.span [ text (copy.font ^ " · " ^ Int.to_string controls.font_size) ]
            ; action_button
                ~label:"A+"
                ~on_click:(inject (Reader_controls.Font (controls.font_size + 1)))
                ()
            ]
        ; Node.div
            ~attrs:[ Attr.class_ "theme-controls" ]
            (List.map
               [ "system", copy.system; "light", copy.light; "dark", copy.dark ]
               ~f:(fun (theme, label) ->
                 action_button
                   ~active:(String.equal controls.theme theme)
                   ~label
                   ~on_click:(inject (Reader_controls.Theme theme))
                   ()))
        ; Node.p [ text copy.local ]
        ]
    ]
;;

let page ~route ~set_route ~posts ~navigation_posts ~all_posts ~article ~controls ~inject =
  let context = Route.context route in
  let copy = Reader_copy.for_locale context.locale in
  let post =
    match route with
    | Route.Article article ->
      List.find all_posts ~f:(fun post -> Route.post_matches_article post article)
    | Index _ | Category _ | Subcategory _ -> None
  in
  let navigation () = category_navigation ~route ~set_route ~posts:navigation_posts in
  Node.div
    ~attrs:[ Attr.class_ "app-shell" ]
    [ Node.header
        ~attrs:[ Attr.class_ "site-header" ]
        [ Node.div
            ~attrs:[ Attr.class_ "brand-row" ]
            [ nav_link
                ~classes:(Attr.class_ "brand")
                ~set_route
                (Route.Index context)
                "y / Young Blog"
            ; Node.div
                ~attrs:[ Attr.class_ "header-actions" ]
                [ action_button ~label:copy.refresh ~on_click:Reader_platform.sync ()
                ; reading_settings ~locale:context.locale ~controls ~inject
                ]
            ]
        ; Node.div
            ~attrs:[ Attr.class_ "topbar" ]
            [ Node.create
                "nav"
                ~attrs:[ Attr.class_ "section-tabs"; Attr.create "aria-label" "Sections" ]
                (List.map Content_area.all ~f:(area_button ~route ~set_route))
            ; Node.create
                "nav"
                ~attrs:[ Attr.class_ "locale-tabs"; Attr.create "aria-label" "Language" ]
                (List.map
                   Locale.all
                   ~f:(locale_button ~route ~set_route ~posts:all_posts))
            ]
        ]
    ; Node.div
        ~attrs:[ Attr.class_ "mobile-topics-wrap" ]
        [ Node.create
            "details"
            ~attrs:[ Attr.class_ "mobile-categories" ]
            [ Node.create "summary" [ text copy.categories ]; navigation () ]
        ]
    ; Node.main
        ~attrs:[ Attr.class_ "page-grid" ]
        [ (match route with
           | Route.Index _ | Category _ | Subcategory _ ->
             article_list_page
               ~set_route
               ~context
               ~route
               ~posts
               ~navigation_posts
               ~controls
               ~inject
           | Route.Article article_route ->
             Node.create
               "article"
               ~attrs:
                 [ Attr.class_ "article-page"
                 ; Attr.create "data-article-path" (Route.to_path route)
                 ]
               [ article_header ~set_route article_route post
               ; Node.div
                   ~attrs:[ Attr.class_ "article-actions" ]
                   [ (match post with
                      | None -> Node.none
                      | Some post ->
                        action_button
                          ~active:(Reader_controls.is_saved controls post)
                          ~label:
                            (if Reader_controls.is_saved controls post
                             then copy.saved
                             else copy.save)
                          ~on_click:
                            (inject
                               (Reader_controls.Toggle_saved
                                  (Reader_controls.saved_key post)))
                          ())
                   ; action_button
                       ~label:copy.share
                       ~on_click:
                         (Reader_platform.share
                            ~path:(Route.to_path route)
                            ~title:
                              (Option.value_map post ~default:"Young Blog" ~f:(fun p ->
                                 p.Post.title)))
                       ()
                   ]
               ; article_body
                   ~locale:context.locale
                   ~article_exists:(Option.is_some post)
                   article
               ; Node.div ~attrs:[ Attr.class_ "reading-end" ] [ text copy.reading ]
               ])
        ; Node.div ~attrs:[ Attr.class_ "desktop-topics" ] [ navigation () ]
        ]
    ; Node.footer
        ~attrs:[ Attr.class_ "site-footer" ]
        [ Node.span [ text "Young Blog" ]; Node.span [ text copy.offline ] ]
    ]
;;
