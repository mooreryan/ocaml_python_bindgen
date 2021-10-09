open! Core_kernel
open Lib

module Q = Quickcheck
module QG = Quickcheck.Generator

(* let%expect_test _ =
 *   print_endline
 *   @@ Sexp.to_string_hum ~indent:1
 *   @@ Otype.sexp_of_t @@ Otype.custom "Doc.t";
 *   [%expect {| hi |}] *)

let print_string_or_error x =
  print_endline
  @@ Sexp.to_string_hum ~indent:1 ([%sexp_of: Otype.t Or_error.t] x)

(* test parsing *)

let%expect_test _ =
  print_string_or_error @@ Otype.parse "apple";
  [%expect {| (Error "Parsing Otype failed... : Bad type string") |}]

let%expect_test _ =
  print_string_or_error @@ Otype.parse "int";
  [%expect {| (Ok Int) |}]

let%expect_test _ =
  print_string_or_error @@ Otype.parse "float";
  [%expect {| (Ok Float) |}]

let%expect_test _ =
  print_string_or_error @@ Otype.parse "string";
  [%expect {| (Ok String) |}]

let%expect_test _ =
  print_string_or_error @@ Otype.parse "bool";
  [%expect {| (Ok Bool) |}]

let%expect_test _ =
  print_string_or_error @@ Otype.parse "unit";
  [%expect {| (Ok Unit) |}]

let%expect_test _ =
  print_string_or_error @@ Otype.parse "t";
  [%expect {| (Ok T) |}]

let%expect_test _ =
  print_string_or_error @@ Otype.parse "Span.t";
  [%expect {| (Ok (Custom Span.t)) |}]

let%expect_test _ =
  print_string_or_error @@ Otype.parse "apple list";
  [%expect {| (Error "Parsing Otype failed... : Bad type string") |}]

let%expect_test _ =
  print_string_or_error @@ Otype.parse "int list";
  [%expect {| (Ok (List Int)) |}]

let%expect_test _ =
  print_string_or_error @@ Otype.parse "float list";
  [%expect {| (Ok (List Float)) |}]

let%expect_test _ =
  print_string_or_error @@ Otype.parse "string list";
  [%expect {| (Ok (List String)) |}]

let%expect_test _ =
  print_string_or_error @@ Otype.parse "bool list";
  [%expect {| (Ok (List Bool)) |}]

let%expect_test _ =
  print_string_or_error @@ Otype.parse "unit list";
  [%expect {| (Ok (List Unit)) |}]

let%expect_test _ =
  print_string_or_error @@ Otype.parse "t list";
  [%expect {| (Ok (List T)) |}]

let%expect_test _ =
  print_string_or_error @@ Otype.parse "Span.t list";
  [%expect {| (Ok (List (Custom Span.t))) |}]

let%expect_test _ =
  print_string_or_error @@ Otype.parse "Span.t thingy";
  [%expect {| (Error "Parsing Otype failed... : end_of_input") |}]

let%expect_test _ =
  print_string_or_error @@ Otype.parse "Span.t int";
  [%expect {| (Error "Parsing Otype failed... : end_of_input") |}]

let%expect_test _ =
  print_string_or_error @@ Otype.parse "int int";
  [%expect {| (Error "Parsing Otype failed... : end_of_input") |}]

let%expect_test _ =
  print_string_or_error @@ Otype.parse "int float";
  [%expect {| (Error "Parsing Otype failed... : end_of_input") |}]

let%expect_test _ =
  print_string_or_error @@ Otype.parse "";
  [%expect {| (Error "Parsing Otype failed... : Bad type string") |}]

(* Quickcheck *)

(* Generate good names of custom otypes *)
let gen_custom_otype_string =
  let is_ok_for_name = function
    | 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '_' -> true
    | _ -> false
  in
  let gen_first_letter = QG.char_uppercase in
  let gen_name_char = QG.filter QG.char ~f:is_ok_for_name in
  let gen_name_rest = String.gen_nonempty' gen_name_char in
  QG.map2 gen_first_letter gen_name_rest ~f:(fun first rest ->
      Char.to_string first ^ rest ^ ".t")

let%test_unit "parse function works with custom types" =
  Q.test gen_custom_otype_string ~sexp_of:String.sexp_of_t ~f:(fun name ->
      match Or_error.ok_exn @@ Otype.parse name with
      | Custom parsed_name -> [%test_eq: string] parsed_name name
      | _ -> failwith "expected variant Custom")

let%test_unit "parse doesn't raise" =
  Q.test String.gen_nonempty ~sexp_of:String.sexp_of_t
    ~shrinker:String.quickcheck_shrinker ~examples:[ "" ] ~f:(fun s ->
      let _x = Otype.parse s in
      ())
