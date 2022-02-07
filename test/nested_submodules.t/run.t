These are a little brittle...they will break if ocamlformat changes
the way it formats, but it is so much easier to read the generated
code if it is properly formatted.

Setup env

  $ export SANITIZE_LOGS=$PWD/../helpers/sanitize_logs

of_pyobject with no check

  $ if [ -f lib.ml ]; then rm lib.ml; fi
  $ pyml_bindgen specs_no_check.txt silly Cat --caml-module=Cat --of-pyo-ret-type=no_check > lib.ml
  $ ocamlformat --enable-outside-detected-project lib.ml
  module Cat : sig
    type t
  
    val of_pyobject : Pytypes.pyobject -> t
  
    val to_pyobject : t -> Pytypes.pyobject
  
    val __init__ : name:string -> unit -> t
  
    val eat : t -> fly:Creature.Bug.Fly.t -> unit -> unit
  
    val hunger : t -> int
  end = struct
    let filter_opt l = List.filter_map Fun.id l
  
    let py_module = lazy (Py.Import.import_module "silly")
  
    let import_module () = Lazy.force py_module
  
    type t = Pytypes.pyobject
  
    let of_pyobject pyo = pyo
  
    let to_pyobject x = x
  
    let __init__ ~name () =
      let callable = Py.Module.get (import_module ()) "Cat" in
      let kwargs = filter_opt [ Some ("name", Py.String.of_string name) ] in
      of_pyobject @@ Py.Callable.to_function_with_keywords callable [||] kwargs
  
    let eat t ~fly () =
      let callable = Py.Object.find_attr_string t "eat" in
      let kwargs =
        filter_opt [ Some ("fly", Creature.Bug.Fly.to_pyobject fly) ]
      in
      ignore @@ Py.Callable.to_function_with_keywords callable [||] kwargs
  
    let hunger t = Py.Int.to_int @@ Py.Object.find_attr_string t "hunger"
  end
  $ dune exec ./run_no_check.exe 2> /dev/null
  10
  5
  done

of_pyobject returning option

  $ if [ -f lib.ml ]; then rm lib.ml; fi
  $ pyml_bindgen specs_option.txt silly Cat --caml-module=Cat --of-pyo-ret-type=option > lib.ml
  $ ocamlformat --enable-outside-detected-project lib.ml
  module Cat : sig
    type t
  
    val of_pyobject : Pytypes.pyobject -> t option
  
    val to_pyobject : t -> Pytypes.pyobject
  
    val __init__ : name:string -> unit -> t option
  
    val eat : t -> fly:Creature.Bug.Fly.t -> unit -> unit
  
    val hunger : t -> int
  end = struct
    let filter_opt l = List.filter_map Fun.id l
  
    let py_module = lazy (Py.Import.import_module "silly")
  
    let import_module () = Lazy.force py_module
  
    type t = Pytypes.pyobject
  
    let is_instance pyo =
      let py_class = Py.Module.get (import_module ()) "Cat" in
      Py.Object.is_instance pyo py_class
  
    let of_pyobject pyo = if is_instance pyo then Some pyo else None
  
    let to_pyobject x = x
  
    let __init__ ~name () =
      let callable = Py.Module.get (import_module ()) "Cat" in
      let kwargs = filter_opt [ Some ("name", Py.String.of_string name) ] in
      of_pyobject @@ Py.Callable.to_function_with_keywords callable [||] kwargs
  
    let eat t ~fly () =
      let callable = Py.Object.find_attr_string t "eat" in
      let kwargs =
        filter_opt [ Some ("fly", Creature.Bug.Fly.to_pyobject fly) ]
      in
      ignore @@ Py.Callable.to_function_with_keywords callable [||] kwargs
  
    let hunger t = Py.Int.to_int @@ Py.Object.find_attr_string t "hunger"
  end
  $ dune exec ./run_option.exe 2> /dev/null
  10
  5
  done

of_pyobject returning Or_error

  $ if [ -f lib.ml ]; then rm lib.ml; fi
  $ pyml_bindgen specs_or_error.txt silly Cat --caml-module=Cat --of-pyo-ret-type=or_error > lib.ml
  $ ocamlformat --enable-outside-detected-project lib.ml
  open! Base
  
  module Cat : sig
    type t
  
    val of_pyobject : Pytypes.pyobject -> t Or_error.t
  
    val to_pyobject : t -> Pytypes.pyobject
  
    val __init__ : name:string -> unit -> t Or_error.t
  
    val eat : t -> fly:Creature.Bug.Fly.t -> unit -> unit
  
    val hunger : t -> int
  end = struct
    let filter_opt = List.filter_opt
  
    let py_module = lazy (Py.Import.import_module "silly")
  
    let import_module () = Lazy.force py_module
  
    type t = Pytypes.pyobject
  
    let is_instance pyo =
      let py_class = Py.Module.get (import_module ()) "Cat" in
      Py.Object.is_instance pyo py_class
  
    let of_pyobject pyo =
      if is_instance pyo then Or_error.return pyo
      else Or_error.error_string "Expected Cat"
  
    let to_pyobject x = x
  
    let __init__ ~name () =
      let callable = Py.Module.get (import_module ()) "Cat" in
      let kwargs = filter_opt [ Some ("name", Py.String.of_string name) ] in
      of_pyobject @@ Py.Callable.to_function_with_keywords callable [||] kwargs
  
    let eat t ~fly () =
      let callable = Py.Object.find_attr_string t "eat" in
      let kwargs =
        filter_opt [ Some ("fly", Creature.Bug.Fly.to_pyobject fly) ]
      in
      ignore @@ Py.Callable.to_function_with_keywords callable [||] kwargs
  
    let hunger t = Py.Int.to_int @@ Py.Object.find_attr_string t "hunger"
  end
  $ dune exec ./run_or_error.exe 2> /dev/null
  10
  5
  done
