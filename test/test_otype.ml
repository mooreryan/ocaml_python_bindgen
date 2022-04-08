open! Base
open Lib
module Q = Base_quickcheck
module QG = Base_quickcheck.Generator

let print_string_or_error x =
  Stdio.print_endline
  @@ Sexp.to_string_hum ~indent:1 ([%sexp_of: Otype.t Or_error.t] x)

let parse_then_py_to_ocaml spec =
  let open Or_error.Let_syntax in
  let%bind parsed = Otype.parse spec in
  (* py_to_ocaml can raise. *)
  match Otype.py_to_ocaml parsed with
  | exception e -> Or_error.of_exn e
  | x -> Or_error.return x

let parse_then_py_of_ocaml spec =
  let open Or_error.Let_syntax in
  let%bind parsed = Otype.parse spec in
  (* py_to_ocaml can raise. *)
  match Otype.py_of_ocaml parsed with
  | exception e -> Or_error.of_exn e
  | x -> Or_error.return x

(* Quickcheck *)

(* Generate good names of custom otypes *)
let gen_custom_otype_string =
  let is_ok_for_name = function
    | 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '_' -> true
    | _ -> false
  in
  let gen_first_letter = QG.char_uppercase in
  let gen_name_char = QG.filter QG.char ~f:is_ok_for_name in
  let gen_name_rest = QG.string_non_empty_of gen_name_char in
  QG.map2 gen_first_letter gen_name_rest ~f:(fun first rest ->
      Char.to_string first ^ rest ^ ".t")

let make_string_test quickcheck_generator :
    (module Q.Test.S with type t = string) =
  (module struct
    type t = string [@@deriving sexp]

    let quickcheck_generator = quickcheck_generator

    let quickcheck_shrinker = Q.Shrinker.string
  end)

let%test_unit "parse function works with custom types" =
  Q.Test.run_exn (make_string_test gen_custom_otype_string) ~f:(fun name ->
      match Or_error.ok_exn @@ Otype.parse name with
      | Custom parsed_name -> [%test_eq: string] parsed_name name
      | _ -> failwith "expected variant Custom")

let%test_unit "parse doesn't raise (may be ok or error though)" =
  Q.Test.run_exn
    (module struct
      type t = string [@@deriving sexp]

      let quickcheck_generator = QG.string_non_empty

      let quickcheck_shrinker = Q.Shrinker.string
    end)
    ~examples:[ "" ]
    ~f:(fun s ->
      let _x = Otype.parse s in
      ())

let%test_unit "container nesting raises or returns error" =
  let gen_otype = QG.of_list [ "array"; "list"; "Seq.t" ] in
  let gen =
    let open QG.Let_syntax in
    let%bind n = QG.int_inclusive 1 100 in
    (* Use n + 1 because we need 2 or more *)
    QG.list_with_length ~length:(n + 1) gen_otype
  in
  Q.Test.run_exn
    (module struct
      type t = string list [@@deriving sexp]

      let quickcheck_generator = gen

      let quickcheck_shrinker = Q.Shrinker.list Q.Shrinker.string
    end)
    ~f:(fun otypes ->
      let s = String.concat otypes ~sep:" " in
      match Otype.parse ("int " ^ s) with
      | (exception _) | Error _ -> ()
      | Ok _ -> failwith "should have failed or raised")

(* test parsing *)

let%expect_test _ =
  print_string_or_error @@ Otype.parse "apple";
  [%expect
    {|
      (Error
       "Parsing Otype failed... otype parser: not a compound, basic, or placeholder otype") |}]

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
       "Parsing Otype failed... otype parser: not a compound, basic, or placeholder otype") |}]

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
  print_string_or_error @@ Otype.parse "int array";
  [%expect {| (Ok (Array Int)) |}]

let%expect_test _ =
  print_string_or_error @@ Otype.parse "float array";
  [%expect {| (Ok (Array Float)) |}]

let%expect_test _ =
  print_string_or_error @@ Otype.parse "string array";
  [%expect {| (Ok (Array String)) |}]

let%expect_test _ =
  print_string_or_error @@ Otype.parse "bool array";
  [%expect {| (Ok (Array Bool)) |}]

let%expect_test _ =
  print_string_or_error @@ Otype.parse "unit array";
  [%expect {| (Ok (Array Unit)) |}]

let%expect_test _ =
  print_string_or_error @@ Otype.parse "t array";
  [%expect {| (Ok (Array T)) |}]

let%expect_test _ =
  print_string_or_error @@ Otype.parse "Span.t array";
  [%expect {| (Ok (Array (Custom Span.t))) |}]

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
       "Parsing Otype failed... otype parser: not a compound, basic, or placeholder otype") |}]

