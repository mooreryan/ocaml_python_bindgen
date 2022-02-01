let () = Py.initialize ()

let hagrid = Person.__init__ ~name:"Hagrid" ~age:111 ()

let () = print_endline @@ Person.__str__ hagrid ()
