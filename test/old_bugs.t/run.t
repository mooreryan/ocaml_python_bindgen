Setup env

  $ export SANITIZE_LOGS=$PWD/../helpers/sanitize_logs

Basic usage.

  $ if [ -f lib.ml ]; then rm lib.ml; fi
  $ pyml_bindgen pr_value_bug.txt silly_mod Silly --caml-module=Silly --of-pyo-ret-type=no_check > lib.ml
  $ ocamlformat --enable --name=a.ml lib.ml
  module Silly : sig
    type t
  
    val of_pyobject : Pytypes.pyobject -> t
  
    val to_pyobject : t -> Pytypes.pyobject
  
    val add_feature : t -> pr_name:string -> pr_value:string -> unit -> unit
  
    val add_feature2 : t -> pr_name:string -> pr_value:string -> unit -> unit
  
    val add_feature3 : t -> pr_name:string -> pr_value:string -> unit -> unit
  end = struct
    let filter_opt l = List.filter_map Fun.id l
  
    let py_module = lazy (Py.Import.import_module "silly_mod")
  
    let import_module () = Lazy.force py_module
  
    type t = Pytypes.pyobject
  
    let of_pyobject pyo = pyo
  
    let to_pyobject x = x
  
    let add_feature t ~pr_name ~pr_value () =
      let callable = Py.Object.find_attr_string t "add_feature" in
      let kwargs =
        filter_opt
          [
            Some ("pr_name", Py.String.of_string pr_name);
            Some ("pr_value", Py.String.of_string pr_value);
          ]
      in
      ignore @@ Py.Callable.to_function_with_keywords callable [||] kwargs
  
    let add_feature2 t ~pr_name ~pr_value () =
      let callable = Py.Object.find_attr_string t "add_feature2" in
      let kwargs =
        filter_opt
          [
            Some ("pr_name", Py.String.of_string pr_name);
            Some ("pr_value", Py.String.of_string pr_value);
          ]
      in
      ignore @@ Py.Callable.to_function_with_keywords callable [||] kwargs
  
    let add_feature3 t ~pr_name ~pr_value () =
      let callable = Py.Object.find_attr_string t "add_feature3" in
      let kwargs =
        filter_opt
          [
            Some ("pr_name", Py.String.of_string pr_name);
            Some ("pr_value", Py.String.of_string pr_value);
          ]
      in
      ignore @@ Py.Callable.to_function_with_keywords callable [||] kwargs
  end
