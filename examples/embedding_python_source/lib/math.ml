module Adder : sig
  type t

  val of_pyobject : Pytypes.pyobject -> t option
  val to_pyobject : t -> Pytypes.pyobject
  val add : x:int -> y:int -> unit -> int
end = struct
  let filter_opt l = List.filter_map Fun.id l

  let py_module =
    lazy
      (let source =
         {pyml_bindgen_string_literal|class Adder:
    @staticmethod
    def add(x, y):
        return x + y
|pyml_bindgen_string_literal}
       in
       let filename =
         {pyml_bindgen_string_literal|../py/math/adder.py|pyml_bindgen_string_literal}
       in
       let bytecode = Py.compile ~filename ~source `Exec in
       Py.Import.exec_code_module
         {pyml_bindgen_string_literal|adder|pyml_bindgen_string_literal}
         bytecode)

  let import_module () = Lazy.force py_module

  type t = Pytypes.pyobject

  let is_instance pyo =
    let py_class = Py.Module.get (import_module ()) "Adder" in
    Py.Object.is_instance pyo py_class

  let of_pyobject pyo = if is_instance pyo then Some pyo else None
  let to_pyobject x = x

  let add ~x ~y () =
    let class_ = Py.Module.get (import_module ()) "Adder" in
    let callable = Py.Object.find_attr_string class_ "add" in
    let kwargs =
      filter_opt [ Some ("x", Py.Int.of_int x); Some ("y", Py.Int.of_int y) ]
    in
    Py.Int.to_int @@ Py.Callable.to_function_with_keywords callable [||] kwargs
end
