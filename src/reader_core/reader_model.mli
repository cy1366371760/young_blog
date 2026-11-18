open! Core

module Search : sig
  val matches
    :  query:string
    -> tag:string option
    -> title:string
    -> summary:string
    -> tags:string list
    -> bool
end

module Load : sig
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

  val empty : t
  val apply : t -> action -> t
end
