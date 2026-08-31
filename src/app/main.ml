open! Core
open! Bonsai_web.Cont
open! Bonsai.Let_syntax

let app graph =
  let active_section, set_active_section =
    Bonsai.state
      Section.Tech_en
      ~sexp_of_model:Section.sexp_of_t
      ~equal:Section.equal
      graph
  in
  let%arr active_section = active_section
  and set_active_section = set_active_section in
  Blog_view.page ~active_section ~set_active_section ~posts:Post.sample
;;

let () = Bonsai_web.Start.start app
