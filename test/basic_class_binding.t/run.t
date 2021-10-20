These are a little brittle...they will break if ocamlformat changes
the way it formats, but it is so much easier to read the generated
code if it is properly formatted.

Setup env

  $ export SANITIZE_LOGS=$PWD/../helpers/sanitize_logs

of_pyobject with no check

  $ if [ -f lib.ml ]; then rm lib.ml; fi
  $ pyml_bindgen sigs_no_check.txt silly Silly --caml-module=Silly --of-pyo-ret-type=no_check > lib.ml
  $ ocamlformat --enable-outside-detected-project lib.ml
  let filter_opt l = List.filter_map Fun.id l
  
  module Silly : sig
    type t
  
    val of_pyobject : Pytypes.pyobject -> t
  
    val to_pyobject : t -> Pytypes.pyobject
  
    val __init__ : x:int -> y:int -> unit -> t
  
    val x : t -> int
  
    val y : t -> int
  
    val foo : t -> a:int -> b:int -> unit -> int
  
    val do_nothing : t -> unit -> unit
  
    val return_list : t -> l:string list -> unit -> string list
  
    val return_opt_list : t -> l:string option list -> unit -> string option list
  
    val bar : a:int -> b:int -> unit -> int
  
    val do_nothing2 : unit -> unit
  end = struct
    let import_module () = Py.Import.import_module "silly"
  
    type t = Pytypes.pyobject
  
    let of_pyobject pyo = pyo
  
    let to_pyobject x = x
  
    let __init__ ~x ~y () =
      let callable = Py.Module.get (import_module ()) "Silly" in
      let kwargs =
        filter_opt [ Some ("x", Py.Int.of_int x); Some ("y", Py.Int.of_int y) ]
      in
      of_pyobject @@ Py.Callable.to_function_with_keywords callable [||] kwargs
  
    let x t = Py.Int.to_int @@ Py.Object.find_attr_string t "x"
  
    let y t = Py.Int.to_int @@ Py.Object.find_attr_string t "y"
  
    let foo t ~a ~b () =
      let callable = Py.Object.find_attr_string t "foo" in
      let kwargs =
        filter_opt [ Some ("a", Py.Int.of_int a); Some ("b", Py.Int.of_int b) ]
      in
      Py.Int.to_int @@ Py.Callable.to_function_with_keywords callable [||] kwargs
  
    let do_nothing t () =
      let callable = Py.Object.find_attr_string t "do_nothing" in
      let kwargs = filter_opt [] in
      ignore @@ Py.Callable.to_function_with_keywords callable [||] kwargs
  
    let return_list t ~l () =
      let callable = Py.Object.find_attr_string t "return_list" in
      let kwargs =
        filter_opt [ Some ("l", Py.List.of_list_map Py.String.of_string l) ]
      in
      Py.List.to_list_map Py.String.to_string
      @@ Py.Callable.to_function_with_keywords callable [||] kwargs
  
    let return_opt_list t ~l () =
      let callable = Py.Object.find_attr_string t "return_opt_list" in
      let kwargs =
        filter_opt
          [
            Some
              ( "l",
                Py.List.of_list_map
                  (function Some x -> Py.String.of_string x | None -> Py.none)
                  l );
          ]
      in
      Py.List.to_list_map (fun x ->
          if Py.is_none x then None else Some (Py.String.to_string x))
      @@ Py.Callable.to_function_with_keywords callable [||] kwargs
  
    let bar ~a ~b () =
      let class_ = Py.Module.get (import_module ()) "Silly" in
      let callable = Py.Object.find_attr_string class_ "bar" in
      let kwargs =
        filter_opt [ Some ("a", Py.Int.of_int a); Some ("b", Py.Int.of_int b) ]
      in
      Py.Int.to_int @@ Py.Callable.to_function_with_keywords callable [||] kwargs
  
    let do_nothing2 () =
      let class_ = Py.Module.get (import_module ()) "Silly" in
      let callable = Py.Object.find_attr_string class_ "do_nothing2" in
      let kwargs = filter_opt [] in
      ignore @@ Py.Callable.to_function_with_keywords callable [||] kwargs
  end
  $ dune exec ./run_no_check.exe 2> /dev/null
  x: 1
  y: 2
  foo: 33
  bar: 30
  (apple pie)
  ((apple) () (pie))

