These are a little brittle...they will break if ocamlformat changes
the way it formats, but it is so much easier to read the generated
code if it is properly formatted.

Setup env

  $ export SANITIZE_LOGS=$PWD/../helpers/sanitize_logs

of_pyobject with no check

  $ if [ -f lib.ml ]; then rm lib.ml; fi
  $ pyml_bindgen specs.txt silly NA -a module --caml-module=Silly --of-pyo-ret-type=no_check > lib.ml
  $ ocamlformat --enable-outside-detected-project lib.ml
  module Silly : sig
    type t
  
    val of_pyobject : Pytypes.pyobject -> t
    val to_pyobject : t -> Pytypes.pyobject
  
    val concat1 :
      x:Pytypes.pyobject -> y:Pytypes.pyobject -> unit -> Pytypes.pyobject
  
    val concat2 : x:Py.Object.t -> y:Py.Object.t -> unit -> Py.Object.t
    val concat3 : x:int -> y:Py.Object.t -> unit -> int
  end = struct
    let filter_opt l = List.filter_map Fun.id l
    let py_module = lazy (Py.Import.import_module "silly")
    let import_module () = Lazy.force py_module
  
    type t = Pytypes.pyobject
  
    let of_pyobject pyo = pyo
    let to_pyobject x = x
  
    let concat1 ~x ~y () =
      let callable = Py.Module.get (import_module ()) "concat1" in
      let kwargs =
        filter_opt [ Some ("x", (fun x -> x) x); Some ("y", (fun x -> x) y) ]
      in
      (fun x -> x) @@ Py.Callable.to_function_with_keywords callable [||] kwargs
  
    let concat2 ~x ~y () =
      let callable = Py.Module.get (import_module ()) "concat2" in
      let kwargs =
        filter_opt [ Some ("x", (fun x -> x) x); Some ("y", (fun x -> x) y) ]
      in
      (fun x -> x) @@ Py.Callable.to_function_with_keywords callable [||] kwargs
  
    let concat3 ~x ~y () =
      let callable = Py.Module.get (import_module ()) "concat3" in
      let kwargs =
        filter_opt [ Some ("x", Py.Int.of_int x); Some ("y", (fun x -> x) y) ]
      in
      Py.Int.to_int @@ Py.Callable.to_function_with_keywords callable [||] kwargs
  end
  $ dune exec ./run.exe 2> /dev/null
  3
  3
  apple pie
  apple pie
  3
  Watch out for type errors....
  (Error
   ("E (<class 'TypeError'>, unsupported operand type(s) for +: 'int' and 'str')"))
  done

Pytypes option won't work

  $ if [ -f lib.ml ]; then rm lib.ml; fi
  $ echo "val f : x:int -> unit -> Pytypes.pyobject option" > bad_specs.txt
  $ pyml_bindgen bad_specs.txt silly NA -a module --caml-module=Silly --of-pyo-ret-type=no_check > lib.ml
  ("Error generating spec for 'val f : x:int -> unit -> Pytypes.pyobject option'"
   "Parsing val_spec failed... val_spec parser > parser failed before all input was consumed at token: option")
  $ echo "val f : x:int -> unit -> Py.Object.t option" > bad_specs.txt
  $ pyml_bindgen bad_specs.txt silly NA -a module --caml-module=Silly --of-pyo-ret-type=no_check > lib.ml
  ("Error generating spec for 'val f : x:int -> unit -> Py.Object.t option'"
   "Parsing val_spec failed... val_spec parser > parser failed before all input was consumed at token: option")
  $ echo "val f : x:Pytype.pyobject option -> unit -> int" > bad_specs.txt
  $ pyml_bindgen bad_specs.txt silly NA -a module --caml-module=Silly --of-pyo-ret-type=no_check > lib.ml
  ("Error generating spec for 'val f : x:Pytype.pyobject option -> unit -> int'"
   "Parsing val_spec failed... val_spec parser > parser failed before all input was consumed at token: x:Pytype.pyobject")
  $ echo "val f : x:Py.Object.t option -> unit -> int" > bad_specs.txt
  $ pyml_bindgen bad_specs.txt silly NA -a module --caml-module=Silly --of-pyo-ret-type=no_check > lib.ml
  ("Error generating spec for 'val f : x:Py.Object.t option -> unit -> int'"
   "Parsing val_spec failed... val_spec parser > parser failed before all input was consumed at token: option")

