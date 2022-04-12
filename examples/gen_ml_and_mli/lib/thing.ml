open! Base

let filter_opt = List.filter_opt

let py_module =
  lazy
    (let source =
       {pyml_bindgen_string_literal|class Thing:
    def __init__(self, name):
        self.name = name
|pyml_bindgen_string_literal}
     in
     let filename =
       {pyml_bindgen_string_literal|py/thing.py|pyml_bindgen_string_literal}
     in
     let bytecode = Py.compile ~filename ~source `Exec in
     Py.Import.exec_code_module
       {pyml_bindgen_string_literal|thing|pyml_bindgen_string_literal} bytecode)

let import_module () = Lazy.force py_module

type t = Pytypes.pyobject

let is_instance pyo =
  let py_class = Py.Module.get (import_module ()) "Thing" in
  Py.Object.is_instance pyo py_class

let of_pyobject pyo =
  if is_instance pyo then Or_error.return pyo
  else Or_error.error_string "Expected Thing"

let to_pyobject x = x

let create ~name () =
  let callable = Py.Module.get (import_module ()) "Thing" in
  let kwargs = filter_opt [ Some ("name", Py.String.of_string name) ] in
  of_pyobject @@ Py.Callable.to_function_with_keywords callable [||] kwargs

let name t = Py.String.to_string @@ Py.Object.find_attr_string t "name"
