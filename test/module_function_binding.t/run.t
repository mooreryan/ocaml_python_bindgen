These are a little brittle...they will break if ocamlformat changes
the way it formats, but it is so much easier to read the generated
code if it is properly formatted.

Setup env

  $ export SANITIZE_LOGS=$PWD/../helpers/sanitize_logs

Run

  $ if [ -f lib.ml ]; then rm lib.ml; fi
  $ pyml_bindgen sigs_no_check.txt silly Silly -r no_check -a module > lib.ml
  $ ocamlformat --enable-outside-detected-project lib.ml
  let filter_opt l = List.filter_map Fun.id l
  
  let import_module () = Py.Import.import_module "silly"
  
  type t = Pytypes.pyobject
  
  let of_pyobject pyo = pyo
  
  let to_pyobject x = x
  
  let add ~a ~b () =
    let callable = Py.Module.get (import_module ()) "add" in
    let kwargs =
      filter_opt [ Some ("a", Py.Int.of_int a); Some ("b", Py.Int.of_int b) ]
    in
    Py.Int.to_int @@ Py.Callable.to_function_with_keywords callable [||] kwargs
  
  let do_nothing () =
    let callable = Py.Module.get (import_module ()) "do_nothing" in
    let kwargs = filter_opt [] in
    ignore @@ Py.Callable.to_function_with_keywords callable [||] kwargs
  $ dune exec ./run_no_caml_module.exe 2> /dev/null
  add: 30

Run

  $ if [ -f lib.ml ]; then rm lib.ml; fi
  $ pyml_bindgen sigs_no_check.txt silly Silly -c Silly -r no_check -a module > lib.ml
  $ ocamlformat --enable-outside-detected-project lib.ml
  module Silly : sig
    type t
  
    val of_pyobject : Pytypes.pyobject -> t
  
    val to_pyobject : t -> Pytypes.pyobject
  
    val add : a:int -> b:int -> unit -> int
  
    val do_nothing : unit -> unit
  end = struct
    let filter_opt l = List.filter_map Fun.id l
  
    let import_module () = Py.Import.import_module "silly"
  
    type t = Pytypes.pyobject
  
    let of_pyobject pyo = pyo
  
    let to_pyobject x = x
  
    let add ~a ~b () =
      let callable = Py.Module.get (import_module ()) "add" in
      let kwargs =
        filter_opt [ Some ("a", Py.Int.of_int a); Some ("b", Py.Int.of_int b) ]
      in
      Py.Int.to_int @@ Py.Callable.to_function_with_keywords callable [||] kwargs
  
    let do_nothing () =
      let callable = Py.Module.get (import_module ()) "do_nothing" in
      let kwargs = filter_opt [] in
      ignore @@ Py.Callable.to_function_with_keywords callable [||] kwargs
  end
  $ dune exec ./run_with_caml_module.exe 
  add: 30