Pytypes Or_error.t won't work

  $ if [ -f lib.ml ]; then rm lib.ml; fi
  $ echo "val f : x:int -> unit -> Pytypes.pyobject Or_error.t" > bad_specs.txt
  $ pyml_bindgen bad_specs.txt silly NA -a module --caml-module=Silly --of-pyo-ret-type=or_error > lib.ml
  ("Error generating spec for 'val f : x:int -> unit -> Pytypes.pyobject Or_error.t'"
   "Parsing val_spec failed... val_spec parser > parser failed before all input was consumed at token: Or_error.t")
  $ echo "val f : x:int -> unit -> Py.Object.t Or_error.t" > bad_specs.txt
  $ pyml_bindgen bad_specs.txt silly NA -a module --caml-module=Silly --of-pyo-ret-type=or_error > lib.ml
  ("Error generating spec for 'val f : x:int -> unit -> Py.Object.t Or_error.t'"
   "Parsing val_spec failed... val_spec parser > parser failed before all input was consumed at token: Or_error.t")
  $ echo "val f : x:Pytype.pyobject Or_error.t -> unit -> int" > bad_specs.txt
  $ pyml_bindgen bad_specs.txt silly NA -a module --caml-module=Silly --of-pyo-ret-type=or_error > lib.ml
  ("Error generating spec for 'val f : x:Pytype.pyobject Or_error.t -> unit -> int'"
   "Parsing val_spec failed... val_spec parser > parser failed before all input was consumed at token: x:Pytype.pyobject")
  $ echo "val f : x:Py.Object.t Or_error.t -> unit -> int" > bad_specs.txt
  $ pyml_bindgen bad_specs.txt silly NA -a module --caml-module=Silly --of-pyo-ret-type=or_error > lib.ml
  ("Error generating spec for 'val f : x:Py.Object.t Or_error.t -> unit -> int'"
   "Parsing val_spec failed... val_spec parser > parser failed before all input was consumed at token: Or_error.t")

Pytypes list won't work

  $ if [ -f lib.ml ]; then rm lib.ml; fi
  $ echo "val f : x:int -> unit -> Pytypes.pyobject list" > bad_specs.txt
  $ pyml_bindgen bad_specs.txt silly NA -a module --caml-module=Silly --of-pyo-ret-type=no_check > lib.ml
  ("Error generating spec for 'val f : x:int -> unit -> Pytypes.pyobject list'"
   "Parsing val_spec failed... val_spec parser > parser failed before all input was consumed at token: list")
  $ echo "val f : x:int -> unit -> Py.Object.t list" > bad_specs.txt
  $ pyml_bindgen bad_specs.txt silly NA -a module --caml-module=Silly --of-pyo-ret-type=no_check > lib.ml
  ("Error generating spec for 'val f : x:int -> unit -> Py.Object.t list'"
   "Parsing val_spec failed... val_spec parser > parser failed before all input was consumed at token: list")
  $ echo "val f : x:Pytype.pyobject list -> unit -> int" > bad_specs.txt
  $ pyml_bindgen bad_specs.txt silly NA -a module --caml-module=Silly --of-pyo-ret-type=no_check > lib.ml
  ("Error generating spec for 'val f : x:Pytype.pyobject list -> unit -> int'"
   "Parsing val_spec failed... val_spec parser > parser failed before all input was consumed at token: x:Pytype.pyobject")
  $ echo "val f : x:Py.Object.t list -> unit -> int" > bad_specs.txt
  $ pyml_bindgen bad_specs.txt silly NA -a module --caml-module=Silly --of-pyo-ret-type=no_check > lib.ml
  ("Error generating spec for 'val f : x:Py.Object.t list -> unit -> int'"
   "Parsing val_spec failed... val_spec parser > parser failed before all input was consumed at token: list")

