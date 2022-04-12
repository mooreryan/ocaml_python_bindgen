let () = Py.initialize ()

let () =
  let s =
    match Thing.create ~name:"Ryan" () with
    | None -> "oops!"
    | Some thing -> Thing.name thing
  in
  print_endline s
