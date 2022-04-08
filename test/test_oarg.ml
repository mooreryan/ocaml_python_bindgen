open! Base
open! Lib

let print x = Stdio.print_s ([%sexp_of: Oarg.val_spec Or_error.t] x)

let%expect_test _ =
  print @@ Oarg.parse_val_spec "val f : 'a todo";
  [%expect {| (Ok ((ml_fun_name f) (args ((Positional ((type_ Todo))))))) |}]

let%expect_test _ =
  print @@ Oarg.parse_val_spec "val f : 'a not_implemented";
  [%expect
    {|
      (Ok ((ml_fun_name f) (args ((Positional ((type_ Not_implemented))))))) |}]

let%expect_test _ =
  print @@ Oarg.parse_val_spec "val f : 'a todo option";
  [%expect
    {|
    (Error
     "Parsing val_spec failed... val_spec parser > parser failed before all input was consumed at token: option") |}]

let%expect_test _ =
  print @@ Oarg.parse_val_spec "val f : 'a not_implemented option";
  [%expect
    {|
    (Error
     "Parsing val_spec failed... val_spec parser > parser failed before all input was consumed at token: option") |}]

let%expect_test _ =
  print @@ Oarg.parse_val_spec "val f : 'a todo -> unit";
  [%expect
    {|
    (Ok
     ((ml_fun_name f)
      (args ((Positional ((type_ Todo))) (Positional ((type_ Unit))))))) |}]

let%expect_test _ =
  print @@ Oarg.parse_val_spec "val f : 'a not_implemented -> unit";
  [%expect
    {|
    (Ok
     ((ml_fun_name f)
      (args ((Positional ((type_ Not_implemented))) (Positional ((type_ Unit))))))) |}]

let%expect_test _ =
  print @@ Oarg.parse_val_spec "val f : 'a todo -> unit -> unit";
  [%expect
    {|
    (Ok
     ((ml_fun_name f)
      (args
       ((Positional ((type_ Todo))) (Positional ((type_ Unit)))
        (Positional ((type_ Unit))))))) |}]

let%expect_test _ =
  print @@ Oarg.parse_val_spec "val f : 'a not_implemented -> unit -> unit";
  [%expect
    {|
    (Ok
     ((ml_fun_name f)
      (args
       ((Positional ((type_ Not_implemented))) (Positional ((type_ Unit)))
        (Positional ((type_ Unit))))))) |}]

let%expect_test _ =
  print @@ Oarg.parse_val_spec "val f : unit -> 'a todo -> unit";
  [%expect
    {|
    (Ok
     ((ml_fun_name f)
      (args
       ((Positional ((type_ Unit))) (Positional ((type_ Todo)))
        (Positional ((type_ Unit))))))) |}]

let%expect_test _ =
  print @@ Oarg.parse_val_spec "val f : unit -> 'a not_implemented -> unit";
  [%expect
    {|
    (Ok
     ((ml_fun_name f)
      (args
       ((Positional ((type_ Unit))) (Positional ((type_ Not_implemented)))
        (Positional ((type_ Unit))))))) |}]

let%expect_test _ =
  print
  @@ Oarg.parse_val_spec "val f : t -> int * string -> unit -> float * bool";
  [%expect
    {|
    (Ok
     ((ml_fun_name f)
      (args
       ((Positional ((type_ T))) (Positional ((type_ (Tuple2 Int String))))
        (Positional ((type_ Unit))) (Positional ((type_ (Tuple2 Float Bool))))))))
     |}]

let%expect_test _ =
  print
  @@ Oarg.parse_val_spec
       "val f : t -> arg1:int * string -> unit -> float * bool";
  [%expect
    {|
    (Ok
     ((ml_fun_name f)
      (args
       ((Positional ((type_ T)))
        (Labeled ((ml_name arg1) (py_name arg1) (type_ (Tuple2 Int String))))
        (Positional ((type_ Unit))) (Positional ((type_ (Tuple2 Float Bool))))))))

     |}]

let%expect_test _ =
  print
  @@ Oarg.parse_val_spec
       "val f : t -> arg1:int * string * bool -> unit -> float * bool * int";
  [%expect
    {|
    (Ok
     ((ml_fun_name f)
      (args
       ((Positional ((type_ T)))
        (Labeled
         ((ml_name arg1) (py_name arg1) (type_ (Tuple3 Int String Bool))))
        (Positional ((type_ Unit)))
        (Positional ((type_ (Tuple3 Float Bool Int)))))))) |}]

