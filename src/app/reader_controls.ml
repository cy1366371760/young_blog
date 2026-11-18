open! Core
open Bonsai_web.Cont
open Bonsai.Let_syntax

type t =
  { query : string
  ; tag : string option
  ; saved_only : bool
  ; saved : string list
  ; font_size : int
  ; theme : string
  }
[@@deriving equal, sexp]

type action =
  | Query of string
  | Tag of string option
  | Saved_only of bool
  | Toggle_saved of string
  | Font of int
  | Theme of string
  | Clear_filters
[@@deriving sexp]

let saved_key (post : Post.t) =
  Content_area.path_segment post.area ^ ":" ^ post.translation_key
;;

let is_saved model post = List.mem model.saved (saved_key post) ~equal:String.equal

let apply_action _ model = function
  | Query query -> { model with query }
  | Tag tag -> { model with tag }
  | Saved_only saved_only -> { model with saved_only }
  | Toggle_saved key ->
    let saved =
      if List.mem model.saved key ~equal:String.equal
      then List.filter model.saved ~f:(fun value -> not (String.equal value key))
      else key :: model.saved
    in
    { model with saved }
  | Font font_size -> { model with font_size = Int.max 15 (Int.min 26 font_size) }
  | Theme theme -> { model with theme }
  | Clear_filters -> { model with query = ""; tag = None; saved_only = false }
;;

let component graph =
  let saved =
    try
      Reader_platform.get "saved" ~default:"()"
      |> Sexp.of_string
      |> [%of_sexp: string list]
    with
    | _ -> []
  in
  let font_size =
    Reader_platform.get "font" ~default:"18"
    |> Int.of_string_opt
    |> Option.value ~default:18
    |> Int.max 15
    |> Int.min 26
  in
  let model, inject =
    Bonsai.state_machine0
      ~sexp_of_model:sexp_of_t
      ~sexp_of_action
      ~equal
      ~default_model:
        { query = ""
        ; tag = None
        ; saved_only = false
        ; saved
        ; font_size
        ; theme = Reader_platform.get "theme" ~default:"system"
        }
      ~apply_action
      graph
  in
  let preferences =
    let%arr model = model in
    model.saved, model.font_size, model.theme
  in
  Bonsai.Edge.on_change
    ~equal:[%equal: string list * int * string]
    preferences
    ~callback:
      (Bonsai.return (fun (saved, font_size, theme) ->
         Effect.of_sync_fun
           (fun () ->
              Reader_platform.set "saved" (Sexp.to_string [%sexp (saved : string list)]);
              Reader_platform.font font_size;
              Reader_platform.theme theme)
           ()))
    graph;
  model, inject
;;
