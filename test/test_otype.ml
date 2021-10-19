open! Core_kernel
open Lib

module Q = Quickcheck
module QG = Quickcheck.Generator

let print_string_or_error x =
  print_endline
  @@ Sexp.to_string_hum ~indent:1 ([%sexp_of: Otype.t Or_error.t] x)

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

(* test parsing *)

let%expect_test _ =
  print_string_or_error @@ Otype.parse "apple";
  [%expect
    {|
      (Error
       "Parsing Otype failed... parser_ > compound_or_basic parser: Expected compound or basic otype") |}]

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
  [%expect
    {|
      (Error
       "Parsing Otype failed... parser_ > compound_or_basic parser: Expected compound or basic otype") |}]

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
  [%expect
    {|
      (Error
       "Parsing Otype failed... parser_ > compound_or_basic parser: Expected compound or basic otype") |}]

let%expect_test _ =
  print_string_or_error @@ Otype.parse "int Seq.t";
  [%expect {| (Ok (Seq Int)) |}]

(* Converting pytypes to ocaml types *)

let parse_then_py_to_ocaml spec =
  let open Or_error.Let_syntax in
  let%bind parsed = Otype.parse spec in
  (* py_to_ocaml can raise. *)
  match Otype.py_to_ocaml parsed with
  | exception e -> Or_error.of_exn e
  | x -> Or_error.return x

let%expect_test "Converting list types" =
  let print x =
    print_endline @@ Sexp.to_string_hum @@ [%sexp_of: string Or_error.t list] x
  in
  let specs =
    [
      "int list";
      "float list";
      "string list";
      "bool list";
      "unit list";
      "t list";
      "Apple_pie.t list";
      "list list";
    ]
  in
  print @@ List.map specs ~f:parse_then_py_to_ocaml;
  [%expect
    {|
     ((Ok "Py.List.to_list_map Py.Int.to_int")
      (Ok "Py.List.to_list_map Py.Float.to_float")
      (Ok "Py.List.to_list_map Py.String.to_string")
      (Ok "Py.List.to_list_map Py.Bool.to_bool") (Ok "Py.List.to_list_map ignore")
      (Ok "Py.List.to_list_map of_pyobject")
      (Ok "Py.List.to_list_map Apple_pie.of_pyobject")
      (Error
       "Parsing Otype failed... parser_ > compound_or_basic parser: Expected compound or basic otype")) |}]

let%expect_test "Converting Seq.t types" =
  let print x =
    print_endline @@ Sexp.to_string_hum @@ [%sexp_of: string Or_error.t list] x
  in
  let specs =
    [
      "int Seq.t";
      "float Seq.t";
      "string Seq.t";
      "bool Seq.t";
      "unit Seq.t";
      "t Seq.t";
      "Apple_pie.t Seq.t";
      "Seq.t Seq.t";
    ]
  in
  print @@ List.map specs ~f:parse_then_py_to_ocaml;
  [%expect
    {|
     ((Ok "Py.Iter.to_seq_map Py.Int.to_int")
      (Ok "Py.Iter.to_seq_map Py.Float.to_float")
      (Ok "Py.Iter.to_seq_map Py.String.to_string")
      (Ok "Py.Iter.to_seq_map Py.Bool.to_bool") (Ok "Py.Iter.to_seq_map ignore")
      (Ok "Py.Iter.to_seq_map of_pyobject")
      (Ok "Py.Iter.to_seq_map Apple_pie.of_pyobject")
      (Error
       "Parsing Otype failed... parser_ > compound_or_basic parser: Expected compound or basic otype")) |}]

let%expect_test "Converting option types" =
  let print x =
    print_endline @@ Sexp.to_string_hum @@ [%sexp_of: string Or_error.t list] x
  in
  let specs =
    [
      "int option";
      "float option";
      "string option";
      "bool option";
      "unit option";
      "t option";
      "Apple_pie.t option";
      "option option";
    ]
  in
  print @@ List.map specs ~f:parse_then_py_to_ocaml;
  [%expect
    {|
    ((Ok "(fun x -> if Py.is_none x then None else Some (Py.Int.to_int x))")
     (Ok "(fun x -> if Py.is_none x then None else Some (Py.Float.to_float x))")
     (Ok
      "(fun x -> if Py.is_none x then None else Some (Py.String.to_string x))")
     (Ok "(fun x -> if Py.is_none x then None else Some (Py.Bool.to_bool x))")
     (Error (Failure "Can't have unit option")) (Ok of_pyobject)
     (Ok Apple_pie.of_pyobject)
     (Error
      "Parsing Otype failed... parser_ > compound_or_basic parser: Expected compound or basic otype")) |}]

