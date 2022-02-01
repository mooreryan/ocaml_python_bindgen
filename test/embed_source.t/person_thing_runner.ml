open Lib

let () = Py.initialize ()

let hagrid = Person.__init__ ~name:"Hagrid" ~age:111 ()

let thing = Thing.__init__ ~color:"orange" ()

let () = print_endline @@ Person.__str__ hagrid ()

let () = print_endline @@ Thing.__str__ thing ()
