open! Base
open Gen_ml_and_mli_lib

let () = Py.initialize ()

let thing = Or_error.ok_exn @@ Thing.create ~name:"Ryan" ()

let () = assert (String.("Ryan" = Thing.name thing))

let orange = Or_error.ok_exn @@ Orange.create ~flavor:"Sooo good!" ()

let () = assert (String.("Sooo good!" = Orange.flavor orange))
