open! Core
open Bonsai_web.Cont

val get : string -> default:string -> string
val set : string -> string -> unit
val font : int -> unit
val theme : string -> unit
val sync : unit Effect.t
val share : path:string -> title:string -> unit Effect.t
val route : path:string -> lang:string -> title:string -> unit Effect.t
val read_article : string -> (string, string) Result.t Async_kernel.Deferred.t
val subscribe_index : (unit -> unit) -> unit
val subscribe_route : (string -> unit) -> unit
