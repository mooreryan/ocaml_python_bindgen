module Add : sig
  type t

  val of_pyobject : Pytypes.pyobject -> t option
  val to_pyobject : t -> Pytypes.pyobject
  val add : x:int -> y:int -> unit -> int
end = struct
  let filter_opt l = List.filter_map Fun.id l
  let py_module = lazy (Py.Import.import_module "silly_math.adder.add")
  let import_module () = Lazy.force py_module

  type t = Pytypes.pyobject

  let is_instance pyo =
    let py_class = Py.Module.get (import_module ()) "NA" in
    Py.Object.is_instance pyo py_class

  let of_pyobject pyo = if is_instance pyo then Some pyo else None
  let to_pyobject x = x

  let add ~x ~y () =
    let callable = Py.Module.get (import_module ()) "add" in
    let kwargs =
      filter_opt [ Some ("x", Py.Int.of_int x); Some ("y", Py.Int.of_int y) ]
    in
    Py.Int.to_int @@ Py.Callable.to_function_with_keywords callable [||] kwargs
end

module Subtract : sig
  type t

  val of_pyobject : Pytypes.pyobject -> t option
  val to_pyobject : t -> Pytypes.pyobject
  val subtract : x:int -> y:int -> unit -> int
end = struct
  let filter_opt l = List.filter_map Fun.id l

  let py_module =
    lazy (Py.Import.import_module "silly_math.subtracter.subtract")

  let import_module () = Lazy.force py_module

  type t = Pytypes.pyobject

  let is_instance pyo =
    let py_class = Py.Module.get (import_module ()) "NA" in
    Py.Object.is_instance pyo py_class

  let of_pyobject pyo = if is_instance pyo then Some pyo else None
  let to_pyobject x = x

  let subtract ~x ~y () =
    let callable = Py.Module.get (import_module ()) "subtract" in
    let kwargs =
      filter_opt [ Some ("x", Py.Int.of_int x); Some ("y", Py.Int.of_int y) ]
    in
    Py.Int.to_int @@ Py.Callable.to_function_with_keywords callable [||] kwargs
end