let%expect_test _ =
  print
  @@ Oarg.parse_val_spec
       "val f : t -> arg1:int * string * bool * float -> unit -> float * bool \
        * int * string";
  [%expect
    {|
    (Ok
     ((ml_fun_name f)
      (args
       ((Positional ((type_ T)))
        (Labeled
         ((ml_name arg1) (py_name arg1) (type_ (Tuple4 Int String Bool Float))))
        (Positional ((type_ Unit)))
        (Positional ((type_ (Tuple4 Float Bool Int String)))))))) |}]

let%expect_test _ =
  print
  @@ Oarg.parse_val_spec
       "val f : t -> arg1:(int * string * bool * float * int) list -> \
        arg2:(int * int) Seq.t -> arg3:(Pytypes.pyobject * int * Py.Object.t) \
        list -> arg4:Pytypes.pyobject * int * Py.Object.t -> unit -> (int * \
        float * bool * int * string) array";
  [%expect
    {|
    (Ok
     ((ml_fun_name f)
      (args
       ((Positional ((type_ T)))
        (Labeled
         ((ml_name arg1) (py_name arg1)
          (type_ (List (Tuple5 Int String Bool Float Int)))))
        (Labeled ((ml_name arg2) (py_name arg2) (type_ (Seq (Tuple2 Int Int)))))
        (Labeled
         ((ml_name arg3) (py_name arg3)
          (type_ (List (Tuple3 Py_obj Int Py_obj)))))
        (Labeled
         ((ml_name arg4) (py_name arg4) (type_ (Tuple3 Py_obj Int Py_obj))))
        (Positional ((type_ Unit)))
        (Positional ((type_ (Array (Tuple5 Int Float Bool Int String))))))))) |}]

let%expect_test _ =
  print
  @@ Oarg.parse_val_spec
       "val f : t -> arg1:int * string * bool * float * int -> unit -> int * \
        float * bool * int * string";
  [%expect
    {|
    (Ok
     ((ml_fun_name f)
      (args
       ((Positional ((type_ T)))
        (Labeled
         ((ml_name arg1) (py_name arg1)
          (type_ (Tuple5 Int String Bool Float Int))))
        (Positional ((type_ Unit)))
        (Positional ((type_ (Tuple5 Int Float Bool Int String)))))))) |}]

let%expect_test _ =
  print
  @@ Oarg.parse_val_spec "val f : t -> arg1:(int * int) option -> unit -> int";
  [%expect
    {|
    (Error
     "Parsing val_spec failed... val_spec parser > parser failed before all input was consumed at token: ->")
     |}]

let%expect_test _ =
  print
  @@ Oarg.parse_val_spec
       "val f : t -> arg1:int * int -> unit -> (int * int) option";
  [%expect
    {|
    (Error
     "Parsing val_spec failed... val_spec parser > parser failed before all input was consumed at token: ->")
     |}]

let%expect_test _ =
  print
  @@ Oarg.parse_val_spec
       "val f : t -> arg1:(int * int) Or_error.t -> unit -> int";
  [%expect
    {|
    (Error
     "Parsing val_spec failed... val_spec parser > parser failed before all input was consumed at token: ->")
     |}]

let%expect_test _ =
  print
  @@ Oarg.parse_val_spec
       "val f : t -> arg1:int * int -> unit -> (int * int) Or_error.t";
  [%expect
    {|
    (Error
     "Parsing val_spec failed... val_spec parser > parser failed before all input was consumed at token: ->")
     |}]

(* None of these tuple things should work. *)
let%expect_test _ =
  print @@ Oarg.parse_val_spec "val f : t -> arg1:int -> unit -> (int)";
  [%expect
    {|
    (Error
     "Parsing val_spec failed... val_spec parser > parser failed before all input was consumed at token: ->") |}]

let%expect_test _ =
  print @@ Oarg.parse_val_spec "val f : t -> arg1:int -> unit -> (int) list";
  [%expect
    {|
    (Error
     "Parsing val_spec failed... val_spec parser > parser failed before all input was consumed at token: ->") |}]

let%expect_test _ =
  print
  @@ Oarg.parse_val_spec "val f : t -> arg1:int -> unit -> ((int * int)) list";
  [%expect
    {|
    (Error
     "Parsing val_spec failed... val_spec parser > parser failed before all input was consumed at token: ->") |}]

