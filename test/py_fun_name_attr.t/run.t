These are a little brittle...they will break if ocamlformat changes
the way it formats, but it is so much easier to read the generated
code if it is properly formatted.

Setup env

  $ export SANITIZE_LOGS=$PWD/../helpers/sanitize_logs

of_pyobject with no check

  $ if [ -f lib.ml ]; then rm lib.ml; fi
  $ pyml_bindgen specs.txt silly Cat --caml-module=Cat --of-pyo-ret-type=no_check > lib.ml
  $ ocamlformat --enable-outside-detected-project lib.ml
  module Cat : sig
    type t
  
    val of_pyobject : Pytypes.pyobject -> t
    val to_pyobject : t -> Pytypes.pyobject
    val create : name:string -> unit -> t
    val to_string : t -> unit -> string
    val eat : t -> num_mice:int -> unit -> unit
    val eat_part : t -> num_mice:float -> unit -> unit
    val climb : t -> how_high:int -> unit -> unit
  end = struct
    let filter_opt l = List.filter_map Fun.id l
    let py_module = lazy (Py.Import.import_module "silly")
    let import_module () = Lazy.force py_module
  
    type t = Pytypes.pyobject
  
    let of_pyobject pyo = pyo
    let to_pyobject x = x
  
    let create ~name () =
      let callable = Py.Module.get (import_module ()) "Cat" in
      let kwargs = filter_opt [ Some ("name", Py.String.of_string name) ] in
      of_pyobject @@ Py.Callable.to_function_with_keywords callable [||] kwargs
  
    let to_string t () =
      let callable = Py.Object.find_attr_string t "__str__" in
      let kwargs = filter_opt [] in
      Py.String.to_string
      @@ Py.Callable.to_function_with_keywords callable [||] kwargs
  
    let eat t ~num_mice () =
      let callable = Py.Object.find_attr_string t "eat" in
      let kwargs = filter_opt [ Some ("num_mice", Py.Int.of_int num_mice) ] in
      ignore @@ Py.Callable.to_function_with_keywords callable [||] kwargs
  
    let eat_part t ~num_mice () =
      let callable = Py.Object.find_attr_string t "eat" in
      let kwargs = filter_opt [ Some ("num_mice", Py.Float.of_float num_mice) ] in
      ignore @@ Py.Callable.to_function_with_keywords callable [||] kwargs
  
    let climb t ~how_high () =
      let callable = Py.Object.find_attr_string t "jump" in
      let kwargs = filter_opt [ Some ("how_high", Py.Int.of_int how_high) ] in
      ignore @@ Py.Callable.to_function_with_keywords callable [||] kwargs
  end
  $ dune exec ./run.exe 2> /dev/null
  Cat -- name: Sam, hunger: 9.0
  done
