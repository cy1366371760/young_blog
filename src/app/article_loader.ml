open! Core
open! Bonsai_web.Cont
open! Bonsai.Let_syntax
module Load = Reader_model.Load

type t = Load.status =
  | No_article
  | Loading
  | Loaded of string
  | Failed of string
[@@deriving equal, sexp]

let component article_path ~revision graph =
  let next_request = ref 0 in
  let model, inject =
    Bonsai.state_machine0
      ~sexp_of_model:Load.sexp_of_t
      ~sexp_of_action:Load.sexp_of_action
      ~equal:Load.equal
      ~default_model:Load.empty
      ~apply_action:(fun _ model action -> Load.apply model action)
      graph
  in
  let callback =
    let%arr inject = inject in
    fun (path, _revision) ->
      incr next_request;
      let request_id = !next_request in
      let open Effect.Let_syntax in
      let%bind () = inject (Load.Start (request_id, path)) in
      match path with
      | None -> Effect.Ignore
      | Some path ->
        let%bind result = Effect.of_deferred_fun Reader_platform.read_article path in
        inject (Load.Finish (request_id, result))
  in
  Bonsai.Edge.on_change
    ~equal:[%equal: string option * int]
    (Bonsai.both article_path revision)
    ~callback
    graph;
  let%arr model = model
  and path = article_path in
  if Option.equal String.equal model.path path
  then model.status
  else if Option.is_some path
  then Loading
  else No_article
;;
