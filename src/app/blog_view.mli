open! Core
open Bonsai_web.Cont

val page
  :  active_section:Section.t
  -> set_active_section:(Section.t -> unit Effect.t)
  -> posts:Post.t list
  -> Vdom.Node.t
