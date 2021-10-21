open! Base
open Lib
open Stdio

let () = Py.initialize ()

let silly = Or_error.ok_exn @@ Silly.__init__ ~x:1 ~y:2 ()

let () = print_endline ("x: " ^ Int.to_string (Silly.x silly))
let () = print_endline ("y: " ^ Int.to_string (Silly.y silly))
let () = print_endline ("foo: " ^ Int.to_string (Silly.foo silly ~a:10 ~b:20 ()))
let () = print_endline ("bar: " ^ Int.to_string (Silly.bar ~a:10 ~b:20 ()))

let () = Silly.do_nothing silly ()
let () = Silly.do_nothing2 ()

let () =
  print_endline
  @@ Sexp.to_string_hum ~indent:1
  @@ [%sexp_of: string list]
  @@ Silly.return_list silly ~l:[ "apple"; "pie" ] ()
let () =
  print_endline
  @@ Sexp.to_string_hum ~indent:1
  @@ [%sexp_of: string option list]
  @@ Silly.return_opt_list silly ~l:[ Some "apple"; None; Some "pie" ] ()

let () =
  print_endline
  @@ Sexp.to_string_hum ~indent:1
  @@ [%sexp_of: string array]
  @@ Silly.return_array silly ~a:[| "apple"; "pie" |] ()
let () =
  print_endline
  @@ Sexp.to_string_hum ~indent:1
  @@ [%sexp_of: string option array]
  @@ Silly.return_opt_array silly ~a:[| Some "apple"; None; Some "pie" |] ()
