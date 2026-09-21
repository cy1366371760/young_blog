open! Core

type t =
  { title : string
  ; area : Content_area.t
  ; locale : Locale.t
  ; category : string
  ; subcategory : string
  ; date : Date.t
  ; tags : string list
  ; summary : string
  ; slug : string
  ; translation_key : string
  }
[@@deriving sexp]

let date_exn = Date.of_string

let sample =
  [ { title = "Bonsai first note"
    ; area = Content_area.Tech
    ; locale = Locale.En
    ; category = "ocaml"
    ; subcategory = "ocaml-learning"
    ; date = date_exn "2026-09-01"
    ; tags = [ "ocaml"; "bonsai"; "jane-street" ]
    ; summary = "A first placeholder note for the English technical section."
    ; slug = "bonsai-first-note"
    ; translation_key = "bonsai-first-note"
    }
  ; { title = "外出前的第一条记录"
    ; area = Content_area.Essays
    ; locale = Locale.Zh_hans
    ; category = "notes"
    ; subcategory = "daily"
    ; date = date_exn "2026-09-01"
    ; tags = [ "随记"; "外出" ]
    ; summary = "这是一篇中文区的占位随记。"
    ; slug = "first-travel-note"
    ; translation_key = "first-travel-note"
    }
  ]
;;

let load () =
  let open Js_of_ocaml in
  let raw : Js.js_string Js.t Js.optdef =
    Js.Unsafe.get Js.Unsafe.global "BLOG_POSTS_SEXP"
  in
  match Js.Optdef.to_option raw with
  | None -> sample
  | Some raw ->
    (try Sexp.of_string (Js.to_string raw) |> [%of_sexp: t list] with
     | _ -> sample)
;;

let visible_in posts ~area ~locale =
  List.filter posts ~f:(fun post ->
    Content_area.equal post.area area && Locale.equal post.locale locale)
;;
