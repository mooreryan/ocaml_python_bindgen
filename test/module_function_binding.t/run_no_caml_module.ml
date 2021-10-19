open! Base
open Lib
open Stdio

let () = Py.initialize ()

let () = print_endline ("add: " ^ Int.to_string (add ~a:10 ~b:20 ()))

let () = do_nothing ()