let%expect_test _ =
  print
  @@ Oarg.parse_val_spec "val f : t -> arg1:int -> unit -> (int * list) list";
  [%expect
    {|
    (Error
     "Parsing val_spec failed... val_spec parser > parser failed before all input was consumed at token: ->") |}]

let%expect_test _ =
  print
  @@ Oarg.parse_val_spec "val f : t -> arg1:int -> unit -> (int * (list)) list";
  [%expect
    {|
    (Error
     "Parsing val_spec failed... val_spec parser > parser failed before all input was consumed at token: ->") |}]

let%expect_test _ =
  print
  @@ Oarg.parse_val_spec
       "val f : t -> arg1:int -> unit -> (int * (int * int)) list";
  [%expect
    {|
    (Error
     "Parsing val_spec failed... val_spec parser > parser failed before all input was consumed at token: ->") |}]

let%expect_test _ =
  print
  @@ Oarg.parse_val_spec "val f : t -> arg1:int -> unit -> (int * (int * int))";
  [%expect
    {|
    (Error
     "Parsing val_spec failed... val_spec parser > parser failed before all input was consumed at token: ->") |}]

let%expect_test _ =
  print
  @@ Oarg.parse_val_spec
       "val f : t -> arg1:int -> unit -> ((((int * (int * int))";
  [%expect
    {|
    (Error
     "Parsing val_spec failed... val_spec parser > parser failed before all input was consumed at token: ->") |}]

(* TODO this needs documentation. *)
let%expect_test _ =
  print @@ Oarg.parse_val_spec "val f : t -> arg1:int -> unit -> (int * int)";
  [%expect
    {|
    (Error
     "Parsing val_spec failed... val_spec parser > parser failed before all input was consumed at token: ->") |}]

let%expect_test _ =
  print @@ Oarg.parse_val_spec "val f : t -> arg1:int -> unit -> (int() * int)";
  [%expect
    {|
    (Error
     "Parsing val_spec failed... val_spec parser > parser failed before all input was consumed at token: ->") |}]

let%expect_test _ =
  print
  @@ Oarg.parse_val_spec "val f : t -> arg1:int option * int -> unit -> int";
  [%expect
    {|
    (Error
     "Parsing val_spec failed... val_spec parser > parser failed before all input was consumed at token: *") |}]

let%expect_test _ =
  print
  @@ Oarg.parse_val_spec "val f : t -> arg1:int * int option -> unit -> int";
  [%expect
    {|
    (Error
     "Parsing val_spec failed... val_spec parser > parser failed before all input was consumed at token: option") |}]

let%expect_test _ =
  print
  @@ Oarg.parse_val_spec "val f : t -> arg1:int -> unit -> int option * int";
  [%expect
    {|
    (Error
     "Parsing val_spec failed... val_spec parser > parser failed before all input was consumed at token: *") |}]

let%expect_test _ =
  print
  @@ Oarg.parse_val_spec "val f : t -> arg1:int -> unit -> int * int option";
  [%expect
    {|
    (Error
     "Parsing val_spec failed... val_spec parser > parser failed before all input was consumed at token: option") |}]

let%expect_test _ =
  print
  @@ Oarg.parse_val_spec "val f : t -> arg1:int Or_error.t * int -> unit -> int";
  [%expect
    {|
    (Error
     "Parsing val_spec failed... val_spec parser > parser failed before all input was consumed at token: *") |}]

let%expect_test _ =
  print
  @@ Oarg.parse_val_spec "val f : t -> arg1:int * int Or_error.t -> unit -> int";
  [%expect
    {|
    (Error
     "Parsing val_spec failed... val_spec parser > parser failed before all input was consumed at token: Or_error.t") |}]

let%expect_test _ =
  print
  @@ Oarg.parse_val_spec "val f : t -> arg1:int -> unit -> int Or_error.t * int";
  [%expect
    {|
    (Error
     "Parsing val_spec failed... val_spec parser > parser failed before all input was consumed at token: *") |}]

let%expect_test _ =
  print
  @@ Oarg.parse_val_spec "val f : t -> arg1:int -> unit -> int * int Or_error.t";
  [%expect
    {|
    (Error
     "Parsing val_spec failed... val_spec parser > parser failed before all input was consumed at token: Or_error.t") |}]
