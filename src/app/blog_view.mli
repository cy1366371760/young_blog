open! Core
open Bonsai_web.Cont

val page
  :  route:Route.t
  -> set_route:(Route.t -> unit Effect.t)
  -> posts:Post.t list
  -> article:Article_loader.t
  -> Vdom.Node.t
