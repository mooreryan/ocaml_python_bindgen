open Examples_attributes_lib

let () = Py.initialize ()

let cat = Cat.create ~name:"Sam" ()

let () = Cat.climb cat ~how_high:20 ()

let () = Cat.eat_part cat ~num_mice:0.2 ()

let () = Cat.eat cat ~num_mice:2 ()

let () = print_endline @@ Cat.to_string cat ()

let () = print_endline "done"
