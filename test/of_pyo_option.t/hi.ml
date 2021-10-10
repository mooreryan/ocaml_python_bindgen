open Lib

let () = Py.initialize ()

let () =
  match Silly.__init__ ~x:"all good!" () with
  | Some s -> print_endline @@ Silly.x s
  | None -> prerr_endline "Couldn't make a Silly thing"