let%expect_test _ =
  print_string_or_error @@ Otype.parse "int Seq.t";
  [%expect {| (Ok (Seq Int)) |}]

let%expect_test _ =
  print_string_or_error @@ Otype.parse "'a todo";
  [%expect {| (Ok Todo) |}]

let%expect_test _ =
  print_string_or_error @@ Otype.parse "'a not_implemented";
  [%expect {| (Ok Not_implemented) |}]

let%expect_test _ =
  print_string_or_error @@ Otype.parse "'b todo";
  [%expect
    {|
      (Error
       "Parsing Otype failed... otype parser: not a compound, basic, or placeholder otype") |}]

let%expect_test _ =
  print_string_or_error @@ Otype.parse "'b not_implemented";
  [%expect
    {|
      (Error
       "Parsing Otype failed... otype parser: not a compound, basic, or placeholder otype") |}]

let%expect_test _ =
  print_string_or_error @@ Otype.parse "'a pizza";
  [%expect
    {|
      (Error
       "Parsing Otype failed... otype parser: not a compound, basic, or placeholder otype") |}]

let%expect_test _ =
  print_string_or_error @@ Otype.parse "'a todo list";
  [%expect {| (Error "Parsing Otype failed... : end_of_input") |}]

let%expect_test _ =
  print_string_or_error @@ Otype.parse "'a todo seq";
  [%expect {| (Error "Parsing Otype failed... : end_of_input") |}]

let%expect_test _ =
  print_string_or_error @@ Otype.parse "'a todo option";
  [%expect {| (Error "Parsing Otype failed... : end_of_input") |}]

let%expect_test _ =
  print_string_or_error @@ Otype.parse "'a todo Or_error.t";
  [%expect {| (Error "Parsing Otype failed... : end_of_input") |}]

let%expect_test _ =
  print_string_or_error @@ Otype.parse "'a not_implemented list";
  [%expect {| (Error "Parsing Otype failed... : end_of_input") |}]

let%expect_test _ =
  print_string_or_error @@ Otype.parse "'a not_implemented seq";
  [%expect {| (Error "Parsing Otype failed... : end_of_input") |}]

let%expect_test _ =
  print_string_or_error @@ Otype.parse "'a not_implemented option";
  [%expect {| (Error "Parsing Otype failed... : end_of_input") |}]

let%expect_test _ =
  print_string_or_error @@ Otype.parse "'a not_implemented Or_error.t";
  [%expect {| (Error "Parsing Otype failed... : end_of_input") |}]

let%expect_test _ =
  print_string_or_error @@ Otype.parse "Apple.Pie.t";
  [%expect {| (Ok (Custom Apple.Pie.t)) |}]

let%expect_test _ =
  print_string_or_error @@ Otype.parse "Good.Apple.Pie.t";
  [%expect {| (Ok (Custom Good.Apple.Pie.t)) |}]

let%expect_test _ =
  print_string_or_error @@ Otype.parse "Good_to.Eat_apple.Pie_always.t";
  [%expect {| (Ok (Custom Good_to.Eat_apple.Pie_always.t)) |}]

let%expect_test _ =
  print_string_or_error @@ Otype.parse "Apple.Pie.thing";
  [%expect {| (Error "Parsing Otype failed... : end_of_input") |}]

let%expect_test _ =
  print_string_or_error @@ Otype.parse "Good.Apple.Pie.thing";
  [%expect {| (Error "Parsing Otype failed... : end_of_input") |}]

let%expect_test _ =
  print_string_or_error @@ Otype.parse "Good_to.Eat_apple.Pie_always.thing";
  [%expect {| (Error "Parsing Otype failed... : end_of_input") |}]

let%expect_test _ =
  print_string_or_error @@ Otype.parse "Apple.pie.t";
  [%expect
    {|
    (Error
     "Parsing Otype failed... otype parser: not a compound, basic, or placeholder otype") |}]

let%expect_test _ =
  print_string_or_error @@ Otype.parse "Good.apple.Pie.t";
  [%expect
    {|
    (Error
     "Parsing Otype failed... otype parser: not a compound, basic, or placeholder otype") |}]

let%expect_test _ =
  print_string_or_error @@ Otype.parse "Good_to.eat_apple.Pie_always.t";
  [%expect
    {|
    (Error
     "Parsing Otype failed... otype parser: not a compound, basic, or placeholder otype") |}]

let%expect_test _ =
  print_string_or_error @@ Otype.parse "Apple.Pie";
  [%expect
    {|
    (Error
     "Parsing Otype failed... otype parser: not a compound, basic, or placeholder otype") |}]

