open! Core
open Bonsai_web.Cont
module Js = Js_of_ocaml.Js

let call name args =
  let bridge = Js.Unsafe.get Js.Unsafe.global "BlogReader" in
  Js.Unsafe.meth_call bridge name args
;;

let string value = Js.Unsafe.inject (Js.string value)
let get key ~default = Js.to_string (call "get" [| string key; string default |])
let set key value = ignore (call "set" [| string key; string value |] : Js.Unsafe.any)
let font size = ignore (call "font" [| Js.Unsafe.inject size |] : Js.Unsafe.any)
let theme value = ignore (call "theme" [| string value |] : Js.Unsafe.any)
let sync = Effect.of_sync_fun (fun () -> ignore (call "sync" [||] : Js.Unsafe.any)) ()

let share ~path ~title =
  Effect.of_sync_fun
    (fun () -> ignore (call "share" [| string path; string title |] : Js.Unsafe.any))
    ()
;;

let route ~path ~lang ~title =
  Effect.of_sync_fun
    (fun () ->
       ignore (call "route" [| string path; string lang; string title |] : Js.Unsafe.any))
    ()
;;

let read_article path =
  let result = Async_kernel.Ivar.create () in
  let callback success text =
    let text = Js.to_string text in
    Async_kernel.Ivar.fill_if_empty
      result
      (if Js.to_bool success then Ok text else Error text)
  in
  ignore
    (call "readArticle" [| string path; Js.Unsafe.inject (Js.wrap_callback callback) |]
     : Js.Unsafe.any);
  Async_kernel.Ivar.read result
;;

let subscribe_index callback =
  ignore
    (call "subscribeIndex" [| Js.Unsafe.inject (Js.wrap_callback callback) |]
     : Js.Unsafe.any)
;;

let subscribe_route callback =
  let callback path = callback (Js.to_string path) in
  ignore
    (call "subscribeRoute" [| Js.Unsafe.inject (Js.wrap_callback callback) |]
     : Js.Unsafe.any)
;;
