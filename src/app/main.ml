open! Core
open! Bonsai_web.Cont
open! Bonsai.Let_syntax

let app graph =
  let posts = Post.load () in
  let route = Bonsai_web_ui_url_var.value Route.url_var in
  let set_route = Bonsai.return (Bonsai_web_ui_url_var.set_effect Route.url_var) in
  let visible_posts =
    let%arr route = route in
    Post.visible_in posts ~section:(Route.section route)
  in
  let article_path =
    let%arr route = route in
    Route.article_asset_path_for_route route
  in
  let article = Article_loader.component article_path graph in
  let%arr route = route
  and set_route = set_route
  and visible_posts = visible_posts
  and article = article in
  Blog_view.page ~route ~set_route ~posts:visible_posts ~article
;;

let () = Bonsai_web.Start.start app
