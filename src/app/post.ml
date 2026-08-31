open! Core

type t =
  { title : string
  ; section : Section.t
  ; category : string
  ; subcategory : string
  ; date : Date.t
  ; tags : string list
  ; summary : string
  ; slug : string
  }
[@@deriving sexp]

let date_exn s = Date.of_string s

let sample =
  [ { title = "Reading Incremental as a Spreadsheet Engine"
    ; section = Tech_en
    ; category = "ocaml"
    ; subcategory = "incremental"
    ; date = date_exn "2026-08-22"
    ; tags = [ "OCaml"; "Incremental"; "Bonsai" ]
    ; summary =
        "A first pass at self-adjusting computation through the lens of spreadsheet \
         cells."
    ; slug = "reading-incremental-as-a-spreadsheet-engine"
    }
  ; { title = "Building a Tag Index Without Rewalking the World"
    ; section = Tech_en
    ; category = "ocaml"
    ; subcategory = "bonsai"
    ; date = date_exn "2026-08-18"
    ; tags = [ "Bonsai"; "Search"; "Performance" ]
    ; summary =
        "The small data flow we will later turn into an Incremental computation trace."
    ; slug = "tag-index-without-rewalking"
    }
  ; { title = "夜里经过一座很安静的桥"
    ; section = Zh_notes
    ; category = "notes"
    ; subcategory = "daily"
    ; date = date_exn "2026-08-21"
    ; tags = [ "随记"; "城市"; "记忆" ]
    ; summary = "一点路灯、一段水声，以及一个人突然慢下来的时刻。"
    ; slug = "quiet-bridge-at-night"
    }
  ; { title = "未完成小说片段：石头的回信"
    ; section = Zh_notes
    ; category = "writing"
    ; subcategory = "fiction"
    ; date = date_exn "2026-08-16"
    ; tags = [ "文学创作"; "小说"; "草稿" ]
    ; summary = "先保存片段，不急着解释它；以后也许会长成一篇完整的故事。"
    ; slug = "stone-reply-fragment"
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

let visible_in posts ~section =
  List.filter posts ~f:(fun post -> Section.equal post.section section)
;;
