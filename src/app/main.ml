open! Core
module Bonsai_core = Bonsai
open! Bonsai_web.Cont
open! Bonsai.Let_syntax

let app graph =
  let posts = Post.load () in
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
    let%arr context = context in
    let area = context.area in
    let locale = context.locale in
    Post.visible_in posts ~area ~locale
  in
  let filtered_posts =
    let%arr route = route
    and visible_posts = visible_posts in
    List.filter visible_posts ~f:(fun (post : Post.t) ->
      match route with
      | Route.Index _ | Article _ -> true
      | Category { category; _ } -> String.equal post.category category
      | Subcategory { category; subcategory; _ } ->
        String.equal post.category category && String.equal post.subcategory subcategory)
    |> List.sort ~compare:(fun (left : Post.t) right -> Date.compare right.date left.date)
  in
  let article_path =
    let%arr route = route in
    match route with
    | Route.Article article
      when List.exists posts ~f:(fun post -> Route.post_matches_article post article) ->
      Route.article_asset_path_for_route route
    | Index _ | Category _ | Subcategory _ | Article _ -> None
  in
  let article = Article_loader.component article_path graph in
  let%arr route = route
  and set_route = set_route
  and visible_posts = visible_posts
  and filtered_posts = filtered_posts
  and article = article in
  Blog_view.page
    ~route
    ~set_route
    ~posts:filtered_posts
    ~navigation_posts:visible_posts
    ~all_posts:posts
    ~article
;;

let () = Bonsai_web.Start.start app
