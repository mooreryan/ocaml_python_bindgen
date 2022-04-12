With trailing / at end of path.

  $ pyml_bindgen specs.txt thing Thing --caml-module Thing --split-caml-module a/b/c/
  $ ocamlformat a/b/c/thing.ml
  let filter_opt l = List.filter_map Fun.id l
  
  let py_module = lazy (Py.Import.import_module "thing")
  
  let import_module () = Lazy.force py_module
  
  type t = Pytypes.pyobject
  
  let is_instance pyo =
    let py_class = Py.Module.get (import_module ()) "Thing" in
    Py.Object.is_instance pyo py_class
  
  let of_pyobject pyo = if is_instance pyo then Some pyo else None
  
  let to_pyobject x = x
  
  let create ~name () =
    let callable = Py.Module.get (import_module ()) "Thing" in
    let kwargs = filter_opt [ Some ("name", Py.String.of_string name) ] in
    of_pyobject @@ Py.Callable.to_function_with_keywords callable [||] kwargs
  
  let name t = Py.String.to_string @@ Py.Object.find_attr_string t "name"
  $ ocamlformat a/b/c/thing.mli
  type t
  
  val of_pyobject : Pytypes.pyobject -> t option
  
  val to_pyobject : t -> Pytypes.pyobject
  
  val create : name:string -> unit -> t option
  
  val name : t -> string


Without trailing / at end of path.

  $ pyml_bindgen specs.txt thing Thing --caml-module Thing --split-caml-module e/f/g
  $ diff a/b/c/thing.ml e/f/g/thing.ml
  $ diff a/b/c/thing.mli e/f/g/thing.mli

Actually using it.

  $ pyml_bindgen specs.txt thing Thing --caml-module Thing --split-caml-module .
  $ dune exec ./hello.exe
  Ryan
