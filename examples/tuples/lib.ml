module Tuples : sig
  type t

  val of_pyobject : Pytypes.pyobject -> t option

  val to_pyobject : t -> Pytypes.pyobject

  val pair : x:int -> y:string -> unit -> int * string

  val identity : x:int * int -> unit -> int * int

  val first : x:int * int -> unit -> int

  val make : ?x:int * int -> unit -> int * int

  val apple : x:int list -> unit -> int list

  val pie_list : x:(int * int) list -> unit -> (int * int) list

  val pie_array : x:(int * int) array -> unit -> (int * int) array

  val pie_seq : x:(int * int) Seq.t -> unit -> (int * int) Seq.t
end = struct
  let filter_opt l = List.filter_map Fun.id l

  let t2_map (a, b) ~fa ~fb = (fa a, fb b)

  let py_module = lazy (Py.Import.import_module "tuples")

  let import_module () = Lazy.force py_module

  type t = Pytypes.pyobject

  let is_instance pyo =
    let py_class = Py.Module.get (import_module ()) "NA" in
    Py.Object.is_instance pyo py_class

  let of_pyobject pyo = if is_instance pyo then Some pyo else None

  let to_pyobject x = x

  let pair ~x ~y () =
    let callable = Py.Module.get (import_module ()) "pair" in
    let kwargs =
      filter_opt
        [ Some ("x", Py.Int.of_int x); Some ("y", Py.String.of_string y) ]
    in
    (fun x ->
      t2_map ~fa:Py.Int.to_int ~fb:Py.String.to_string @@ Py.Tuple.to_tuple2 x)
    @@ Py.Callable.to_function_with_keywords callable [||] kwargs

  let identity ~x () =
    let callable = Py.Module.get (import_module ()) "identity" in
    let kwargs =
      filter_opt
        [
          Some
            ( "x",
              (fun x ->
                Py.Tuple.of_tuple2
                @@ t2_map ~fa:Py.Int.of_int ~fb:Py.Int.of_int x)
                x );
        ]
    in
    (fun x ->
      t2_map ~fa:Py.Int.to_int ~fb:Py.Int.to_int @@ Py.Tuple.to_tuple2 x)
    @@ Py.Callable.to_function_with_keywords callable [||] kwargs

  let first ~x () =
    let callable = Py.Module.get (import_module ()) "first" in
    let kwargs =
      filter_opt
        [
          Some
            ( "x",
              (fun x ->
                Py.Tuple.of_tuple2
                @@ t2_map ~fa:Py.Int.of_int ~fb:Py.Int.of_int x)
                x );
        ]
    in
    Py.Int.to_int @@ Py.Callable.to_function_with_keywords callable [||] kwargs

  let make ?x () =
    let callable = Py.Module.get (import_module ()) "make" in
    let kwargs =
      filter_opt
        [
          (match x with
          | Some x ->
              Some
                ( "x",
                  (fun x ->
                    Py.Tuple.of_tuple2
                    @@ t2_map ~fa:Py.Int.of_int ~fb:Py.Int.of_int x)
                    x )
          | None -> None);
        ]
    in
    (fun x ->
      t2_map ~fa:Py.Int.to_int ~fb:Py.Int.to_int @@ Py.Tuple.to_tuple2 x)
    @@ Py.Callable.to_function_with_keywords callable [||] kwargs

  let apple ~x () =
    let callable = Py.Module.get (import_module ()) "apple" in
    let kwargs =
      filter_opt [ Some ("x", Py.List.of_list_map Py.Int.of_int x) ]
    in
    Py.List.to_list_map Py.Int.to_int
    @@ Py.Callable.to_function_with_keywords callable [||] kwargs

  let pie_list ~x () =
    let callable = Py.Module.get (import_module ()) "pie_list" in
    let kwargs =
      filter_opt
        [
          Some
            ( "x",
              Py.List.of_list_map
                (fun x ->
                  Py.Tuple.of_tuple2
                  @@ t2_map ~fa:Py.Int.of_int ~fb:Py.Int.of_int x)
                x );
        ]
    in
    Py.List.to_list_map (fun x ->
        t2_map ~fa:Py.Int.to_int ~fb:Py.Int.to_int @@ Py.Tuple.to_tuple2 x)
    @@ Py.Callable.to_function_with_keywords callable [||] kwargs

  let pie_array ~x () =
    let callable = Py.Module.get (import_module ()) "pie_array" in
    let kwargs =
      filter_opt
        [
          Some
            ( "x",
              Py.List.of_array_map
                (fun x ->
                  Py.Tuple.of_tuple2
                  @@ t2_map ~fa:Py.Int.of_int ~fb:Py.Int.of_int x)
                x );
        ]
    in
    Py.List.to_array_map (fun x ->
        t2_map ~fa:Py.Int.to_int ~fb:Py.Int.to_int @@ Py.Tuple.to_tuple2 x)
    @@ Py.Callable.to_function_with_keywords callable [||] kwargs

  let pie_seq ~x () =
    let callable = Py.Module.get (import_module ()) "pie_seq" in
    let kwargs =
      filter_opt
        [
          Some
            ( "x",
              Py.Iter.of_seq_map
                (fun x ->
                  Py.Tuple.of_tuple2
                  @@ t2_map ~fa:Py.Int.of_int ~fb:Py.Int.of_int x)
                x );
        ]
    in
    Py.Iter.to_seq_map (fun x ->
        t2_map ~fa:Py.Int.to_int ~fb:Py.Int.to_int @@ Py.Tuple.to_tuple2 x)
    @@ Py.Callable.to_function_with_keywords callable [||] kwargs
end
