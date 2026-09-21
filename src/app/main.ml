open! Core
open! Bonsai_web.Cont
open! Bonsai.Let_syntax

let app graph =
  let posts = Post.load () in
  let route = Bonsai_web_ui_url_var.value Route.url_var in
  let set_route = Bonsai.return (Bonsai_web_ui_url_var.set_effect Route.url_var) in
  let visible_posts =
    let%arr route = route in
    let context = Route.context route in
    let area = context.area in
    let locale = context.locale in
    Post.visible_in posts ~area ~locale
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
  and article = article in
  Blog_view.page ~route ~set_route ~posts:visible_posts ~all_posts:posts ~article
;;

let () = Bonsai_web.Start.start app