let%expect_test _ =
  print_string_or_error @@ Otype.parse "Good.Apple.Pie";
  [%expect
    {|
    (Error
     "Parsing Otype failed... otype parser: not a compound, basic, or placeholder otype") |}]

let%expect_test _ =
  print_string_or_error @@ Otype.parse "Good_to.Eat_apple.Pie_always";
  [%expect
    {|
    (Error
     "Parsing Otype failed... otype parser: not a compound, basic, or placeholder otype") |}]

let%expect_test _ =
  print_string_or_error @@ Otype.parse "int *string";
  [%expect {| (Ok (Tuple2 Int String)) |}]

let%expect_test _ =
  print_string_or_error @@ Otype.parse "int *string*   float";
  [%expect {| (Ok (Tuple3 Int String Float)) |}]

let%expect_test _ =
  print_string_or_error @@ Otype.parse "int   * string * float*     bool";
  [%expect {| (Ok (Tuple4 Int String Float Bool)) |}]

let%expect_test _ =
  print_string_or_error @@ Otype.parse "int *    string*float*bool *     t";
  [%expect {| (Ok (Tuple5 Int String Float Bool T)) |}]

(* Converting pytypes to ocaml types *)

let%expect_test "Converting list types" =
  let print x =
    Stdio.print_endline @@ Sexp.to_string_hum
    @@ [%sexp_of: string Or_error.t list] x
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
       "Parsing Otype failed... otype parser: not a compound, basic, or placeholder otype")) |}]

let%expect_test "Converting array types" =
  let print x =
    Stdio.print_endline @@ Sexp.to_string_hum
    @@ [%sexp_of: string Or_error.t list] x
  in
  let specs =
    [
      "int array";
      "float array";
      "string array";
      "bool array";
      "unit array";
      "t array";
      "Apple_pie.t array";
      "array array";
    ]
  in
  print @@ List.map specs ~f:parse_then_py_to_ocaml;
  [%expect
    {|
     ((Ok "Py.List.to_array_map Py.Int.to_int")
      (Ok "Py.List.to_array_map Py.Float.to_float")
      (Ok "Py.List.to_array_map Py.String.to_string")
      (Ok "Py.List.to_array_map Py.Bool.to_bool")
      (Ok "Py.List.to_array_map ignore") (Ok "Py.List.to_array_map of_pyobject")
      (Ok "Py.List.to_array_map Apple_pie.of_pyobject")
      (Error
       "Parsing Otype failed... otype parser: not a compound, basic, or placeholder otype")) |}]

let%expect_test "Converting Seq.t types" =
  let print x =
    Stdio.print_endline @@ Sexp.to_string_hum
    @@ [%sexp_of: string Or_error.t list] x
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
       "Parsing Otype failed... otype parser: not a compound, basic, or placeholder otype")) |}]

let%expect_test "Converting option types" =
  let print x =
    Stdio.print_endline @@ Sexp.to_string_hum
    @@ [%sexp_of: string Or_error.t list] x
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
      "Parsing Otype failed... otype parser: not a compound, basic, or placeholder otype")) |}]

let%expect_test "Converting Or_error types" =
  let print x =
    Stdio.print_endline @@ Sexp.to_string_hum
    @@ [%sexp_of: string Or_error.t list] x
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
      "Parsing Otype failed... otype parser: not a compound, basic, or placeholder otype")) |}]

let%expect_test "Most nesting fails" =
  let specs =
    [
      "int Or_error.t array";
      "int Or_error.t list";
      "int Or_error.t Seq.t";
      "int array option";
      "int list option";
      "int Seq.t option";
      "int array Or_error.t";
      "int list Or_error.t";
      "int Seq.t Or_error.t";
      (* Nesting array, list, Seq.t *)
      "int array array";
      "int list list";
      "int Seq.t Seq.t";
      "int array list";
      "int list array";
      "int array Seq.t";
      "int Seq.t array";
      "int list Seq.t";
      "int Seq.t list";
    ]
  in
  Stdio.print_endline @@ Sexp.to_string_hum
  @@ [%sexp_of: string Or_error.t list]
  @@ List.map specs ~f:parse_then_py_to_ocaml;
  [%expect
    {|
     ((Error "Parsing Otype failed... : end_of_input")
      (Error "Parsing Otype failed... : end_of_input")
      (Error "Parsing Otype failed... : end_of_input")
      (Error "Parsing Otype failed... : end_of_input")
      (Error "Parsing Otype failed... : end_of_input")
      (Error "Parsing Otype failed... : end_of_input")
      (Error "Parsing Otype failed... : end_of_input")
      (Error "Parsing Otype failed... : end_of_input")
      (Error "Parsing Otype failed... : end_of_input")
      (Error "Parsing Otype failed... : end_of_input")
      (Error "Parsing Otype failed... : end_of_input")
      (Error "Parsing Otype failed... : end_of_input")
      (Error "Parsing Otype failed... : end_of_input")
      (Error "Parsing Otype failed... : end_of_input")
      (Error "Parsing Otype failed... : end_of_input")
      (Error "Parsing Otype failed... : end_of_input")
      (Error "Parsing Otype failed... : end_of_input")
      (Error "Parsing Otype failed... : end_of_input")) |}]

