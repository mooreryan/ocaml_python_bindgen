open! Base

(** Note, this one isn't included in the "all" functions below. *)
let gen_import_module_impl py_module =
  [%string {| let import_module () = Py.Import.import_module "%{py_module}" |}]

let gen_type_sig () = "type t"
let gen_type_impl () = "type t = Pytypes.pyobject"

let gen_of_pyobject_sig = function
  | `No_check -> "val of_pyobject : Pytypes.pyobject -> t"
  | `Check -> "val of_pyobject : Pytypes.pyobject -> t option"

(** Only generates stuff for simple python types, or for custom classes. If you
    have a list you will need to write your own. *)
let gen_of_pyobject_impl = function
  | `Custom py_class ->
      [%string
        {|
let is_instance pyo =
  let py_class = Py.Module.get (import_module ()) "%{py_class}" in
  Py.Object.is_instance pyo py_class

let of_pyobject pyo = if is_instance pyo then Some pyo else None
|}]
  | `Int ->
      [%string
        {| let of_pyobject pyo = if Py.Int.check pyo then Some pyo else None |}]
  | `Float ->
      [%string
        {| let of_pyobject pyo = if Py.Float.check pyo then Some pyo else None |}]
  | `String ->
      [%string
        {| let of_pyobject pyo = if Py.String.check pyo then Some pyo else None |}]
  | `Bool ->
      [%string
        {| let of_pyobject pyo = if Py.Bool.check pyo then Some pyo else None |}]
  | `No_check -> "let of_pyobject pyo = pyo"
  | `Todo -> {| let of_pyobject pyo = failwith "unimplemented" |}

let gen_to_pyobject_sig () = "val to_pyobject : t -> Pytypes.pyobject"
let gen_to_pyobject_impl () = "let to_pyobject x = x"

let gen_all_signatures () =
  [ gen_type_sig (); gen_of_pyobject_sig `Check; gen_to_pyobject_sig () ]

let gen_all_functions ~py_class =
  [
    gen_type_impl ();
    gen_of_pyobject_impl (`Custom py_class);
    gen_to_pyobject_impl ();
  ]
