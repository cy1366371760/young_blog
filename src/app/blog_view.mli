open! Core
open Bonsai_web.Cont

val page
  :  route:Route.t
  -> set_route:(Route.t -> unit Effect.t)
  -> posts:Post.t list
  -> navigation_posts:Post.t list
  -> all_posts:Post.t list
  -> article:Article_loader.t
  -> controls:Reader_controls.t
  -> inject:(Reader_controls.action -> unit Effect.t)
  -> Vdom.Node.t