let%expect_test "Converting option list" =
  let print x =
    Stdio.print_endline @@ Sexp.to_string_hum
    @@ [%sexp_of: string Or_error.t list] x
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
      "Parsing Otype failed... otype parser: not a compound, basic, or placeholder otype")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error
      "Parsing Otype failed... otype parser: not a compound, basic, or placeholder otype")) |}]

let%expect_test "Converting option array" =
  let print x =
    Stdio.print_endline @@ Sexp.to_string_hum
    @@ [%sexp_of: string Or_error.t list] x
  in
  let specs =
    [
      "int option array";
      "float option array";
      "string option array";
      "bool option array";
      "unit option array";
      "t option array";
      "Apple_pie.t option array";
      "option option array";
      "int array option";
      "float array option";
      "string array option";
      "bool array option";
      "unit array option";
      "t array option";
      "Apple_pie.t array option";
      "option array option";
    ]
  in
  print @@ List.map specs ~f:parse_then_py_to_ocaml;
  [%expect
    {|
    ((Ok
      "Py.List.to_array_map (fun x -> if Py.is_none x then None else Some (Py.Int.to_int x))")
     (Ok
      "Py.List.to_array_map (fun x -> if Py.is_none x then None else Some (Py.Float.to_float x))")
     (Ok
      "Py.List.to_array_map (fun x -> if Py.is_none x then None else Some (Py.String.to_string x))")
     (Ok
      "Py.List.to_array_map (fun x -> if Py.is_none x then None else Some (Py.Bool.to_bool x))")
     (Error (Failure "Can't have unit option"))
     (Ok "Py.List.to_array_map of_pyobject")
     (Ok "Py.List.to_array_map Apple_pie.of_pyobject")
     (Error
      "Parsing Otype failed... otype parser: not a compound, basic, or placeholder otype")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error
      "Parsing Otype failed... otype parser: not a compound, basic, or placeholder otype")) |}]

let%expect_test "Converting option seq" =
  let print x =
    Stdio.print_endline @@ Sexp.to_string_hum
    @@ [%sexp_of: string Or_error.t list] x
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
      "Parsing Otype failed... otype parser: not a compound, basic, or placeholder otype")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error
      "Parsing Otype failed... otype parser: not a compound, basic, or placeholder otype"))
|}]

let%expect_test "Converting todo and not_implemented" =
  let print x =
    Stdio.print_endline @@ Sexp.to_string_hum
    @@ [%sexp_of: string Or_error.t list] x
  in
  let specs =
    [
      "'a todo";
      "'a not_implemented";
      "'b todo";
      "'b not_implemented";
      "'a apple_pie";
      "'b apple_pie";
    ]
  in
  print @@ List.map specs ~f:parse_then_py_to_ocaml;
  [%expect
    {|
    ((Ok "") (Ok "")
     (Error
      "Parsing Otype failed... otype parser: not a compound, basic, or placeholder otype")
     (Error
      "Parsing Otype failed... otype parser: not a compound, basic, or placeholder otype")
     (Error
      "Parsing Otype failed... otype parser: not a compound, basic, or placeholder otype")
     (Error
      "Parsing Otype failed... otype parser: not a compound, basic, or placeholder otype")) |}]

let%expect_test "Nested custom modules" =
  let print x =
    Stdio.print_endline @@ Sexp.to_string_hum
    @@ [%sexp_of: string Or_error.t list] x
  in
  let specs =
    [ "Apple.Pie.t"; "Good.Apple.Pie.t"; "Good_to.Eat_apple.Pie_always.t" ]
  in
  print @@ List.map specs ~f:parse_then_py_to_ocaml;
  [%expect
    {|
    ((Ok Apple.Pie.of_pyobject) (Ok Good.Apple.Pie.of_pyobject)
     (Ok Good_to.Eat_apple.Pie_always.of_pyobject)) |}]

