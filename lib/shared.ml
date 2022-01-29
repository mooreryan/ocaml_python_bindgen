open! Base

(** Note, this one isn't included in the "all" functions below. *)
let gen_import_module_impl py_module =
  [%string {| let import_module () = Py.Import.import_module "%{py_module}" |}]

let gen_type_sig () = "type t"

let gen_type_impl () = "type t = Pytypes.pyobject"

let gen_of_pyobject_sig = function
  | `No_check -> "val of_pyobject : Pytypes.pyobject -> t"
  | `Option -> "val of_pyobject : Pytypes.pyobject -> t option"
  | `Or_error -> "val of_pyobject : Pytypes.pyobject -> t Or_error.t"

(** Only generates stuff for simple python types, or for custom classes. If you
    have a list you will need to write your own. *)
let gen_of_pyobject_impl of_pyo_return_type of_pyo_otype =
  match (of_pyo_return_type, of_pyo_otype) with
  | `Option, `Custom py_class ->
      [%string
        {|
let is_instance pyo =
  let py_class = Py.Module.get (import_module ()) "%{py_class}" in
  Py.Object.is_instance pyo py_class

let of_pyobject pyo = if is_instance pyo then Some pyo else None
|}]
  | `Or_error, `Custom py_class ->
      [%string
        {|
let is_instance pyo =
  let py_class = Py.Module.get (import_module ()) "%{py_class}" in
  Py.Object.is_instance pyo py_class

let of_pyobject pyo =
  if is_instance pyo then Or_error.return pyo
  else Or_error.error_string "Expected %{py_class}"
|}]
  | `Option, `Int ->
      [%string
        {| let of_pyobject pyo = if Py.Int.check pyo then Some pyo else None |}]
  | `Or_error, `Int ->
      [%string
        {|
let of_pyobject pyo =
  if Py.Int.check pyo then Or_error.return 
  else Or_error.error_string "Expected Int"
|}]
  | `Option, `Float ->
      [%string
        {| let of_pyobject pyo = if Py.Float.check pyo then Some pyo else None |}]
  | `Or_error, `Float ->
      [%string
        {| 
let of_pyobject pyo = 
  if Py.Float.check pyo then Or_error.return pyo 
  else Or_error.error_string "Expected Float"
|}]
  | `Option, `String ->
      [%string
        {| let of_pyobject pyo = if Py.String.check pyo then Some pyo else None |}]
  | `Or_error, `String ->
      [%string
        {| 
let of_pyobject pyo = 
  if Py.String.check pyo then Or_error.return pyo 
  else Or_error.error_string "Expected String"
|}]
  | `Option, `Bool ->
      [%string
        {| let of_pyobject pyo = if Py.Bool.check pyo then Some pyo else None |}]
  | `Or_error, `Bool ->
      [%string
        {|
let of_pyobject pyo = 
  if Py.Bool.check pyo then Or_error.return pyo 
  else Or_error.error_string "Expected Bool"
|}]
  | `No_check, `Custom _
  | `No_check, `Int
  | `No_check, `Float
  | `No_check, `String
  | `No_check, `Bool ->
      "let of_pyobject pyo = pyo"

let gen_to_pyobject_sig () = "val to_pyobject : t -> Pytypes.pyobject"

let gen_to_pyobject_impl () = "let to_pyobject x = x"

let gen_all_signatures of_pyo_return_type =
  [
    gen_type_sig ();
    gen_of_pyobject_sig of_pyo_return_type;
    gen_to_pyobject_sig ();
  ]

let gen_all_functions of_pyo_return_type of_pyo_otype =
  [
    gen_type_impl ();
    gen_of_pyobject_impl of_pyo_return_type of_pyo_otype;
    gen_to_pyobject_impl ();
  ]
