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

let () =
  let x = (1, "1") in
  assert (Tuples.t2 ~x () = x)

let () =
  let x = (1, "1", 1.0) in
  assert (Tuples.t3 ~x () = x)

let () =
  let x = (1, "1", 1.0, true) in
  assert (Tuples.t4 ~x () = x)

let () =
  let x = (1, "1", 1.0, true, 1) in
  assert (Tuples.t5 ~x () = x)

let () =
  let x = [ (1, "1", 1.0, true, 1) ] in
  assert (Tuples.t5_list ~x () = x)

let x = 1

let y = 2

let py_tup = (Py.Int.of_int x, Py.Int.of_int y)

let () =
  let x', y' = Tuples.t2_pyobject ~x:py_tup () in
  let x', y' = (Py.Int.to_int x', Py.Int.to_int y') in
  assert ((x, y) = (x', y'))

let () =
  let x', y' = Tuples.t2_pyobject2 ~x:py_tup () in
  let x', y' = (Py.Int.to_int x', Py.Int.to_int y') in
  assert ((x, y) = (x', y'))

let () =
  let x', y' =
    match Tuples.t2_pyobject_list ~x:[ py_tup ] () with
    | [ a ] -> a
    | _ -> assert false
  in
  let x', y' = (Py.Int.to_int x', Py.Int.to_int y') in
  assert ((x, y) = (x', y'))

let () =
  let x', y' =
    match Tuples.t2_pyobject2_list ~x:[ py_tup ] () with
    | [ a ] -> a
    | _ -> assert false
  in
  let x', y' = (Py.Int.to_int x', Py.Int.to_int y') in
  assert ((x, y) = (x', y'))

let () =
  let points1 = [ (1, 2); (3, 4) ] in
  let points2 = [ (10, 20); (30, 40) ] in
  let actual = Tuples.add ~points1 ~points2 () in
  let expected = [ (11, 22); (33, 44) ] in
  assert (actual = expected)
