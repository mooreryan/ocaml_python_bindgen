open! Base
open Examples_recursive_modules_lib.Lib

let () = Py.initialize ()

let print_endline = Stdio.print_endline

let human = Human.create ~name:"Bob" ()

let cat = Cat.create ~name:"Apple" ()

let () =
  print_endline "Before adoption...";
  print_endline @@ Human.to_string human ();
  print_endline @@ Cat.to_string cat ()

let () =
  Human.adopt_cat human ~cat ();
  Cat.adopt_human cat ~human ()

let () =
  print_endline "After adoption...";
  print_endline @@ Human.to_string human ();
  print_endline @@ Cat.to_string cat ()