let%expect_test "Converting Or_error types" =
  let print x =
    print_endline @@ Sexp.to_string_hum @@ [%sexp_of: string Or_error.t list] x
  in
  let specs =
    [
      "int Or_error.t";
      "float Or_error.t";
      "string Or_error.t";
      "bool Or_error.t";
      "unit Or_error.t";
      "t Or_error.t";
      "Apple_pie.t Or_error.t";
      "Or_error.t Or_error.t";
    ]
  in
  print @@ List.map specs ~f:parse_then_py_to_ocaml;
  [%expect
    {|
    ((Error (Failure "you can only have <t> Or_error.t or <custom> Or_error.t"))
     (Error (Failure "you can only have <t> Or_error.t or <custom> Or_error.t"))
     (Error (Failure "you can only have <t> Or_error.t or <custom> Or_error.t"))
     (Error (Failure "you can only have <t> Or_error.t or <custom> Or_error.t"))
     (Error (Failure "you can only have <t> Or_error.t or <custom> Or_error.t"))
     (Ok of_pyobject) (Ok Apple_pie.of_pyobject)
     (Error
      "Parsing Otype failed... parser_ > compound_or_basic parser: Expected compound or basic otype")) |}]

let%expect_test "Converting triples fails" =
  let specs =
    [
      (* For now, some triples don't parse. *)
      "int Or_error.t list";
      "int Or_error.t Seq.t";
      "int list option";
      "int Seq.t option";
      "int list Or_error.t";
      "int Seq.t Or_error.t";
    ]
  in
  print_endline @@ Sexp.to_string_hum @@ [%sexp_of: string Or_error.t list]
  @@ List.map specs ~f:parse_then_py_to_ocaml;
  [%expect
    {|
     ((Error "Parsing Otype failed... : end_of_input")
      (Error "Parsing Otype failed... : end_of_input")
      (Error "Parsing Otype failed... : end_of_input")
      (Error "Parsing Otype failed... : end_of_input")
      (Error "Parsing Otype failed... : end_of_input")
      (Error "Parsing Otype failed... : end_of_input")) |}]

let%expect_test "Converting option list" =
  let print x =
    print_endline @@ Sexp.to_string_hum @@ [%sexp_of: string Or_error.t list] x
  in
  let specs =
    [
      "int option list";
      "float option list";
      "string option list";
      "bool option list";
      "unit option list";
      "t option list";
      "Apple_pie.t option list";
      "option option list";
      "int list option";
      "float list option";
      "string list option";
      "bool list option";
      "unit list option";
      "t list option";
      "Apple_pie.t list option";
      "option list option";
    ]
  in
  print @@ List.map specs ~f:parse_then_py_to_ocaml;
  [%expect
    {|
    ((Ok
      "Py.List.to_list_map (fun x -> if Py.is_none x then None else Some (Py.Int.to_int x))")
     (Ok
      "Py.List.to_list_map (fun x -> if Py.is_none x then None else Some (Py.Float.to_float x))")
     (Ok
      "Py.List.to_list_map (fun x -> if Py.is_none x then None else Some (Py.String.to_string x))")
     (Ok
      "Py.List.to_list_map (fun x -> if Py.is_none x then None else Some (Py.Bool.to_bool x))")
     (Error (Failure "Can't have unit option"))
     (Ok "Py.List.to_list_map of_pyobject")
     (Ok "Py.List.to_list_map Apple_pie.of_pyobject")
     (Error
      "Parsing Otype failed... parser_ > compound_or_basic parser: Expected compound or basic otype")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error
      "Parsing Otype failed... parser_ > compound_or_basic parser: Expected compound or basic otype")) |}]

let%expect_test "Converting option seq" =
  let print x =
    print_endline @@ Sexp.to_string_hum @@ [%sexp_of: string Or_error.t list] x
  in
  let specs =
    [
      "int option Seq.t";
      "float option Seq.t";
      "string option Seq.t";
      "bool option Seq.t";
      "unit option Seq.t";
      "t option Seq.t";
      "Apple_pie.t option Seq.t";
      "option option Seq.t";
      "int Seq.t option";
      "float Seq.t option";
      "string Seq.t option";
      "bool Seq.t option";
      "unit Seq.t option";
      "t Seq.t option";
      "Apple_pie.t Seq.t option";
      "option Seq.t option";
    ]
  in
  print @@ List.map specs ~f:parse_then_py_to_ocaml;
  [%expect
    {|
    ((Ok
      "Py.Iter.to_seq_map (fun x -> if Py.is_none x then None else Some (Py.Int.to_int x))")
     (Ok
      "Py.Iter.to_seq_map (fun x -> if Py.is_none x then None else Some (Py.Float.to_float x))")
     (Ok
      "Py.Iter.to_seq_map (fun x -> if Py.is_none x then None else Some (Py.String.to_string x))")
     (Ok
      "Py.Iter.to_seq_map (fun x -> if Py.is_none x then None else Some (Py.Bool.to_bool x))")
     (Error (Failure "Can't have unit option"))
     (Ok "Py.Iter.to_seq_map of_pyobject")
     (Ok "Py.Iter.to_seq_map Apple_pie.of_pyobject")
     (Error
      "Parsing Otype failed... parser_ > compound_or_basic parser: Expected compound or basic otype")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error
      "Parsing Otype failed... parser_ > compound_or_basic parser: Expected compound or basic otype"))
|}]

