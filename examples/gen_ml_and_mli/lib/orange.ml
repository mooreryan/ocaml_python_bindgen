open! Base

let filter_opt = List.filter_opt

let py_module =
  lazy
    (let source =
       {pyml_bindgen_string_literal|class Orange:
    def __init__(self, flavor):
        self.flavor = flavor
|pyml_bindgen_string_literal}
     in
     let filename =
       {pyml_bindgen_string_literal|py/orange.py|pyml_bindgen_string_literal}
     in
     let bytecode = Py.compile ~filename ~source `Exec in
     Py.Import.exec_code_module
       {pyml_bindgen_string_literal|orange|pyml_bindgen_string_literal} bytecode)

let import_module () = Lazy.force py_module

type t = Pytypes.pyobject

let is_instance pyo =
  let py_class = Py.Module.get (import_module ()) "Orange" in
  Py.Object.is_instance pyo py_class

let of_pyobject pyo =
  if is_instance pyo then Or_error.return pyo
  else Or_error.error_string "Expected Orange"

let to_pyobject x = x

let create ~flavor () =
  let callable = Py.Module.get (import_module ()) "Orange" in
  let kwargs = filter_opt [ Some ("flavor", Py.String.of_string flavor) ] in
  of_pyobject @@ Py.Callable.to_function_with_keywords callable [||] kwargs

let flavor t = Py.String.to_string @@ Py.Object.find_attr_string t "flavor"
