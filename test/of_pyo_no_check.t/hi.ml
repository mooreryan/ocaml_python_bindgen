open Lib

let () = Py.initialize ()

let () = print_endline @@ Silly.x @@ Silly.__init__ ~x:"all good!" ()
