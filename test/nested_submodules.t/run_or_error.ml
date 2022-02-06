open! Base
open Lib
open Stdio

let () = Py.initialize ()

let cat = Or_error.ok_exn (Cat.__init__ ~name:"Sam" ())

let () = print_endline @@ Int.to_string @@ Cat.hunger cat

let fly = Creature.Bug.Fly.make "Bill"

let () = Cat.eat cat ~fly ()

let () = print_endline @@ Int.to_string @@ Cat.hunger cat

let () = print_endline "done"
