module Hearts : sig
  type t

  val of_pyobject : Pytypes.pyobject -> t option

  val to_pyobject : t -> Pytypes.pyobject

  val hearts : unit -> string
end = struct
  let filter_opt l = List.filter_map Fun.id l

  let import_module () = Py.Import.import_module "magic_dust.hearts"

  type t = Pytypes.pyobject

  let is_instance pyo =
    let py_class = Py.Module.get (import_module ()) "NA" in
    Py.Object.is_instance pyo py_class

  let of_pyobject pyo = if is_instance pyo then Some pyo else None

  let to_pyobject x = x

  let hearts () =
    let callable = Py.Module.get (import_module ()) "hearts" in
    let kwargs = filter_opt [] in
    Py.String.to_string
    @@ Py.Callable.to_function_with_keywords callable [||] kwargs
end

module Sparkles : sig
  type t

  val of_pyobject : Pytypes.pyobject -> t option

  val to_pyobject : t -> Pytypes.pyobject

  val sparkles : unit -> string
end = struct
  let filter_opt l = List.filter_map Fun.id l

  let import_module () = Py.Import.import_module "magic_dust.sparkles"

  type t = Pytypes.pyobject

  let is_instance pyo =
    let py_class = Py.Module.get (import_module ()) "NA" in
    Py.Object.is_instance pyo py_class

  let of_pyobject pyo = if is_instance pyo then Some pyo else None

  let to_pyobject x = x

  let sparkles () =
    let callable = Py.Module.get (import_module ()) "sparkles" in
    let kwargs = filter_opt [] in
    Py.String.to_string
    @@ Py.Callable.to_function_with_keywords callable [||] kwargs
end
