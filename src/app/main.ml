open! Core
module Bonsai_core = Bonsai
open! Bonsai_web.Cont
open! Bonsai.Let_syntax

let app graph =
  let catalog, update_catalog =
    Bonsai.state_machine0
      ~default_model:(Post.load (), 0)
      ~apply_action:(fun _ (_, revision) posts -> posts, revision + 1)
      graph
  in
  let on_activate =
    let%arr update_catalog = update_catalog in
    Effect.of_sync_fun
      (fun () ->
         Reader_platform.subscribe_index (fun () ->
           Vdom.Effect.Expert.handle_non_dom_event_exn (update_catalog (Post.load ())));
         Reader_platform.subscribe_route (fun path ->
           match Route.of_path path with
           | Error _ -> ()
           | Ok route ->
             Vdom.Effect.Expert.handle_non_dom_event_exn
               (Bonsai_web_ui_url_var.set_effect Route.url_var route)))
      ()
  in
  Bonsai.Edge.lifecycle ~on_activate graph;
  let posts =
    let%arr posts, _ = catalog in
    posts
  in
  let revision =
    let%arr _, revision = catalog in
    revision
  in
  let controls, inject = Reader_controls.component graph in
  let route = Bonsai_web_ui_url_var.value Route.url_var in
  let set_route = Bonsai.return (Bonsai_web_ui_url_var.set_effect Route.url_var) in
  let context =
    let context =
      let%arr route = route in
      Route.context route
    in
    Bonsai_core.Value.cutoff context ~equal:Route.equal_context
  in
  let visible_posts =
    let%arr context = context
    and posts = posts in
    Post.visible_in posts ~area:context.area ~locale:context.locale
  in
  let filter_spec =
    let spec =
      let%arr (controls : Reader_controls.t) = controls in
      controls.query, controls.tag, controls.saved_only, controls.saved
    in
    Bonsai_core.Value.cutoff
      spec
      ~equal:[%equal: string * string option * bool * string list]
  in
  let filtered_posts =
    let%arr route = route
    and visible_posts = visible_posts
    and query, tag, saved_only, saved = filter_spec in
    List.filter visible_posts ~f:(fun (post : Post.t) ->
      match route with
      | Route.Article _ -> true
      | Index _ | Category _ | Subcategory _ ->
        let in_category =
          match route with
          | Route.Category { category; _ } -> String.equal post.category category
          | Subcategory { category; subcategory; _ } ->
            String.equal post.category category
            && String.equal post.subcategory subcategory
          | Index _ | Article _ -> true
        in
        in_category
        && ((not saved_only)
            || List.mem saved (Reader_controls.saved_key post) ~equal:String.equal)
        && Reader_model.Search.matches
             ~query
             ~tag
             ~title:post.title
             ~summary:post.summary
             ~tags:post.tags)
    |> List.sort ~compare:(fun (left : Post.t) right -> Date.compare right.date left.date)
  in
  let article_path =
    let%arr route = route
    and posts = posts in
    match route with
    | Route.Article article
      when List.exists posts ~f:(fun post -> Route.post_matches_article post article) ->
      Route.article_asset_path_for_route route
    | Index _ | Category _ | Subcategory _ | Article _ -> None
  in
  let article = Article_loader.component article_path ~revision graph in
  let document_info =
    let%arr route = route
    and posts = posts in
    let context = Route.context route in
    let lang =
      match context.locale with
      | Locale.En -> "en"
      | Zh_hans -> "zh-Hans"
      | Zh_hant -> "zh-Hant"
    in
    let title =
      match route with
      | Route.Article article ->
        List.find posts ~f:(fun post -> Route.post_matches_article post article)
        |> Option.value_map ~default:"Young Blog" ~f:(fun post -> post.Post.title)
      | Index _ | Category _ | Subcategory _ ->
        Copy.area_label context.locale context.area
    in
    Route.to_path route, lang, title
  in
  Bonsai.Edge.on_change
    ~equal:[%equal: string * string * string]
    document_info
    ~callback:
      (Bonsai.return (fun (path, lang, title) -> Reader_platform.route ~path ~lang ~title))
    graph;
  let%arr route = route
  and set_route = set_route
  and visible_posts = visible_posts
  and filtered_posts = filtered_posts
  and posts = posts
  and article = article
  and controls = controls
  and inject = inject in
  Blog_view.page
    ~route
    ~set_route
    ~posts:filtered_posts
    ~navigation_posts:visible_posts
    ~all_posts:posts
    ~article
    ~controls
    ~inject
;;

let () = Bonsai_web.Start.start app
