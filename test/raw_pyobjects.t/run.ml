open! Base
open Lib
open Stdio

let () = Py.initialize ()

let () =
  print_endline @@ Int.to_string @@ Py.Int.to_int
  @@ Silly.concat1 ~x:(Py.Int.of_int 1) ~y:(Py.Int.of_int 2) ()

let () =
  print_endline @@ Int.to_string @@ Py.Int.to_int
  @@ Silly.concat2 ~x:(Py.Int.of_int 1) ~y:(Py.Int.of_int 2) ()

let () =
  print_endline @@ Py.String.to_string
  @@ Silly.concat1
       ~x:(Py.String.of_string "apple ")
       ~y:(Py.String.of_string "pie")
       ()

let () =
  print_endline @@ Py.String.to_string
  @@ Silly.concat2
       ~x:(Py.String.of_string "apple ")
       ~y:(Py.String.of_string "pie")
       ()

let () =
  print_endline @@ Int.to_string @@ Silly.concat3 ~x:1 ~y:(Py.Int.of_int 2) ()

let () = print_endline "Watch out for type errors...."

let () =
  print_s @@ [%sexp_of: string Or_error.t]
  @@ Or_error.try_with (fun () ->
         Py.String.to_string
         @@ Silly.concat2 ~x:(Py.Int.of_int 1)
              ~y:(Py.String.of_string " pie")
              ())

let () = print_endline "done"
