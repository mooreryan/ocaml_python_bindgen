open! Core_kernel
open! Lib

let print x = print_s ([%sexp_of: Oarg.val_spec Or_error.t] x)

let%expect_test _ =
  print @@ Oarg.parse_val_spec "val f : 'a todo";
  [%expect {| (Ok ((py_fun_name f) (ml_fun_name f) (args ((Positional ((type_ Todo))))))) |}]

let%expect_test _ =
  print @@ Oarg.parse_val_spec "val f : 'a not_implemented";
  [%expect
    {|
      (Ok
       ((py_fun_name f) (ml_fun_name f)
        (args ((Positional ((type_ Not_implemented))))))) |}]

let%expect_test _ =
  print @@ Oarg.parse_val_spec "val f : 'a todo option";
  [%expect {|
    (Error
     "Parsing val_spec failed... val_spec parser > parser failed before all input was consumed at token: option") |}]

let%expect_test _ =
  print @@ Oarg.parse_val_spec "val f : 'a not_implemented option";
  [%expect {|
    (Error
     "Parsing val_spec failed... val_spec parser > parser failed before all input was consumed at token: option") |}]

let%expect_test _ =
  print @@ Oarg.parse_val_spec "val f : 'a todo -> unit";
  [%expect
    {|
    (Ok
     ((py_fun_name f) (ml_fun_name f)
      (args ((Positional ((type_ Todo))) (Positional ((type_ Unit))))))) |}]

let%expect_test _ =
  print @@ Oarg.parse_val_spec "val f : 'a not_implemented -> unit";
  [%expect
    {|
    (Ok
     ((py_fun_name f) (ml_fun_name f)
      (args ((Positional ((type_ Not_implemented))) (Positional ((type_ Unit))))))) |}]

let%expect_test _ =
  print @@ Oarg.parse_val_spec "val f : 'a todo -> unit -> unit";
  [%expect
    {|
    (Ok
     ((py_fun_name f) (ml_fun_name f)
      (args
       ((Positional ((type_ Todo))) (Positional ((type_ Unit)))
        (Positional ((type_ Unit))))))) |}]

let%expect_test _ =
  print @@ Oarg.parse_val_spec "val f : 'a not_implemented -> unit -> unit";
  [%expect
    {|
    (Ok
     ((py_fun_name f) (ml_fun_name f)
      (args
       ((Positional ((type_ Not_implemented))) (Positional ((type_ Unit)))
        (Positional ((type_ Unit))))))) |}]

let%expect_test _ =
  print @@ Oarg.parse_val_spec "val f : unit -> 'a todo -> unit";
  [%expect
    {|
    (Ok
     ((py_fun_name f) (ml_fun_name f)
      (args
       ((Positional ((type_ Unit))) (Positional ((type_ Todo)))
        (Positional ((type_ Unit))))))) |}]

let%expect_test _ =
  print @@ Oarg.parse_val_spec "val f : unit -> 'a not_implemented -> unit";
  [%expect
    {|
    (Ok
     ((py_fun_name f) (ml_fun_name f)
      (args
       ((Positional ((type_ Unit))) (Positional ((type_ Not_implemented)))
        (Positional ((type_ Unit))))))) |}]
