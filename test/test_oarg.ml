open! Core_kernel
open! Lib

let print x = print_s ([%sexp_of: Oarg.val_spec Or_error.t] x)

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
        (Labeled ((name arg1) (type_ (Tuple2 Int String))))
        (Positional ((type_ Unit))) (Positional ((type_ (Tuple2 Float Bool))))))))

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
