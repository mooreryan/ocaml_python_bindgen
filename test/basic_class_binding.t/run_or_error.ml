open! Base
open Lib
open Stdio

let () = Py.initialize ()

let silly = Or_error.ok_exn @@ Silly.__init__ ~x:1 ~y:2 ()

let () = print_endline ("x: " ^ Int.to_string (Silly.x silly))
let () = print_endline ("y: " ^ Int.to_string (Silly.y silly))
let () = print_endline ("foo: " ^ Int.to_string (Silly.foo silly ~a:10 ~b:20 ()))
let () = print_endline ("bar: " ^ Int.to_string (Silly.bar ~a:10 ~b:20 ()))
