open! Core
open! Bonsai_web.Cont
open! Bonsai.Let_syntax
module Js = Js_of_ocaml.Js
module Xhr = Js_of_ocaml.XmlHttpRequest

type t =
  | No_article
  | Loading
  | Loaded of string
  | Failed of string
[@@deriving equal, sexp]

module Fetch_result = struct
  type t =
    { path : string option
    ; result : (string, string) Result.t
    }
  [@@deriving equal, sexp]
end

module Model = struct
  type nonrec t =
    { path : string option
    ; status : t
    }
  [@@deriving equal, sexp]
end

module Action = struct
  type t =
    | Start of string option
    | Finish of Fetch_result.t
  [@@deriving sexp]
end

let response_text request =
  let text : Js.js_string Js.t = Js.Unsafe.get request "responseText" in
  Js.to_string text
;;

let int_property request name = (Js.Unsafe.get request name : int)
let set_property request name value = Js.Unsafe.set request name value

let meth_call request name args =
  ignore (Js.Unsafe.meth_call request name args : Js.Unsafe.any)
;;

let fetch_path path =
  let open Async_kernel in
  let ivar = Ivar.create () in
  let request = Xhr.create () in
  let on_ready_state_change () =
    if int_property request "readyState" = 4
    then (
      let status = int_property request "status" in
      let result =
        if status >= 200 && status < 300
        then Ok (response_text request)
        else Error [%string "Could not load article: HTTP %{status#Int}"]
      in
      Ivar.fill_if_empty ivar { Fetch_result.path = Some path; result })
    else ()
  in
  let () =
    set_property
      request
      "onreadystatechange"
      (Js.Unsafe.inject (Js.wrap_callback on_ready_state_change))
  in
  let () =
    meth_call
      request
      "open"
      [| Js.Unsafe.inject (Js.string "GET")
       ; Js.Unsafe.inject (Js.string path)
       ; Js.Unsafe.inject (Js.bool true)
      |]
  in
  let () = meth_call request "send" [| Js.Unsafe.inject Js.null |] in
  Ivar.read ivar
;;

let fetch = function
  | None -> Async_kernel.Deferred.return { Fetch_result.path = None; result = Ok "" }
  | Some path -> fetch_path path
;;

let sexp_of_optional_string = function
  | None -> Sexp.Atom "None"
  | Some value -> Sexp.List [ Atom "Some"; Atom value ]
;;

let equal_optional_string = Option.equal String.equal

let apply_action _context (model : Model.t) = function
  | Action.Start None -> { Model.path = None; status = No_article }
  | Action.Start (Some path) -> { Model.path = Some path; status = Loading }
  | Action.Finish { path; result } ->
    if not (equal_optional_string model.path path)
    then model
    else (
      let status =
        match result with
        | Ok html -> Loaded html
        | Error message -> Failed message
      in
      { model with status })
;;

let load_after_start inject article_path =
  match article_path with
  | None -> inject (Action.Start None)
  | Some _ ->
    let open Bonsai_web.Effect.Let_syntax in
    let%bind () = inject (Action.Start article_path) in
    let%bind result = Bonsai_web.Effect.of_deferred_fun fetch article_path in
    inject (Action.Finish result)
;;

let component article_path graph =
  let model, inject =
    Bonsai.state_machine0
      ~sexp_of_model:Model.sexp_of_t
      ~sexp_of_action:Action.sexp_of_t
      ~equal:Model.equal
      ~default_model:{ Model.path = None; status = No_article }
      ~apply_action
      graph
  in
  let callback =
    let%arr inject = inject in
    load_after_start inject
  in
  Bonsai.Edge.on_change
    ~sexp_of_model:sexp_of_optional_string
    ~equal:equal_optional_string
    article_path
    ~callback
    graph;
  let%arr model = model in
  model.status
;;
