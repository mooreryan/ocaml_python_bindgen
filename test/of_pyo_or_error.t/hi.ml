open Base
open Lib

let () = Py.initialize ()

let () =
  Caml.print_endline @@ Silly.x @@ Or_error.ok_exn
  @@ Silly.__init__ ~x:"all good!" ()