let%expect_test "Converting Tuple2 (good)" =
  let print x =
    Stdio.print_endline @@ Sexp.to_string_hum
    @@ [%sexp_of: string Or_error.t list] x
  in
  let specs =
    [
      "int*int";
      "int * string";
      "string   * float";
      "bool*int";
      "Doc.t * t";
      "t*t";
      "T.t*Span_thing.t";
      "(int * int) list";
      "(int * int * int) list";
      "(int * int * int * int) list";
      "(int * int * int * int * int) list";
      "(int * int) array";
      "(int * int) Seq.t";
      "(string * bool) list";
      "(float * t) array";
      "(bool * int) Seq.t";
    ]
  in
  print @@ List.map specs ~f:parse_then_py_to_ocaml;
  [%expect
    {|
    ((Ok
      "(fun x -> t2_map ~fa:Py.Int.to_int ~fb:Py.Int.to_int @@ Py.Tuple.to_tuple2 x)")
     (Ok
      "(fun x -> t2_map ~fa:Py.Int.to_int ~fb:Py.String.to_string @@ Py.Tuple.to_tuple2 x)")
     (Ok
      "(fun x -> t2_map ~fa:Py.String.to_string ~fb:Py.Float.to_float @@ Py.Tuple.to_tuple2 x)")
     (Ok
      "(fun x -> t2_map ~fa:Py.Bool.to_bool ~fb:Py.Int.to_int @@ Py.Tuple.to_tuple2 x)")
     (Ok
      "(fun x -> t2_map ~fa:Doc.of_pyobject ~fb:of_pyobject @@ Py.Tuple.to_tuple2 x)")
     (Ok
      "(fun x -> t2_map ~fa:of_pyobject ~fb:of_pyobject @@ Py.Tuple.to_tuple2 x)")
     (Ok
      "(fun x -> t2_map ~fa:T.of_pyobject ~fb:Span_thing.of_pyobject @@ Py.Tuple.to_tuple2 x)")
     (Ok
      "Py.List.to_list_map (fun x -> t2_map ~fa:Py.Int.to_int ~fb:Py.Int.to_int @@ Py.Tuple.to_tuple2 x)")
     (Ok
      "Py.List.to_list_map (fun x -> t3_map ~fa:Py.Int.to_int ~fb:Py.Int.to_int ~fc:Py.Int.to_int @@ Py.Tuple.to_tuple3 x)")
     (Ok
      "Py.List.to_list_map (fun x -> t4_map ~fa:Py.Int.to_int ~fb:Py.Int.to_int ~fc:Py.Int.to_int ~fd:Py.Int.to_int @@ Py.Tuple.to_tuple4 x)")
     (Ok
      "Py.List.to_list_map (fun x -> t5_map ~fa:Py.Int.to_int ~fb:Py.Int.to_int ~fc:Py.Int.to_int ~fd:Py.Int.to_int ~fe:Py.Int.to_int @@ Py.Tuple.to_tuple5 x)")
     (Ok
      "Py.List.to_array_map (fun x -> t2_map ~fa:Py.Int.to_int ~fb:Py.Int.to_int @@ Py.Tuple.to_tuple2 x)")
     (Ok
      "Py.Iter.to_seq_map (fun x -> t2_map ~fa:Py.Int.to_int ~fb:Py.Int.to_int @@ Py.Tuple.to_tuple2 x)")
     (Ok
      "Py.List.to_list_map (fun x -> t2_map ~fa:Py.String.to_string ~fb:Py.Bool.to_bool @@ Py.Tuple.to_tuple2 x)")
     (Ok
      "Py.List.to_array_map (fun x -> t2_map ~fa:Py.Float.to_float ~fb:of_pyobject @@ Py.Tuple.to_tuple2 x)")
     (Ok
      "Py.Iter.to_seq_map (fun x -> t2_map ~fa:Py.Bool.to_bool ~fb:Py.Int.to_int @@ Py.Tuple.to_tuple2 x)"))
     |}]

let%expect_test "Converting Tuple2 (these won't work)" =
  let print x =
    Stdio.print_endline @@ Sexp.to_string_hum
    @@ [%sexp_of: string Or_error.t list] x
  in
  let specs =
    [
      "int array * string";
      "int list * string";
      "int Seq.t * string";
      "int option * string";
      "int Or_error.t * string";
      "unit * string";
      "int * 'a todo";
      "int * 'a failwith";
      "apple * pie";
      "int * int list";
      "int * int array";
      "int * int Seq.t";
      "int*int*int*int*int*int";
      "int*";
      "*int";
    ]
  in
  print @@ List.map specs ~f:parse_then_py_to_ocaml;
  [%expect
    {|
    ((Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error
      "Parsing Otype failed... otype parser: not a compound, basic, or placeholder otype")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error
      "Parsing Otype failed... otype parser: not a compound, basic, or placeholder otype"))

     |}]

