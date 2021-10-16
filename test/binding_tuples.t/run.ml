open Lib

let () = Py.initialize ()

let () =
  Tuple_int_string.print_endline
  @@ Silly.foo ~x:(Tuple_int_string.make 1 "a") ()