Pytypes array won't work

  $ if [ -f lib.ml ]; then rm lib.ml; fi
  $ echo "val f : x:int -> unit -> Pytypes.pyobject array" > bad_specs.txt
  $ pyml_bindgen bad_specs.txt silly NA -a module --caml-module=Silly --of-pyo-ret-type=no_check > lib.ml
  ("Error generating spec for 'val f : x:int -> unit -> Pytypes.pyobject array'"
   "Parsing val_spec failed... val_spec parser > parser failed before all input was consumed at token: array")
  $ echo "val f : x:int -> unit -> Py.Object.t array" > bad_specs.txt
  $ pyml_bindgen bad_specs.txt silly NA -a module --caml-module=Silly --of-pyo-ret-type=no_check > lib.ml
  ("Error generating spec for 'val f : x:int -> unit -> Py.Object.t array'"
   "Parsing val_spec failed... val_spec parser > parser failed before all input was consumed at token: array")
  $ echo "val f : x:Pytype.pyobject array -> unit -> int" > bad_specs.txt
  $ pyml_bindgen bad_specs.txt silly NA -a module --caml-module=Silly --of-pyo-ret-type=no_check > lib.ml
  ("Error generating spec for 'val f : x:Pytype.pyobject array -> unit -> int'"
   "Parsing val_spec failed... val_spec parser > parser failed before all input was consumed at token: x:Pytype.pyobject")
  $ echo "val f : x:Py.Object.t array -> unit -> int" > bad_specs.txt
  $ pyml_bindgen bad_specs.txt silly NA -a module --caml-module=Silly --of-pyo-ret-type=no_check > lib.ml
  ("Error generating spec for 'val f : x:Py.Object.t array -> unit -> int'"
   "Parsing val_spec failed... val_spec parser > parser failed before all input was consumed at token: array")

Pytypes Seq.t won't work

  $ if [ -f lib.ml ]; then rm lib.ml; fi
  $ echo "val f : x:int -> unit -> Pytypes.pyobject Seq.t" > bad_specs.txt
  $ pyml_bindgen bad_specs.txt silly NA -a module --caml-module=Silly --of-pyo-ret-type=no_check > lib.ml
  ("Error generating spec for 'val f : x:int -> unit -> Pytypes.pyobject Seq.t'"
   "Parsing val_spec failed... val_spec parser > parser failed before all input was consumed at token: Seq.t")
  $ echo "val f : x:int -> unit -> Py.Object.t Seq.t" > bad_specs.txt
  $ pyml_bindgen bad_specs.txt silly NA -a module --caml-module=Silly --of-pyo-ret-type=no_check > lib.ml
  ("Error generating spec for 'val f : x:int -> unit -> Py.Object.t Seq.t'"
   "Parsing val_spec failed... val_spec parser > parser failed before all input was consumed at token: Seq.t")
  $ echo "val f : x:Pytype.pyobject Seq.t -> unit -> int" > bad_specs.txt
  $ pyml_bindgen bad_specs.txt silly NA -a module --caml-module=Silly --of-pyo-ret-type=no_check > lib.ml
  ("Error generating spec for 'val f : x:Pytype.pyobject Seq.t -> unit -> int'"
   "Parsing val_spec failed... val_spec parser > parser failed before all input was consumed at token: x:Pytype.pyobject")
  $ echo "val f : x:Py.Object.t Seq.t -> unit -> int" > bad_specs.txt
  $ pyml_bindgen bad_specs.txt silly NA -a module --caml-module=Silly --of-pyo-ret-type=no_check > lib.ml
  ("Error generating spec for 'val f : x:Py.Object.t Seq.t -> unit -> int'"
   "Parsing val_spec failed... val_spec parser > parser failed before all input was consumed at token: Seq.t")