of_pyobject returning option

  $ if [ -f lib.ml ]; then rm lib.ml; fi
  $ pyml_bindgen sigs_option.txt silly Silly --caml-module=Silly --of-pyo-ret-type=option > lib.ml
  $ ocamlformat --enable-outside-detected-project lib.ml
  let filter_opt l = List.filter_map Fun.id l
  
  module Silly : sig
    type t
  
    val of_pyobject : Pytypes.pyobject -> t option
  
    val to_pyobject : t -> Pytypes.pyobject
  
    val __init__ : x:int -> y:int -> unit -> t option
  
    val x : t -> int
  
    val y : t -> int
  
    val foo : t -> a:int -> b:int -> unit -> int
  
    val do_nothing : t -> unit -> unit
  
    val return_list : t -> l:string list -> unit -> string list
  
    val return_opt_list : t -> l:string option list -> unit -> string option list
  
    val bar : a:int -> b:int -> unit -> int
  
    val do_nothing2 : unit -> unit
  end = struct
    let import_module () = Py.Import.import_module "silly"
  
    type t = Pytypes.pyobject
  
    let is_instance pyo =
      let py_class = Py.Module.get (import_module ()) "Silly" in
      Py.Object.is_instance pyo py_class
  
    let of_pyobject pyo = if is_instance pyo then Some pyo else None
  
    let to_pyobject x = x
  
    let __init__ ~x ~y () =
      let callable = Py.Module.get (import_module ()) "Silly" in
      let kwargs =
        filter_opt [ Some ("x", Py.Int.of_int x); Some ("y", Py.Int.of_int y) ]
      in
      of_pyobject @@ Py.Callable.to_function_with_keywords callable [||] kwargs
  
    let x t = Py.Int.to_int @@ Py.Object.find_attr_string t "x"
  
    let y t = Py.Int.to_int @@ Py.Object.find_attr_string t "y"
  
    let foo t ~a ~b () =
      let callable = Py.Object.find_attr_string t "foo" in
      let kwargs =
        filter_opt [ Some ("a", Py.Int.of_int a); Some ("b", Py.Int.of_int b) ]
      in
      Py.Int.to_int @@ Py.Callable.to_function_with_keywords callable [||] kwargs
  
    let do_nothing t () =
      let callable = Py.Object.find_attr_string t "do_nothing" in
      let kwargs = filter_opt [] in
      ignore @@ Py.Callable.to_function_with_keywords callable [||] kwargs
  
    let return_list t ~l () =
      let callable = Py.Object.find_attr_string t "return_list" in
      let kwargs =
        filter_opt [ Some ("l", Py.List.of_list_map Py.String.of_string l) ]
      in
      Py.List.to_list_map Py.String.to_string
      @@ Py.Callable.to_function_with_keywords callable [||] kwargs
  
    let return_opt_list t ~l () =
      let callable = Py.Object.find_attr_string t "return_opt_list" in
      let kwargs =
        filter_opt
          [
            Some
              ( "l",
                Py.List.of_list_map
                  (function Some x -> Py.String.of_string x | None -> Py.none)
                  l );
          ]
      in
      Py.List.to_list_map (fun x ->
          if Py.is_none x then None else Some (Py.String.to_string x))
      @@ Py.Callable.to_function_with_keywords callable [||] kwargs
  
    let bar ~a ~b () =
      let class_ = Py.Module.get (import_module ()) "Silly" in
      let callable = Py.Object.find_attr_string class_ "bar" in
      let kwargs =
        filter_opt [ Some ("a", Py.Int.of_int a); Some ("b", Py.Int.of_int b) ]
      in
      Py.Int.to_int @@ Py.Callable.to_function_with_keywords callable [||] kwargs
  
    let do_nothing2 () =
      let class_ = Py.Module.get (import_module ()) "Silly" in
      let callable = Py.Object.find_attr_string class_ "do_nothing2" in
      let kwargs = filter_opt [] in
      ignore @@ Py.Callable.to_function_with_keywords callable [||] kwargs
  end
  $ dune exec ./run_option.exe 2> /dev/null
  x: 1
  y: 2
  foo: 33
  bar: 30
  (apple pie)
  ((apple) () (pie))

