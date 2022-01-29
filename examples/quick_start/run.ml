open Lib

let () = Py.initialize ()

let result = Adder.add ~x:1 ~y:2 ()

let () = assert (result = 3)
