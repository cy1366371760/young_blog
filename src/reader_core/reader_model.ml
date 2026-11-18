open! Core

module Search = struct
  let matches ~query ~tag ~title ~summary ~tags =
    let haystack = String.lowercase (String.concat (title :: summary :: tags) ~sep:" ") in
    let words = String.split_on_chars (String.lowercase query) ~on:[ ' '; '\t'; '\n' ] in
    List.for_all words ~f:(fun word -> String.is_substring haystack ~substring:word)
    && Option.value_map tag ~default:true ~f:(fun tag ->
      List.mem tags tag ~equal:String.equal)
  ;;

  let%expect_test "search combines words and an exact tag" =
    let matches query tag =
      matches ~query ~tag ~title:"Learning OCaml" ~summary:"学习 Bonsai" ~tags:[ "notes" ]
      |> Bool.to_string
      |> print_endline
    in
    matches "ocaml Bonsai" None;
    matches "学习" (Some "notes");
    matches "ocaml" (Some "note");
    matches "rust" None;
    [%expect
      {|
      true
      true
      false
      false
      |}]
  ;;
end

module Load = struct
  type status =
    | No_article
    | Loading
    | Loaded of string
    | Failed of string
  [@@deriving equal, sexp]

  type t =
    { request_id : int
    ; path : string option
    ; status : status
    }
  [@@deriving equal, sexp]

  type action =
    | Start of int * string option
    | Finish of int * (string, string) Result.t
  [@@deriving sexp]

  let empty = { request_id = 0; path = None; status = No_article }

  let apply model = function
    | Start (request_id, path) ->
      { request_id; path; status = (if Option.is_some path then Loading else No_article) }
    | Finish (request_id, result) ->
      if request_id <> model.request_id
      then model
      else
        { model with
          status =
            (match result with
             | Ok html -> Loaded html
             | Error e -> Failed e)
        }
  ;;

  let%expect_test "A B A navigation rejects an older response for the same article" =
    let model = apply empty (Start (1, Some "A")) in
    let model = apply model (Start (2, Some "B")) in
    let model = apply model (Start (3, Some "A")) in
    let model = apply model (Finish (1, Ok "old A")) in
    print_s [%sexp (model : t)];
    let model = apply model (Finish (3, Ok "new A")) in
    let model = apply model (Finish (2, Error "late failure")) in
    print_s [%sexp (model : t)];
    [%expect
      {|
      ((request_id 3) (path (A)) (status Loading))
      ((request_id 3) (path (A)) (status (Loaded "new A")))
      |}]
  ;;
end