of_pyobject returning Or_error

  $ if [ -f lib.ml ]; then rm lib.ml; fi
  $ pyml_bindgen sigs_or_error.txt silly Silly --caml-module=Silly --of-pyo-ret-type=or_error > lib.ml
  $ ocamlformat --enable-outside-detected-project lib.ml
  open! Base
  
  let filter_opt = List.filter_opt
  
  module Silly : sig
    type t
  
    val of_pyobject : Pytypes.pyobject -> t Or_error.t
  
    val to_pyobject : t -> Pytypes.pyobject
  
    val __init__ : x:int -> y:int -> unit -> t Or_error.t
  
    val x : t -> int
  
    val y : t -> int
  
    val foo : t -> a:int -> b:int -> unit -> int
  
    val do_nothing : t -> unit -> unit
  
    val return_list : t -> l:string list -> unit -> string list
  
    val return_opt_list : t -> l:string option list -> unit -> string option list
  
    val bar : a:int -> b:int -> unit -> int
  
    val do_nothing2 : unit -> unit
  end = struct
    let import_module () = Py.Import.import_module "silly"
  
    type t = Pytypes.pyobject
  
    let is_instance pyo =
      let py_class = Py.Module.get (import_module ()) "Silly" in
      Py.Object.is_instance pyo py_class
  
    let of_pyobject pyo =
      if is_instance pyo then Or_error.return pyo
      else Or_error.error_string "Expected Silly"
  
    let to_pyobject x = x
  
    let __init__ ~x ~y () =
      let callable = Py.Module.get (import_module ()) "Silly" in
      let kwargs =
        filter_opt [ Some ("x", Py.Int.of_int x); Some ("y", Py.Int.of_int y) ]
      in
      of_pyobject @@ Py.Callable.to_function_with_keywords callable [||] kwargs
  
    let x t = Py.Int.to_int @@ Py.Object.find_attr_string t "x"
  
    let y t = Py.Int.to_int @@ Py.Object.find_attr_string t "y"
  
    let foo t ~a ~b () =
      let callable = Py.Object.find_attr_string t "foo" in
      let kwargs =
        filter_opt [ Some ("a", Py.Int.of_int a); Some ("b", Py.Int.of_int b) ]
      in
      Py.Int.to_int @@ Py.Callable.to_function_with_keywords callable [||] kwargs
  
    let do_nothing t () =
      let callable = Py.Object.find_attr_string t "do_nothing" in
      let kwargs = filter_opt [] in
      ignore @@ Py.Callable.to_function_with_keywords callable [||] kwargs
  
    let return_list t ~l () =
      let callable = Py.Object.find_attr_string t "return_list" in
      let kwargs =
        filter_opt [ Some ("l", Py.List.of_list_map Py.String.of_string l) ]
      in
      Py.List.to_list_map Py.String.to_string
      @@ Py.Callable.to_function_with_keywords callable [||] kwargs
  
    let return_opt_list t ~l () =
      let callable = Py.Object.find_attr_string t "return_opt_list" in
      let kwargs =
        filter_opt
          [
            Some
              ( "l",
                Py.List.of_list_map
                  (function Some x -> Py.String.of_string x | None -> Py.none)
                  l );
          ]
      in
      Py.List.to_list_map (fun x ->
          if Py.is_none x then None else Some (Py.String.to_string x))
      @@ Py.Callable.to_function_with_keywords callable [||] kwargs
  
    let bar ~a ~b () =
      let class_ = Py.Module.get (import_module ()) "Silly" in
      let callable = Py.Object.find_attr_string class_ "bar" in
      let kwargs =
        filter_opt [ Some ("a", Py.Int.of_int a); Some ("b", Py.Int.of_int b) ]
      in
      Py.Int.to_int @@ Py.Callable.to_function_with_keywords callable [||] kwargs
  
    let do_nothing2 () =
      let class_ = Py.Module.get (import_module ()) "Silly" in
      let callable = Py.Object.find_attr_string class_ "do_nothing2" in
      let kwargs = filter_opt [] in
      ignore @@ Py.Callable.to_function_with_keywords callable [||] kwargs
  end
  $ dune exec ./run_or_error.exe 2> /dev/null
  x: 1
  y: 2
  foo: 33
  bar: 30
  (apple pie)
  ((apple) () (pie))

