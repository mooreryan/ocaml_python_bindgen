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

  val t2 : x:int * string -> unit -> int * string

  val t3 : x:int * string * float -> unit -> int * string * float

  val t4 : x:int * string * float * bool -> unit -> int * string * float * bool

  val t5 :
    x:int * string * float * bool * int ->
    unit ->
    int * string * float * bool * int

  val t5_list :
    x:(int * string * float * bool * int) list ->
    unit ->
    (int * string * float * bool * int) list

  val t2_pyobject :
    x:Py.Object.t * Pytypes.pyobject -> unit -> Py.Object.t * Pytypes.pyobject

  val t2_pyobject2 :
    x:Pytypes.pyobject * Py.Object.t -> unit -> Pytypes.pyobject * Py.Object.t

  val t2_pyobject_list :
    x:(Py.Object.t * Pytypes.pyobject) list ->
    unit ->
    (Py.Object.t * Pytypes.pyobject) list

  val t2_pyobject2_list :
    x:(Pytypes.pyobject * Py.Object.t) list ->
    unit ->
    (Pytypes.pyobject * Py.Object.t) list
end = struct
  let filter_opt l = List.filter_map Fun.id l

  let t2_map (a, b) ~fa ~fb = (fa a, fb b)

  let t3_map (a, b, c) ~fa ~fb ~fc = (fa a, fb b, fc c)

  let t4_map (a, b, c, d) ~fa ~fb ~fc ~fd = (fa a, fb b, fc c, fd d)

  let t5_map (a, b, c, d, e) ~fa ~fb ~fc ~fd ~fe = (fa a, fb b, fc c, fd d, fe e)

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
    let callable = Py.Module.get (import_module ()) "identity" in
    let kwargs =
      filter_opt [ Some ("x", Py.List.of_list_map Py.Int.of_int x) ]
    in
    Py.List.to_list_map Py.Int.to_int
    @@ Py.Callable.to_function_with_keywords callable [||] kwargs

  let pie_list ~x () =
    let callable = Py.Module.get (import_module ()) "identity" in
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
    let callable = Py.Module.get (import_module ()) "identity" in
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
    let callable = Py.Module.get (import_module ()) "identity" in
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

  let t2 ~x () =
    let callable = Py.Module.get (import_module ()) "identity" in
    let kwargs =
      filter_opt
        [
          Some
            ( "x",
              (fun x ->
                Py.Tuple.of_tuple2
                @@ t2_map ~fa:Py.Int.of_int ~fb:Py.String.of_string x)
                x );
        ]
    in
    (fun x ->
      t2_map ~fa:Py.Int.to_int ~fb:Py.String.to_string @@ Py.Tuple.to_tuple2 x)
    @@ Py.Callable.to_function_with_keywords callable [||] kwargs

  let t3 ~x () =
    let callable = Py.Module.get (import_module ()) "identity" in
    let kwargs =
      filter_opt
        [
          Some
            ( "x",
              (fun x ->
                Py.Tuple.of_tuple3
                @@ t3_map ~fa:Py.Int.of_int ~fb:Py.String.of_string
                     ~fc:Py.Float.of_float x)
                x );
        ]
    in
    (fun x ->
      t3_map ~fa:Py.Int.to_int ~fb:Py.String.to_string ~fc:Py.Float.to_float
      @@ Py.Tuple.to_tuple3 x)
    @@ Py.Callable.to_function_with_keywords callable [||] kwargs

  let t4 ~x () =
    let callable = Py.Module.get (import_module ()) "identity" in
    let kwargs =
      filter_opt
        [
          Some
            ( "x",
              (fun x ->
                Py.Tuple.of_tuple4
                @@ t4_map ~fa:Py.Int.of_int ~fb:Py.String.of_string
                     ~fc:Py.Float.of_float ~fd:Py.Bool.of_bool x)
                x );
        ]
    in
    (fun x ->
      t4_map ~fa:Py.Int.to_int ~fb:Py.String.to_string ~fc:Py.Float.to_float
        ~fd:Py.Bool.to_bool
      @@ Py.Tuple.to_tuple4 x)
    @@ Py.Callable.to_function_with_keywords callable [||] kwargs

  let t5 ~x () =
    let callable = Py.Module.get (import_module ()) "identity" in
    let kwargs =
      filter_opt
        [
          Some
            ( "x",
              (fun x ->
                Py.Tuple.of_tuple5
                @@ t5_map ~fa:Py.Int.of_int ~fb:Py.String.of_string
                     ~fc:Py.Float.of_float ~fd:Py.Bool.of_bool ~fe:Py.Int.of_int
                     x)
                x );
        ]
    in
    (fun x ->
      t5_map ~fa:Py.Int.to_int ~fb:Py.String.to_string ~fc:Py.Float.to_float
        ~fd:Py.Bool.to_bool ~fe:Py.Int.to_int
      @@ Py.Tuple.to_tuple5 x)
    @@ Py.Callable.to_function_with_keywords callable [||] kwargs

  let t5_list ~x () =
    let callable = Py.Module.get (import_module ()) "identity" in
    let kwargs =
      filter_opt
        [
          Some
            ( "x",
              Py.List.of_list_map
                (fun x ->
                  Py.Tuple.of_tuple5
                  @@ t5_map ~fa:Py.Int.of_int ~fb:Py.String.of_string
                       ~fc:Py.Float.of_float ~fd:Py.Bool.of_bool
                       ~fe:Py.Int.of_int x)
                x );
        ]
    in
    Py.List.to_list_map (fun x ->
        t5_map ~fa:Py.Int.to_int ~fb:Py.String.to_string ~fc:Py.Float.to_float
          ~fd:Py.Bool.to_bool ~fe:Py.Int.to_int
        @@ Py.Tuple.to_tuple5 x)
    @@ Py.Callable.to_function_with_keywords callable [||] kwargs

  let t2_pyobject ~x () =
    let callable = Py.Module.get (import_module ()) "identity" in
    let kwargs =
      filter_opt
        [
          Some
            ( "x",
              (fun x ->
                Py.Tuple.of_tuple2 @@ t2_map ~fa:(fun x -> x) ~fb:(fun x -> x) x)
                x );
        ]
    in
    (fun x -> t2_map ~fa:(fun x -> x) ~fb:(fun x -> x) @@ Py.Tuple.to_tuple2 x)
    @@ Py.Callable.to_function_with_keywords callable [||] kwargs

  let t2_pyobject2 ~x () =
    let callable = Py.Module.get (import_module ()) "identity" in
    let kwargs =
      filter_opt
        [
          Some
            ( "x",
              (fun x ->
                Py.Tuple.of_tuple2 @@ t2_map ~fa:(fun x -> x) ~fb:(fun x -> x) x)
                x );
        ]
    in
    (fun x -> t2_map ~fa:(fun x -> x) ~fb:(fun x -> x) @@ Py.Tuple.to_tuple2 x)
    @@ Py.Callable.to_function_with_keywords callable [||] kwargs

  let t2_pyobject_list ~x () =
    let callable = Py.Module.get (import_module ()) "identity" in
    let kwargs =
      filter_opt
        [
          Some
            ( "x",
              Py.List.of_list_map
                (fun x ->
                  Py.Tuple.of_tuple2
                  @@ t2_map ~fa:(fun x -> x) ~fb:(fun x -> x) x)
                x );
        ]
    in
    Py.List.to_list_map (fun x ->
        t2_map ~fa:(fun x -> x) ~fb:(fun x -> x) @@ Py.Tuple.to_tuple2 x)
    @@ Py.Callable.to_function_with_keywords callable [||] kwargs

  let t2_pyobject2_list ~x () =
    let callable = Py.Module.get (import_module ()) "identity" in
    let kwargs =
      filter_opt
        [
          Some
            ( "x",
              Py.List.of_list_map
                (fun x ->
                  Py.Tuple.of_tuple2
                  @@ t2_map ~fa:(fun x -> x) ~fb:(fun x -> x) x)
                x );
        ]
    in
    Py.List.to_list_map (fun x ->
        t2_map ~fa:(fun x -> x) ~fb:(fun x -> x) @@ Py.Tuple.to_tuple2 x)
    @@ Py.Callable.to_function_with_keywords callable [||] kwargs
end