(******************************************************)

(* Converting ocaml types to python types *)

let%expect_test "Converting list types" =
  let print x =
    Stdio.print_endline @@ Sexp.to_string_hum
    @@ [%sexp_of: string Or_error.t list] x
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
       "Parsing Otype failed... otype parser: not a compound, basic, or placeholder otype")) |}]

let%expect_test "Converting array types" =
  let print x =
    Stdio.print_endline @@ Sexp.to_string_hum
    @@ [%sexp_of: string Or_error.t list] x
  in
  let specs =
    [
      "int array";
      "float array";
      "string array";
      "bool array";
      "unit array";
      "t array";
      "Apple_pie.t array";
      "array array";
    ]
  in
  print @@ List.map specs ~f:parse_then_py_of_ocaml;
  [%expect
    {|
     ((Ok "Py.List.of_array_map Py.Int.of_int")
      (Ok "Py.List.of_array_map Py.Float.of_float")
      (Ok "Py.List.of_array_map Py.String.of_string")
      (Ok "Py.List.of_array_map Py.Bool.of_bool")
      (Error (Failure "Can't use unit here"))
      (Ok "Py.List.of_array_map to_pyobject")
      (Ok "Py.List.of_array_map Apple_pie.to_pyobject")
      (Error
       "Parsing Otype failed... otype parser: not a compound, basic, or placeholder otype")) |}]

let%expect_test "Converting Seq.t types" =
  let print x =
    Stdio.print_endline @@ Sexp.to_string_hum
    @@ [%sexp_of: string Or_error.t list] x
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
       "Parsing Otype failed... otype parser: not a compound, basic, or placeholder otype")) |}]

let%expect_test "Converting option types" =
  let print x =
    Stdio.print_endline @@ Sexp.to_string_hum
    @@ [%sexp_of: string Or_error.t list] x
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
      "Parsing Otype failed... otype parser: not a compound, basic, or placeholder otype")) |}]

let%expect_test "Converting Or_error types" =
  let print x =
    Stdio.print_endline @@ Sexp.to_string_hum
    @@ [%sexp_of: string Or_error.t list] x
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
      "Parsing Otype failed... otype parser: not a compound, basic, or placeholder otype")) |}]

let%expect_test "Most nesting fails" =
  let specs =
    [
      (* For now, some triples don't parse. *)
      "int Or_error.t array";
      "int Or_error.t list";
      "int Or_error.t Seq.t";
      "int array option";
      "int list option";
      "int Seq.t option";
      "int array Or_error.t";
      "int list Or_error.t";
      "int Seq.t Or_error.t";
      (* Nesting array, list, Seq.t *)
      "int array array";
      "int list list";
      "int Seq.t Seq.t";
      "int array list";
      "int list array";
      "int array Seq.t";
      "int Seq.t array";
      "int list Seq.t";
      "int Seq.t list";
    ]
  in
  Stdio.print_endline @@ Sexp.to_string_hum
  @@ [%sexp_of: string Or_error.t list]
  @@ List.map specs ~f:parse_then_py_of_ocaml;
  [%expect
    {|
     ((Error "Parsing Otype failed... : end_of_input")
      (Error "Parsing Otype failed... : end_of_input")
      (Error "Parsing Otype failed... : end_of_input")
      (Error "Parsing Otype failed... : end_of_input")
      (Error "Parsing Otype failed... : end_of_input")
      (Error "Parsing Otype failed... : end_of_input")
      (Error "Parsing Otype failed... : end_of_input")
      (Error "Parsing Otype failed... : end_of_input")
      (Error "Parsing Otype failed... : end_of_input")
      (Error "Parsing Otype failed... : end_of_input")
      (Error "Parsing Otype failed... : end_of_input")
      (Error "Parsing Otype failed... : end_of_input")
      (Error "Parsing Otype failed... : end_of_input")
      (Error "Parsing Otype failed... : end_of_input")
      (Error "Parsing Otype failed... : end_of_input")
      (Error "Parsing Otype failed... : end_of_input")
      (Error "Parsing Otype failed... : end_of_input")
      (Error "Parsing Otype failed... : end_of_input")) |}]

let%expect_test "Converting option list" =
  let print x =
    Stdio.print_endline @@ Sexp.to_string_hum
    @@ [%sexp_of: string Or_error.t list] x
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
      "Parsing Otype failed... otype parser: not a compound, basic, or placeholder otype")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error
      "Parsing Otype failed... otype parser: not a compound, basic, or placeholder otype")) |}]

