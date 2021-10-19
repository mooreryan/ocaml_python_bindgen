open! Base
open Lib
open Stdio

let () = Py.initialize ()

let () = print_endline ("add: " ^ Int.to_string (Silly.add ~a:10 ~b:20 ()))

let () = Silly.do_nothing ()