(******************************************************)

(* Converting ocaml types to python types *)

let parse_then_py_of_ocaml spec =
  let open Or_error.Let_syntax in
  let%bind parsed = Otype.parse spec in
  (* py_to_ocaml can raise. *)
  match Otype.py_of_ocaml parsed with
  | exception e -> Or_error.of_exn e
  | x -> Or_error.return x

let%expect_test "Converting list types" =
  let print x =
    print_endline @@ Sexp.to_string_hum @@ [%sexp_of: string Or_error.t list] x
  in
  let specs =
    [
      "int list";
      "float list";
      "string list";
      "bool list";
      "unit list";
      "t list";
      "Apple_pie.t list";
      "list list";
    ]
  in
  print @@ List.map specs ~f:parse_then_py_of_ocaml;
  [%expect
    {|
     ((Ok "Py.List.of_list_map Py.Int.of_int")
      (Ok "Py.List.of_list_map Py.Float.of_float")
      (Ok "Py.List.of_list_map Py.String.of_string")
      (Ok "Py.List.of_list_map Py.Bool.of_bool")
      (Error (Failure "Can't use unit here"))
      (Ok "Py.List.of_list_map to_pyobject")
      (Ok "Py.List.of_list_map Apple_pie.to_pyobject")
      (Error
       "Parsing Otype failed... parser_ > compound_or_basic parser: Expected compound or basic otype")) |}]

let%expect_test "Converting Seq.t types" =
  let print x =
    print_endline @@ Sexp.to_string_hum @@ [%sexp_of: string Or_error.t list] x
  in
  let specs =
    [
      "int Seq.t";
      "float Seq.t";
      "string Seq.t";
      "bool Seq.t";
      "unit Seq.t";
      "t Seq.t";
      "Apple_pie.t Seq.t";
      "Seq.t Seq.t";
    ]
  in
  print @@ List.map specs ~f:parse_then_py_of_ocaml;
  [%expect
    {|
     ((Ok "Py.Iter.of_seq_map Py.Int.of_int")
      (Ok "Py.Iter.of_seq_map Py.Float.of_float")
      (Ok "Py.Iter.of_seq_map Py.String.of_string")
      (Ok "Py.Iter.of_seq_map Py.Bool.of_bool")
      (Error (Failure "Can't use unit here"))
      (Ok "Py.Iter.of_seq_map to_pyobject")
      (Ok "Py.Iter.of_seq_map Apple_pie.to_pyobject")
      (Error
       "Parsing Otype failed... parser_ > compound_or_basic parser: Expected compound or basic otype")) |}]

let%expect_test "Converting option types" =
  let print x =
    print_endline @@ Sexp.to_string_hum @@ [%sexp_of: string Or_error.t list] x
  in
  let specs =
    [
      "int option";
      "float option";
      "string option";
      "bool option";
      "unit option";
      "t option";
      "Apple_pie.t option";
      "option option";
    ]
  in
  print @@ List.map specs ~f:parse_then_py_of_ocaml;
  [%expect
    {|
    ((Ok "(function Some x -> Py.Int.of_int x | None -> Py.none)")
     (Ok "(function Some x -> Py.Float.of_float x | None -> Py.none)")
     (Ok "(function Some x -> Py.String.of_string x | None -> Py.none)")
     (Ok "(function Some x -> Py.Bool.of_bool x | None -> Py.none)")
     (Error (Failure "Can't have unit option")) (Ok to_pyobject)
     (Ok Apple_pie.to_pyobject)
     (Error
      "Parsing Otype failed... parser_ > compound_or_basic parser: Expected compound or basic otype")) |}]