let%expect_test "Converting option array" =
  let print x =
    Stdio.print_endline @@ Sexp.to_string_hum
    @@ [%sexp_of: string Or_error.t list] x
  in
  let specs =
    [
      "int option array";
      "float option array";
      "string option array";
      "bool option array";
      "unit option array";
      "t option array";
      "Apple_pie.t option array";
      "option option array";
      "int array option";
      "float array option";
      "string array option";
      "bool array option";
      "unit array option";
      "t array option";
      "Apple_pie.t array option";
      "option array option";
    ]
  in
  print @@ List.map specs ~f:parse_then_py_of_ocaml;
  [%expect
    {|
    ((Ok
      "Py.List.of_array_map (function Some x -> Py.Int.of_int x | None -> Py.none)")
     (Ok
      "Py.List.of_array_map (function Some x -> Py.Float.of_float x | None -> Py.none)")
     (Ok
      "Py.List.of_array_map (function Some x -> Py.String.of_string x | None -> Py.none)")
     (Ok
      "Py.List.of_array_map (function Some x -> Py.Bool.of_bool x | None -> Py.none)")
     (Error (Failure "Can't have unit option"))
     (Ok "Py.List.of_array_map to_pyobject")
     (Ok "Py.List.of_array_map Apple_pie.to_pyobject")
     (Error
      "Parsing Otype failed... otype parser: not a compound, basic, or placeholder otype")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error
      "Parsing Otype failed... otype parser: not a compound, basic, or placeholder otype")) |}]

let%expect_test "Converting option seq" =
  let print x =
    Stdio.print_endline @@ Sexp.to_string_hum
    @@ [%sexp_of: string Or_error.t list] x
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
      "Parsing Otype failed... otype parser: not a compound, basic, or placeholder otype")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error
      "Parsing Otype failed... otype parser: not a compound, basic, or placeholder otype"))
|}]

let%expect_test "Converting todo and not_implemented" =
  let print x =
    Stdio.print_endline @@ Sexp.to_string_hum
    @@ [%sexp_of: string Or_error.t list] x
  in
  let specs =
    [
      "'a todo";
      "'a not_implemented";
      "'b todo";
      "'b not_implemented";
      "'a apple_pie";
      "'b apple_pie";
    ]
  in
  print @@ List.map specs ~f:parse_then_py_of_ocaml;
  [%expect
    {|
    ((Ok "") (Ok "")
     (Error
      "Parsing Otype failed... otype parser: not a compound, basic, or placeholder otype")
     (Error
      "Parsing Otype failed... otype parser: not a compound, basic, or placeholder otype")
     (Error
      "Parsing Otype failed... otype parser: not a compound, basic, or placeholder otype")
     (Error
      "Parsing Otype failed... otype parser: not a compound, basic, or placeholder otype")) |}]

(* Note: this test is here because I found a bug in the Otype.py_to_ocaml, and
   py_of_ocaml functions. The current tests don't pick up this bug as the parser
   doesn't allow things that would trigger it to hit the function. So test them
   explicitly here. *)
let%expect_test "only basic types can be options (py_to_ocaml)" =
  let otypes =
    [
      Otype.Option (Array Int);
      Otype.Option (List Int);
      Otype.Option (Seq Int);
      Otype.Option (Or_error Int);
      Otype.Option Todo;
      Otype.Option Not_implemented;
    ]
  in
  let results =
    List.map
      ~f:(fun otype -> Or_error.try_with (fun () -> Otype.py_to_ocaml otype))
      otypes
  in
  Stdio.print_s @@ [%sexp_of: string Or_error.t list] results;
  [%expect
    {|
    ((Error (Failure "only basic types can be options"))
     (Error (Failure "only basic types can be options"))
     (Error (Failure "only basic types can be options"))
     (Error (Failure "only basic types can be options"))
     (Error (Failure "only basic types can be options"))
     (Error (Failure "only basic types can be options"))) |}]

let%expect_test "only basic types can be options (py_of_ocaml)" =
  let otypes =
    [
      Otype.Option (Array Int);
      Otype.Option (List Int);
      Otype.Option (Seq Int);
      Otype.Option (Or_error Int);
      Otype.Option Todo;
      Otype.Option Not_implemented;
    ]
  in
  let results =
    List.map
      ~f:(fun otype -> Or_error.try_with (fun () -> Otype.py_of_ocaml otype))
      otypes
  in
  Stdio.print_s @@ [%sexp_of: string Or_error.t list] results;
  [%expect
    {|
    ((Error (Failure "only basic types can be options"))
     (Error (Failure "only basic types can be options"))
     (Error (Failure "only basic types can be options"))
     (Error (Failure "only basic types can be options"))
     (Error (Failure "only basic types can be options"))
     (Error (Failure "only basic types can be options"))) |}]

