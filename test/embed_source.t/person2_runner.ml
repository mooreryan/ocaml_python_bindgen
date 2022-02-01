let () = Py.initialize ()

let hagrid = Person2.__init__ ~name:"Hagrid" ~age:111 ()

let () = print_endline @@ Person2.__str__ hagrid ()