let%expect_test "Converting Or_error types" =
  let print x =
    print_endline @@ Sexp.to_string_hum @@ [%sexp_of: string Or_error.t list] x
  in
  let specs =
    [
      "int Or_error.t";
      "float Or_error.t";
      "string Or_error.t";
      "bool Or_error.t";
      "unit Or_error.t";
      "t Or_error.t";
      "Apple_pie.t Or_error.t";
      "Or_error.t Or_error.t";
    ]
  in
  print @@ List.map specs ~f:parse_then_py_of_ocaml;
  [%expect
    {|
    ((Error (Failure "you can only have <t> Or_error.t or <custom> Or_error.t"))
     (Error (Failure "you can only have <t> Or_error.t or <custom> Or_error.t"))
     (Error (Failure "you can only have <t> Or_error.t or <custom> Or_error.t"))
     (Error (Failure "you can only have <t> Or_error.t or <custom> Or_error.t"))
     (Error (Failure "you can only have <t> Or_error.t or <custom> Or_error.t"))
     (Ok to_pyobject) (Ok Apple_pie.to_pyobject)
     (Error
      "Parsing Otype failed... parser_ > compound_or_basic parser: Expected compound or basic otype")) |}]

let%expect_test "Converting triples fails" =
  let specs =
    [
      (* For now, some triples don't parse. *)
      "int Or_error.t list";
      "int Or_error.t Seq.t";
      "int list option";
      "int Seq.t option";
      "int list Or_error.t";
      "int Seq.t Or_error.t";
    ]
  in
  print_endline @@ Sexp.to_string_hum @@ [%sexp_of: string Or_error.t list]
  @@ List.map specs ~f:parse_then_py_of_ocaml;
  [%expect
    {|
     ((Error "Parsing Otype failed... : end_of_input")
      (Error "Parsing Otype failed... : end_of_input")
      (Error "Parsing Otype failed... : end_of_input")
      (Error "Parsing Otype failed... : end_of_input")
      (Error "Parsing Otype failed... : end_of_input")
      (Error "Parsing Otype failed... : end_of_input")) |}]

let%expect_test "Converting option list" =
  let print x =
    print_endline @@ Sexp.to_string_hum @@ [%sexp_of: string Or_error.t list] x
  in
  let specs =
    [
      "int option list";
      "float option list";
      "string option list";
      "bool option list";
      "unit option list";
      "t option list";
      "Apple_pie.t option list";
      "option option list";
      "int list option";
      "float list option";
      "string list option";
      "bool list option";
      "unit list option";
      "t list option";
      "Apple_pie.t list option";
      "option list option";
    ]
  in
  print @@ List.map specs ~f:parse_then_py_of_ocaml;
  [%expect
    {|
    ((Ok
      "Py.List.of_list_map (function Some x -> Py.Int.of_int x | None -> Py.none)")
     (Ok
      "Py.List.of_list_map (function Some x -> Py.Float.of_float x | None -> Py.none)")
     (Ok
      "Py.List.of_list_map (function Some x -> Py.String.of_string x | None -> Py.none)")
     (Ok
      "Py.List.of_list_map (function Some x -> Py.Bool.of_bool x | None -> Py.none)")
     (Error (Failure "Can't have unit option"))
     (Ok "Py.List.of_list_map to_pyobject")
     (Ok "Py.List.of_list_map Apple_pie.to_pyobject")
     (Error
      "Parsing Otype failed... parser_ > compound_or_basic parser: Expected compound or basic otype")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error
      "Parsing Otype failed... parser_ > compound_or_basic parser: Expected compound or basic otype")) |}]

let%expect_test "Converting option seq" =
  let print x =
    print_endline @@ Sexp.to_string_hum @@ [%sexp_of: string Or_error.t list] x
  in
  let specs =
    [
      "int option Seq.t";
      "float option Seq.t";
      "string option Seq.t";
      "bool option Seq.t";
      "unit option Seq.t";
      "t option Seq.t";
      "Apple_pie.t option Seq.t";
      "option option Seq.t";
      "int Seq.t option";
      "float Seq.t option";
      "string Seq.t option";
      "bool Seq.t option";
      "unit Seq.t option";
      "t Seq.t option";
      "Apple_pie.t Seq.t option";
      "option Seq.t option";
    ]
  in
  print @@ List.map specs ~f:parse_then_py_of_ocaml;
  [%expect
    {|
    ((Ok
      "Py.Iter.of_seq_map (function Some x -> Py.Int.of_int x | None -> Py.none)")
     (Ok
      "Py.Iter.of_seq_map (function Some x -> Py.Float.of_float x | None -> Py.none)")
     (Ok
      "Py.Iter.of_seq_map (function Some x -> Py.String.of_string x | None -> Py.none)")
     (Ok
      "Py.Iter.of_seq_map (function Some x -> Py.Bool.of_bool x | None -> Py.none)")
     (Error (Failure "Can't have unit option"))
     (Ok "Py.Iter.of_seq_map to_pyobject")
     (Ok "Py.Iter.of_seq_map Apple_pie.to_pyobject")
     (Error
      "Parsing Otype failed... parser_ > compound_or_basic parser: Expected compound or basic otype")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error
      "Parsing Otype failed... parser_ > compound_or_basic parser: Expected compound or basic otype"))
|}]