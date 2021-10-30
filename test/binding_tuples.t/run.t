These are a little brittle...they will break if ocamlformat changes
the way it formats, but it is so much easier to read the generated
code if it is properly formatted.

Setup env

  $ export SANITIZE_LOGS=$PWD/../helpers/sanitize_logs

Binding tuples

  $ if [ -f tmp ]; then rm tmp; fi
  $ pyml_bindgen sigs.txt silly Silly --caml-module=Silly --of-pyo-ret-type=no_check > tmp

Cat the files and run.

  $ cat lib_ml.txt > lib.ml
  $ printf "\n" >> lib.ml
  $ cat tmp >> lib.ml
  $ ocamlformat --enable-outside-detected-project lib.ml
  module Tuple_int_string : sig
    type t
  
    val make : int -> string -> t
  
    val to_pyobject : t -> Pytypes.pyobject
  
    val of_pyobject : Pytypes.pyobject -> t
  
    val print_endline : t -> unit
  end = struct
    type t = int * string
  
    let make i s = (i, s)
  
    let to_pyobject (i, s) =
      Py.Tuple.of_tuple2 (Py.Int.of_int i, Py.String.of_string s)
  
    let of_pyobject pyo =
      let i, s = Py.Tuple.to_tuple2 pyo in
      (Py.Int.to_int i, Py.String.to_string s)
  
    let print_endline (i, s) = print_endline @@ string_of_int i ^ " " ^ s
  end
  
  module Silly : sig
    type t
  
    val of_pyobject : Pytypes.pyobject -> t
  
    val to_pyobject : t -> Pytypes.pyobject
  
    val foo : x:Tuple_int_string.t -> unit -> Tuple_int_string.t
  end = struct
    let filter_opt l = List.filter_map Fun.id l
  
    let import_module () = Py.Import.import_module "silly"
  
    type t = Pytypes.pyobject
  
    let of_pyobject pyo = pyo
  
    let to_pyobject x = x
  
    let foo ~x () =
      let class_ = Py.Module.get (import_module ()) "Silly" in
      let callable = Py.Object.find_attr_string class_ "foo" in
      let kwargs = filter_opt [ Some ("x", Tuple_int_string.to_pyobject x) ] in
      Tuple_int_string.of_pyobject
      @@ Py.Callable.to_function_with_keywords callable [||] kwargs
  end
  $ dune exec ./run.exe 2> /dev/null
  10 a!!

