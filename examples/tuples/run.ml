open Lib

let () = Py.initialize ()

let () = assert (Tuples.pair ~x:1 ~y:"apple" () = (1, "apple"))

let () = assert (Tuples.first ~x:(1, 2) () = 1)

let () = assert (Tuples.identity ~x:(1, 2) () = (1, 2))

let () = assert (Tuples.make () = (0, 0))

let () = assert (Tuples.apple ~x:[ 1; 2 ] () = [ 1; 2 ])

let () = assert (Tuples.pie_list ~x:[ (1, 2); (3, 4) ] () = [ (1, 2); (3, 4) ])

let () =
  assert (Tuples.pie_array ~x:[| (1, 2); (3, 4) |] () = [| (1, 2); (3, 4) |])

let () =
  let l = [ (1, 2); (3, 4) ] in
  let x = List.to_seq l in
  let result = Tuples.pie_seq ~x () in
  assert (List.of_seq result = l)
