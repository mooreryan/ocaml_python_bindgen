open! Core_kernel
open! Lib

module Q = Quickcheck
module QG = Quickcheck.Generator

let spaces = Re2.create_exn "[ \n]+"
let squash_spaces s = Re2.rewrite_exn ~template:" " spaces s
let clean s = String.strip @@ squash_spaces s

let gen_pyml_impl spec =
  let open Or_error.Let_syntax in
  let%bind val_spec = Oarg.parse_val_spec spec in
  let%bind py_fun = Py_fun.create val_spec in
  let class_name = "Apple" in
  return @@ clean @@ Py_fun.pyml_impl class_name py_fun

let bad_spec spec = [%string "bad spec was << %{spec} >>"]

(* Go from a string spec to a pyml_impl. Assert whether it is ok or not. (f
   should be either Or_error.is_ok or is_error. *)
let assert_pyml_impl_is f spec =
  let impl = gen_pyml_impl spec in
  [%test_pred: string Or_error.t] f impl ~message:(bad_spec spec)

let assert_pyml_impl_throws spec =
  match gen_pyml_impl spec with
  | exception _ -> ()
  | _ -> failwith [%string "I expected an exception.  %{bad_spec spec}"]

let assert_pyml_impls_throw specs = List.iter specs ~f:assert_pyml_impl_throws

(* TODO group related assertions using this function. *)
let assert_pyml_impls_are f specs = List.iter specs ~f:(assert_pyml_impl_is f)

(* Not using expect tests here as I don't want dune promote to blow up my
   formatting on the functions...(too hard to read otherwise). *)

let%test_unit "attribute" =
  let val_spec = Or_error.ok_exn @@ Oarg.parse_val_spec "val pie : t -> int" in
  let py_fun = Or_error.ok_exn @@ Py_fun.create val_spec in
  let class_name = "Apple" in
  let expect =
    clean
      {|
let pie t =
  Py.Int.to_int @@ Py.Object.find_attr_string t "pie"
|}
  in
  let actual = clean @@ Py_fun.pyml_impl class_name py_fun in
  [%test_result: string] actual ~expect

let%test_unit "instance method" =
  let val_spec =
    Or_error.ok_exn
    @@ Oarg.parse_val_spec
         "val pie : t -> a:string -> ?b:Food.t -> cat:Animal.t -> ?what:float \
          -> unit -> int"
  in
  let py_fun = Or_error.ok_exn @@ Py_fun.create val_spec in
  let class_name = "Apple" in
  let expect =
    clean
      {|
let pie t ~a ?b ~cat ?what () =
  let callable = Py.Object.find_attr_string t "pie" in
  let kwargs =
    filter_opt
      [
        Some ("a", Py.String.of_string a);
        (match b with
        | Some b -> Some ("b", Food.to_pyobject b)
        | None -> None);
        Some ("cat", Animal.to_pyobject cat);
        (match what with
        | Some what -> Some ("what", Py.Float.of_float what)
        | None -> None);
      ]
  in
  Py.Int.to_int @@ Py.Callable.to_function_with_keywords callable [||] kwargs
|}
  in
  let actual = clean @@ Py_fun.pyml_impl class_name py_fun in
  [%test_result: string] actual ~expect

let%test_unit "special __init__ method" =
  let val_spec =
    Or_error.ok_exn
    @@ Oarg.parse_val_spec "val __init__ : x:int -> y:int -> unit -> t"
  in
  let py_fun = Or_error.ok_exn @@ Py_fun.create val_spec in
  let class_name = "Apple" in
  let expect =
    clean
      {|
let __init__ ~x ~y () =
  let callable = Py.Module.get (import_module ()) "Apple" in
  let kwargs =
    filter_opt
      [
        Some ("x", Py.Int.of_int x);
        Some ("y", Py.Int.of_int y);
      ]
  in
  of_pyobject @@ Py.Callable.to_function_with_keywords callable [||] kwargs
 |}
  in
  let actual = clean @@ Py_fun.pyml_impl class_name py_fun in
  [%test_result: string] actual ~expect

let%test_unit "class method" =
  let val_spec =
    Or_error.ok_exn
    @@ Oarg.parse_val_spec
         "val pie : a:string -> ?b:Food.t -> cat:Animal.t -> ?what:float -> \
          unit -> Cat.t"
  in
  let py_fun = Or_error.ok_exn @@ Py_fun.create val_spec in
  let class_name = "Apple" in
  let expect =
    clean
      {|
let pie ~a ?b ~cat ?what () =
  let class_ = Py.Module.get (import_module ()) "Apple" in
  let callable = Py.Object.find_attr_string class_ "pie" in
  let kwargs =
    filter_opt
      [
        Some ("a", Py.String.of_string a);
        (match b with
        | Some b -> Some ("b", Food.to_pyobject b)
        | None -> None);
        Some ("cat", Animal.to_pyobject cat);
        (match what with
        | Some what -> Some ("what", Py.Float.of_float what)
        | None -> None);
      ]
  in
  Cat.of_pyobject @@ Py.Callable.to_function_with_keywords callable [||] kwargs
 |}
  in
  let actual = clean @@ Py_fun.pyml_impl class_name py_fun in
  [%test_result: string] actual ~expect

let%test_unit "lists are okay" =
  let open Or_error.Let_syntax in
  let spec =
    "val foo : t -> ?apple:string list -> ?pie:Cat.t list -> good:bool -> unit \
     -> Dog.t list"
  in
  let x =
    let%bind val_spec = Oarg.parse_val_spec spec in
    let%bind py_fun = Py_fun.create val_spec in
    let class_name = "Apple" in
    return @@ clean @@ Py_fun.pyml_impl class_name py_fun
  in
  let expect =
    clean
      {|
let foo t ?apple ?pie ~good () =
  let callable = Py.Object.find_attr_string t "foo" in
  let kwargs =
    filter_opt
      [
        (match apple with
        | Some apple ->
            Some ("apple", Py.List.of_list_map Py.String.of_string apple)
        | None -> None);
        (match pie with
        | Some pie -> Some ("pie", Py.List.of_list_map Cat.to_pyobject pie)
        | None -> None);
        Some ("good", Py.Bool.of_bool good);
      ]
  in
  Py.List.to_list_map Dog.of_pyobject
  @@ Py.Callable.to_function_with_keywords callable [||] kwargs
 |}
  in
  let actual = clean @@ Or_error.ok_exn x in
  [%test_result: string] actual ~expect

let%test_unit "lists are okay" =
  let open Or_error.Let_syntax in
  let spec =
    "val foo : t -> ?apple:string list -> ?pie:Cat.t list -> good:bool -> unit \
     -> bool list"
  in
  let x =
    let%bind val_spec = Oarg.parse_val_spec spec in
    let%bind py_fun = Py_fun.create val_spec in
    let class_name = "Apple" in
    return @@ clean @@ Py_fun.pyml_impl class_name py_fun
  in
  let expect =
    clean
      {|
let foo t ?apple ?pie ~good () =
  let callable = Py.Object.find_attr_string t "foo" in
  let kwargs =
    filter_opt
      [
        (match apple with
        | Some apple ->
            Some ("apple", Py.List.of_list_map Py.String.of_string apple)
        | None -> None);
        (match pie with
        | Some pie -> Some ("pie", Py.List.of_list_map Cat.to_pyobject pie)
        | None -> None);
        Some ("good", Py.Bool.of_bool good);
      ]
  in
  Py.List.to_list_map Py.Bool.to_bool
  @@ Py.Callable.to_function_with_keywords callable [||] kwargs
 |}
  in
  let actual = clean @@ Or_error.ok_exn x in
  [%test_result: string] actual ~expect

(* TODO *)
(* let%test_unit "no arg python functions work" =
 *   let val_spec =
 *     Or_error.ok_exn @@ Oarg.parse_val_spec "val f : unit -> t Or_error.t"
 *   in
 *   let py_fun = Or_error.ok_exn @@ Py_fun.create val_spec in
 *   let class_name = "Apple" in
 *   let expect = clean {|
 * let f () =
 *   let callable = Py.Module.get (import_module ()) "Apple" in
 *   let kwargs =
 *     filter_opt
 *       [
 *         Some ("a", Py.String.of_string a);
 *         (match b with
 *         | Some b -> Some ("b", Food.to_pyobject b)
 *         | None -> None);
 *         Some ("cat", Animal.to_pyobject cat);
 *         (match what with
 *         | Some what -> Some ("what", Py.Float.of_float what)
 *         | None -> None);
 *       ]
 *   in
 *   Cat.of_pyobject @@ Py.Callable.to_function_with_keywords callable [||] kwargs
 * |} in
 *   let actual = clean @@ Py_fun.pyml_impl class_name py_fun in
 *   [%test_result: string] actual ~expect *)

(* Checking for errors and okays. *)

let%test_unit "all middle args of instance method must be named" =
  assert_pyml_impl_is Or_error.is_error "val bar : t -> string -> unit -> float"

let%test_unit "all middle args of class method must be named" =
  assert_pyml_impl_is Or_error.is_error "val bar : string -> unit -> float"

let%test_unit "all middle args of class method must be named" =
  assert_pyml_impl_is Or_error.is_ok "val bar : apple:string -> unit -> float"

let%test_unit "all middle args of class method must be named" =
  assert_pyml_impl_is Or_error.is_ok "val bar : ?apple:string -> unit -> float"

let%test_unit _ = assert_pyml_impl_is Or_error.is_error "val pie : t"

(* arg names that start with t are a bit weird...so test a couple *)

let%test_unit "if a name starts with t, it's okay" =
  assert_pyml_impl_is Or_error.is_ok
    "val bar : t -> teehee:string -> unit -> float"

let%test_unit "if a name starts with t, it's okay" =
  assert_pyml_impl_is Or_error.is_ok "val bar : t -> t_:string -> unit -> float"

let%test_unit "if a name starts with t, it's okay" =
  assert_pyml_impl_is Or_error.is_ok
    "val bar : t -> t_t:string -> unit -> float"

let%test_unit "if a name is t, it's an error" =
  assert_pyml_impl_is Or_error.is_error
    "val bar : t -> t:string -> unit -> float"

(* arg names that match types are bad *)

let%test_unit _ =
  assert_pyml_impl_is Or_error.is_error
    "val bar : t -> int:string -> unit -> float"

let%test_unit _ =
  assert_pyml_impl_is Or_error.is_error
    "val bar : t -> float:string -> unit -> float"

let%test_unit _ =
  assert_pyml_impl_is Or_error.is_error
    "val bar : t -> string:string -> unit -> float"

let%test_unit _ =
  assert_pyml_impl_is Or_error.is_error
    "val bar : t -> bool:string -> unit -> float"

let%test_unit _ =
  assert_pyml_impl_is Or_error.is_error
    "val bar : t -> unit:string -> unit -> float"

let%test_unit _ =
  assert_pyml_impl_is Or_error.is_error
    "val bar : t -> Doc.t:string -> unit -> float"

(* arg names that start with types are bad *)

let%test_unit _ =
  assert_pyml_impl_is Or_error.is_error
    "val bar : t -> int_thing:string -> unit -> float"

let%test_unit _ =
  assert_pyml_impl_is Or_error.is_error
    "val bar : t -> float_thing:string -> unit -> float"

let%test_unit _ =
  assert_pyml_impl_is Or_error.is_error
    "val bar : t -> string_thing:string -> unit -> float"

let%test_unit _ =
  assert_pyml_impl_is Or_error.is_error
    "val bar : t -> bool_thing:string -> unit -> float"

let%test_unit _ =
  assert_pyml_impl_is Or_error.is_error
    "val bar : t -> unit_thing:string -> unit -> float"

let%test_unit _ =
  assert_pyml_impl_is Or_error.is_error
    "val bar : t -> Doc.t_thing:string -> unit -> float"

(* arg names that end with types are okay. TODO: these should probably be bad,
   but it's an artifact of the parsing that they are good... *)

let%test_unit _ =
  assert_pyml_impl_is Or_error.is_ok
    "val bar : t -> thing_int:string -> unit -> float"

let%test_unit _ =
  assert_pyml_impl_is Or_error.is_ok
    "val bar : t -> thing_float:string -> unit -> float"

let%test_unit _ =
  assert_pyml_impl_is Or_error.is_ok
    "val bar : t -> thing_string:string -> unit -> float"

let%test_unit _ =
  assert_pyml_impl_is Or_error.is_ok
    "val bar : t -> thing_bool:string -> unit -> float"

let%test_unit _ =
  assert_pyml_impl_is Or_error.is_ok
    "val bar : t -> thing_unit:string -> unit -> float"

let%test_unit "cannot have labeled unit args" =
  assert_pyml_impl_is Or_error.is_error
    "val bar : t -> apple:unit -> unit -> float"

let%test_unit "cannot have optional unit args" =
  assert_pyml_impl_is Or_error.is_error
    "val bar : t -> ?apple:unit -> unit -> float"

let%test_unit "names and args can start with underscores" =
  assert_pyml_impl_is Or_error.is_ok
    "val __bar__ : t -> ?_apple:bool -> unit -> float"

let%test_unit "names and args cannot be only underscores" =
  assert_pyml_impl_is Or_error.is_error "val _ : t -> ?_:Doc.t -> unit -> float"

let%test_unit "names and args cannot be only underscores" =
  assert_pyml_impl_is Or_error.is_error
    "val ____ : t -> ?__:Cat.t -> unit -> float"

(* Seq.t *)

let%test_unit "attribute returning Seq.t" =
  let spec = "val f : t -> int Seq.t" in
  let val_spec = Or_error.ok_exn @@ Oarg.parse_val_spec spec in
  let py_fun = Or_error.ok_exn @@ Py_fun.create val_spec in
  let class_name = "Apple" in
  let expect =
    clean
      {|
let f t =
  Py.Iter.to_seq_map Py.Int.to_int @@ Py.Object.find_attr_string t "f"
|}
  in
  let actual = clean @@ Py_fun.pyml_impl class_name py_fun in
  [%test_result: string] actual ~expect

let%test_unit "Seq.t is for attributes" =
  assert_pyml_impls_are Or_error.is_ok
    [
      "val f : t -> int Seq.t";
      "val f : t -> float Seq.t";
      "val f : t -> string Seq.t";
      "val f : t -> bool Seq.t";
      "val f : t -> t Seq.t";
      "val f : t -> Token.t Seq.t";
      "val f : t -> Apple_pie.t Seq.t";
    ]

let%test_unit "Seq.t is for instance methods" =
  assert_pyml_impls_are Or_error.is_ok
    [
      "val f : t -> a:int Seq.t -> unit -> int Seq.t";
      "val f : t -> a:float Seq.t -> unit -> float Seq.t";
      "val f : t -> a:string Seq.t -> unit -> string Seq.t";
      "val f : t -> a:bool Seq.t -> unit -> bool Seq.t";
      "val f : t -> a:t Seq.t -> unit -> t Seq.t";
      "val f : t -> a:Token.t Seq.t -> unit -> Token.t Seq.t";
      "val f : t -> a:Apple_pie.t Seq.t -> unit -> Apple_pie.t Seq.t";
    ]

let%test_unit "Seq.t is for class methods" =
  assert_pyml_impls_are Or_error.is_ok
    [
      "val f : a:int Seq.t -> unit -> int Seq.t";
      "val f : a:float Seq.t -> unit -> float Seq.t";
      "val f : a:string Seq.t -> unit -> string Seq.t";
      "val f : a:bool Seq.t -> unit -> bool Seq.t";
      "val f : a:t Seq.t -> unit -> t Seq.t";
      "val f : a:Token.t Seq.t -> unit -> Token.t Seq.t";
      "val f : a:Apple_pie.t Seq.t -> unit -> Apple_pie.t Seq.t";
    ]

(* TODO it is confusing that these raise exceptions, but many of the other py
   impl failures return Or_errors *)
let%test_unit "you can't have unit Seq.t as an argument or return value" =
  assert_pyml_impls_throw
    [
      "val f : t -> unit Seq.t";
      "val f : t -> a:unit Seq.t -> unit -> unit Seq.t";
      "val f : a:unit Seq.t -> unit -> unit Seq.t";
      "val f : t -> a:int -> unit -> unit Seq.t";
      "val f : a:int -> unit -> unit Seq.t";
    ]
