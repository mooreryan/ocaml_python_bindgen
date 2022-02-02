module Lib = struct
  module Adder : sig
    type t

    val of_pyobject : Pytypes.pyobject -> t option

    val to_pyobject : t -> Pytypes.pyobject

    val add : x:int -> y:int -> unit -> int
  end = struct
    let filter_opt l = List.filter_map Fun.id l

    let import_module () = Py.Import.import_module "adder"

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
      Py.Int.to_int
      @@ Py.Callable.to_function_with_keywords callable [||] kwargs
  end

  module Adder_cached : sig
    type t

    val of_pyobject : Pytypes.pyobject -> t option

    val to_pyobject : t -> Pytypes.pyobject

    val add : x:int -> y:int -> unit -> int
  end = struct
    let filter_opt l = List.filter_map Fun.id l

    let imported_module =
      if not (Py.is_initialized ()) then Py.initialize ();
      Py.Import.import_module "adder"

    type t = Pytypes.pyobject

    let is_instance pyo =
      let py_class = Py.Module.get imported_module "Adder" in
      Py.Object.is_instance pyo py_class

    let of_pyobject pyo = if is_instance pyo then Some pyo else None

    let to_pyobject x = x

    let add ~x ~y () =
      let class_ = Py.Module.get imported_module "Adder" in
      let callable = Py.Object.find_attr_string class_ "add" in
      let kwargs =
        filter_opt [ Some ("x", Py.Int.of_int x); Some ("y", Py.Int.of_int y) ]
      in
      Py.Int.to_int
      @@ Py.Callable.to_function_with_keywords callable [||] kwargs
  end

  module Adder_lazy : sig
    type t

    val of_pyobject : Pytypes.pyobject -> t option

    val to_pyobject : t -> Pytypes.pyobject

    val add : x:int -> y:int -> unit -> int
  end = struct
    let filter_opt l = List.filter_map Fun.id l

    let imported_module = lazy (Py.Import.import_module "adder")

    type t = Pytypes.pyobject

    let is_instance pyo =
      let m = Lazy.force imported_module in
      let py_class = Py.Module.get m "Adder" in
      Py.Object.is_instance pyo py_class

    let of_pyobject pyo = if is_instance pyo then Some pyo else None

    let to_pyobject x = x

    let add ~x ~y () =
      let m = Lazy.force imported_module in
      let class_ = Py.Module.get m "Adder" in
      let callable = Py.Object.find_attr_string class_ "add" in
      let kwargs =
        filter_opt [ Some ("x", Py.Int.of_int x); Some ("y", Py.Int.of_int y) ]
      in
      Py.Int.to_int
      @@ Py.Callable.to_function_with_keywords callable [||] kwargs
  end

  module Adder_lazy_fun : sig
    type t

    val of_pyobject : Pytypes.pyobject -> t option

    val to_pyobject : t -> Pytypes.pyobject

    val add : x:int -> y:int -> unit -> int
  end = struct
    let filter_opt l = List.filter_map Fun.id l

    let lazy_import_module =
      Lazy.from_fun (fun () -> Py.Import.import_module "adder")

    let import_module () = Lazy.force lazy_import_module

    type t = Pytypes.pyobject

    let is_instance pyo =
      let m = import_module () in
      let py_class = Py.Module.get m "Adder" in
      Py.Object.is_instance pyo py_class

    let of_pyobject pyo = if is_instance pyo then Some pyo else None

    let to_pyobject x = x

    let add ~x ~y () =
      let m = import_module () in
      let class_ = Py.Module.get m "Adder" in
      let callable = Py.Object.find_attr_string class_ "add" in
      let kwargs =
        filter_opt [ Some ("x", Py.Int.of_int x); Some ("y", Py.Int.of_int y) ]
      in
      Py.Int.to_int
      @@ Py.Callable.to_function_with_keywords callable [||] kwargs
  end

  module Adder_embedded : sig
    type t

    val of_pyobject : Pytypes.pyobject -> t option

    val to_pyobject : t -> Pytypes.pyobject

    val add : x:int -> y:int -> unit -> int
  end = struct
    let filter_opt l = List.filter_map Fun.id l

    let import_module () =
      let source =
        {pyml_bindgen_string_literal|class Adder:
    @staticmethod
    def add(x, y):
        return x + y
|pyml_bindgen_string_literal}
      in
      let filename =
        {pyml_bindgen_string_literal|adder.py|pyml_bindgen_string_literal}
      in
      let bytecode = Py.compile ~filename ~source `Exec in
      Py.Import.exec_code_module
        {pyml_bindgen_string_literal|adder|pyml_bindgen_string_literal} bytecode

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
      Py.Int.to_int
      @@ Py.Callable.to_function_with_keywords callable [||] kwargs
  end

  module Adder_embedded_lazy : sig
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
           {pyml_bindgen_string_literal|adder.py|pyml_bindgen_string_literal}
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
      Py.Int.to_int
      @@ Py.Callable.to_function_with_keywords callable [||] kwargs
  end

  module Adder_cached_embedded : sig
    type t

    val of_pyobject : Pytypes.pyobject -> t option

    val to_pyobject : t -> Pytypes.pyobject

    val add : x:int -> y:int -> unit -> int
  end = struct
    let filter_opt l = List.filter_map Fun.id l

    let imported_module =
      if not (Py.is_initialized ()) then Py.initialize ();
      let source =
        {pyml_bindgen_string_literal|class Adder:
    @staticmethod
    def add(x, y):
        return x + y
|pyml_bindgen_string_literal}
      in
      let filename =
        {pyml_bindgen_string_literal|adder.py|pyml_bindgen_string_literal}
      in
      let bytecode = Py.compile ~filename ~source `Exec in
      Py.Import.exec_code_module
        {pyml_bindgen_string_literal|adder|pyml_bindgen_string_literal} bytecode

    type t = Pytypes.pyobject

    let is_instance pyo =
      let py_class = Py.Module.get imported_module "Adder" in
      Py.Object.is_instance pyo py_class

    let of_pyobject pyo = if is_instance pyo then Some pyo else None

    let to_pyobject x = x

    let add ~x ~y () =
      let class_ = Py.Module.get imported_module "Adder" in
      let callable = Py.Object.find_attr_string class_ "add" in
      let kwargs =
        filter_opt [ Some ("x", Py.Int.of_int x); Some ("y", Py.Int.of_int y) ]
      in
      Py.Int.to_int
      @@ Py.Callable.to_function_with_keywords callable [||] kwargs
  end
end

open! Core
open! Core_bench

let () = if not (Py.is_initialized ()) then Py.initialize ()

let () =
  let open Lib in
  let bench name f = Bench.Test.create ~name (fun () -> f ()) in
  Command.run
    (Bench.make_command
       [
         bench "Adder.add" (fun () -> Adder.add ~x:10 ~y:20 ());
         bench "Adder_cached.add" (fun () -> Adder_cached.add ~x:10 ~y:20 ());
         bench "Adder_lazy.add" (fun () -> Adder_lazy.add ~x:10 ~y:20 ());
         bench "Adder_lazy_fun.add" (fun () ->
             Adder_lazy_fun.add ~x:10 ~y:20 ());
         bench "Adder_embedded.add" (fun () ->
             Adder_embedded.add ~x:10 ~y:20 ());
         bench "Adder_embedded_lazy.add" (fun () ->
             Adder_embedded_lazy.add ~x:10 ~y:20 ());
         bench "Adder_cached_embedded.add" (fun () ->
             Adder_cached_embedded.add ~x:10 ~y:20 ());
       ])