let%expect_test "Nested custom modules" =
  let print x =
    Stdio.print_endline @@ Sexp.to_string_hum
    @@ [%sexp_of: string Or_error.t list] x
  in
  let specs =
    [ "Apple.Pie.t"; "Good.Apple.Pie.t"; "Good_to.Eat_apple.Pie_always.t" ]
  in
  print @@ List.map specs ~f:parse_then_py_of_ocaml;
  [%expect
    {|
    ((Ok Apple.Pie.to_pyobject) (Ok Good.Apple.Pie.to_pyobject)
     (Ok Good_to.Eat_apple.Pie_always.to_pyobject)) |}]

let%expect_test "Converting Tuple2 (good)" =
  let print x =
    Stdio.print_endline @@ Sexp.to_string_hum
    @@ [%sexp_of: string Or_error.t list] x
  in
  let specs =
    [
      "int*int";
      "int * string";
      "string   * float";
      "bool*int";
      "Doc.t * t";
      "t*t";
      "T.t*Span_thing.t";
      "(int * int) list";
      "(int * int) array";
      "(int * int) Seq.t";
      "(string * bool) list";
      "(float * t) array";
      "(bool * int) Seq.t";
    ]
  in
  print @@ List.map specs ~f:parse_then_py_of_ocaml;
  [%expect
    {|
    ((Ok
      "(fun x -> Py.Tuple.of_tuple2 @@ t2_map ~fa:Py.Int.of_int ~fb:Py.Int.of_int x)")
     (Ok
      "(fun x -> Py.Tuple.of_tuple2 @@ t2_map ~fa:Py.Int.of_int ~fb:Py.String.of_string x)")
     (Ok
      "(fun x -> Py.Tuple.of_tuple2 @@ t2_map ~fa:Py.String.of_string ~fb:Py.Float.of_float x)")
     (Ok
      "(fun x -> Py.Tuple.of_tuple2 @@ t2_map ~fa:Py.Bool.of_bool ~fb:Py.Int.of_int x)")
     (Ok
      "(fun x -> Py.Tuple.of_tuple2 @@ t2_map ~fa:Doc.to_pyobject ~fb:to_pyobject x)")
     (Ok
      "(fun x -> Py.Tuple.of_tuple2 @@ t2_map ~fa:to_pyobject ~fb:to_pyobject x)")
     (Ok
      "(fun x -> Py.Tuple.of_tuple2 @@ t2_map ~fa:T.to_pyobject ~fb:Span_thing.to_pyobject x)")
     (Ok
      "Py.List.of_list_map (fun x -> Py.Tuple.of_tuple2 @@ t2_map ~fa:Py.Int.of_int ~fb:Py.Int.of_int x)")
     (Ok
      "Py.List.of_array_map (fun x -> Py.Tuple.of_tuple2 @@ t2_map ~fa:Py.Int.of_int ~fb:Py.Int.of_int x)")
     (Ok
      "Py.Iter.of_seq_map (fun x -> Py.Tuple.of_tuple2 @@ t2_map ~fa:Py.Int.of_int ~fb:Py.Int.of_int x)")
     (Ok
      "Py.List.of_list_map (fun x -> Py.Tuple.of_tuple2 @@ t2_map ~fa:Py.String.of_string ~fb:Py.Bool.of_bool x)")
     (Ok
      "Py.List.of_array_map (fun x -> Py.Tuple.of_tuple2 @@ t2_map ~fa:Py.Float.of_float ~fb:to_pyobject x)")
     (Ok
      "Py.Iter.of_seq_map (fun x -> Py.Tuple.of_tuple2 @@ t2_map ~fa:Py.Bool.of_bool ~fb:Py.Int.of_int x)")) |}]

let%expect_test "Converting Tuple2 (these won't work)" =
  let print x =
    Stdio.print_endline @@ Sexp.to_string_hum
    @@ [%sexp_of: string Or_error.t list] x
  in
  let specs =
    [
      "int array * string";
      "int list * string";
      "int Seq.t * string";
      "int option * string";
      "int Or_error.t * string";
      "unit * string";
      "int * 'a todo";
      "int * 'a failwith";
      "apple * pie";
      "int * int list";
      "int * int array";
      "int * int Seq.t";
    ]
  in
  print @@ List.map specs ~f:parse_then_py_of_ocaml;
  [%expect
    {|
    ((Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error
      "Parsing Otype failed... otype parser: not a compound, basic, or placeholder otype")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input")
     (Error "Parsing Otype failed... : end_of_input"))
     |}]
