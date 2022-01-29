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

let%test_unit "instance method that returns unit" =
  let val_spec =
    Or_error.ok_exn @@ Oarg.parse_val_spec "val f : t -> unit -> unit"
  in
  let py_fun = Or_error.ok_exn @@ Py_fun.create val_spec in
  let class_name = "Apple" in
  let expect =
    clean
      {|
let f t () =
  let callable = Py.Object.find_attr_string t "f" in
  let kwargs = filter_opt [ ] in
  ignore @@ Py.Callable.to_function_with_keywords callable [||] kwargs
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

let%test_unit "class method returning unit" =
  let val_spec =
    Or_error.ok_exn @@ Oarg.parse_val_spec "val f : unit -> unit"
  in
  let py_fun = Or_error.ok_exn @@ Py_fun.create val_spec in
  let class_name = "Apple" in
  let expect =
    clean
      {|
let f () =
  let class_ = Py.Module.get (import_module ()) "Apple" in
  let callable = Py.Object.find_attr_string class_ "f" in
  let kwargs = filter_opt [ ] in
  ignore @@ Py.Callable.to_function_with_keywords callable [||] kwargs
 |}
  in
  let actual = clean @@ Py_fun.pyml_impl class_name py_fun in
  [%test_result: string] actual ~expect

let%test_unit "module function returning unit" =
  let val_spec =
    Or_error.ok_exn @@ Oarg.parse_val_spec "val f : unit -> unit"
  in
  let py_fun =
    Or_error.ok_exn @@ Py_fun.create val_spec ~associated_with:`Module
  in
  (* Annoying, but you still have to pass in the class name :/ *)
  let class_name = "Apple" in
  let expect =
    clean
      {|
let f () =
  let callable = Py.Module.get (import_module ()) "f" in
  let kwargs = filter_opt [ ] in
  ignore @@ Py.Callable.to_function_with_keywords callable [||] kwargs
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

let%test_unit "no arg python functions work" =
  let val_spec = Or_error.ok_exn @@ Oarg.parse_val_spec "val f : unit -> int" in
  let py_fun = Or_error.ok_exn @@ Py_fun.create val_spec in
  let class_name = "Apple" in
  let expect =
    clean
      {|
let f () =
  let class_ = Py.Module.get (import_module ()) "Apple" in
  let callable = Py.Object.find_attr_string class_ "f" in
  let kwargs = filter_opt [ ] in
  Py.Int.to_int @@ Py.Callable.to_function_with_keywords callable [||] kwargs
|}
  in
  let actual = clean @@ Py_fun.pyml_impl class_name py_fun in
  [%test_result: string] actual ~expect

let%test_unit "todo placeholder" =
  let val_spec =
    Or_error.ok_exn @@ Oarg.parse_val_spec "val apple_pie : 'a todo"
  in
  let py_fun = Or_error.ok_exn @@ Py_fun.create val_spec in
  let class_name = "Apple" in
  let expect = clean {| let apple_pie () = failwith "todo: apple_pie" |} in
  let actual = clean @@ Py_fun.pyml_impl class_name py_fun in
  [%test_result: string] actual ~expect

let%test_unit "not_implemented placeholder" =
  let val_spec =
    Or_error.ok_exn @@ Oarg.parse_val_spec "val apple_pie : 'a not_implemented"
  in
  let py_fun = Or_error.ok_exn @@ Py_fun.create val_spec in
  let class_name = "Apple" in
  let expect =
    clean {| let apple_pie () = failwith "not implemented: apple_pie" |}
  in
  let actual = clean @@ Py_fun.pyml_impl class_name py_fun in
  [%test_result: string] actual ~expect

(* TODO recheck this test! *)
(* let%test_unit "attribute returning option_list" =
 *   let val_spec =
 *     Or_error.ok_exn @@ Oarg.parse_val_spec "val f : t -> "
 *   in
 *   let py_fun =
 *     Or_error.ok_exn @@ Py_fun.create val_spec ~associated_with:`Module
 *   in
 *   (\* Annoying, but you still have to pass in the class name :/ *\)
 *   let class_name = "Apple" in
 *   let expect =
 *     clean
 *       {|
 * let f () =
 *   let callable = Py.Module.get (import_module ()) "f" in
 *   let kwargs = filter_opt [ ] in
 *   ignore @@ Py.Callable.to_function_with_keywords callable [||] kwargs
 * |}
 *   in
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

(* let%test_unit "spaces don't matter" =
 *   assert_pyml_impls_are Or_error.is_error
 *     [ "val f:t->a:int->int"; "val     f   :  t    ->    a  :   int ->    int" ] *)

let%test_unit "attributes cannot return unit" =
  assert_pyml_impls_are Or_error.is_error [ "val f : t -> unit" ]

let%test_unit "everything else CAN return unit" =
  assert_pyml_impls_are Or_error.is_ok
    [
      "val f : t -> unit -> unit";
      "val f : t -> a:int -> unit -> unit";
      "val f : unit -> unit";
      "val f : a:int -> unit -> unit";
    ]

let%test_unit "unit can be in a array, list or seq return type" =
  assert_pyml_impls_are Or_error.is_ok
    [
      "val f : t -> unit array";
      "val f : t -> unit list";
      "val f : t -> unit Seq.t";
      "val f : unit -> unit array";
      "val f : unit -> unit list";
      "val f : unit -> unit Seq.t";
    ]

(* TODO can i merge this test with the one above? *)
let%test_unit "unit can be in Seq.t or list or array in return types" =
  assert_pyml_impls_are Or_error.is_ok
    [
      (* seq *)
      "val f : t -> unit Seq.t";
      "val f : t -> unit -> unit Seq.t";
      "val f : unit -> unit Seq.t";
      "val f : t -> a:int -> unit -> unit Seq.t";
      "val f : a:int -> unit -> unit Seq.t";
      (* list *)
      "val f : t -> unit list";
      "val f : t -> unit -> unit list";
      "val f : unit -> unit list";
      "val f : t -> a:int -> unit -> unit list";
      "val f : a:int -> unit -> unit list";
      (* array *)
      "val f : t -> unit array";
      "val f : t -> unit -> unit array";
      "val f : unit -> unit array";
      "val f : t -> a:int -> unit -> unit array";
      "val f : a:int -> unit -> unit array";
    ]

(* It's brittle, but these actually throw rather than return Or_error. *)
let%test_unit "unit can't be in an option or or_error return type" =
  assert_pyml_impls_throw
    [
      "val f : t -> unit option";
      "val f : unit -> unit option";
      "val f : t -> unit Or_error.t";
      "val f : unit -> unit Or_error.t";
    ]

let%test_unit "unit cannot be in args in functions that aren't 'no arg' python \
               functions" =
  assert_pyml_impls_are Or_error.is_error
    [
      "val f : a:unit -> unit -> unit";
      "val f : a:unit -> ?b:unit -> unit -> unit";
      "val f : unit -> a:unit -> unit -> unit";
    ]

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

(* Note, for now you can only return [t option] or [<custom> option] and
   Or_error. *)

let%test_unit "'no arg' class methods are okay" =
  assert_pyml_impls_are Or_error.is_ok
    [
      "val f : unit -> int";
      "val f : unit -> t";
      "val f : unit -> t option";
      "val f : unit -> t Or_error.t";
      "val f : unit -> Cat.t";
      "val f : unit -> Cat.t option";
      "val f : unit -> Cat.t Or_error.t";
    ]

let%test_unit "but one arg positional only class methods not are okay" =
  assert_pyml_impls_are Or_error.is_error
    [
      "val f : int -> int";
      "val f : int -> t";
      "val f : int -> t option";
      "val f : int -> t Or_error.t";
      "val f : int -> Cat.t";
      "val f : int -> Cat.t option";
      "val f : int -> Cat.t Or_error.t";
    ]

let%test_unit "these were once bugs..." =
  assert_pyml_impls_are Or_error.is_ok
    [ "val foo : x:Tup_int_string.t -> unit -> unit" ]

let%test_unit "option arrays usage that is okay" =
  assert_pyml_impls_are Or_error.is_ok
    [
      "val f : t -> a:int option array -> unit -> int option array";
      "val f : t -> a:float option array -> unit -> float option array";
      "val f : t -> a:string option array -> unit -> int option array";
      "val f : t -> a:bool option array -> unit -> bool option array";
      "val f : t -> a:t option array -> unit -> t option array";
      "val f : t -> a:Apple_pie.t option array -> unit -> Apple_pie.t option \
       array";
    ]

let%test_unit "option arrays usage that is NOT okay" =
  assert_pyml_impls_are Or_error.is_error
    [
      "val f : t -> a:int array option -> unit -> int array option";
      "val f : t -> a:float array option -> unit -> float array option";
      "val f : t -> a:string array option -> unit -> int array option";
      "val f : t -> a:bool array option -> unit -> bool array option";
      "val f : t -> a:t array option -> unit -> t array option";
      "val f : t -> a:Apple_pie.t array option -> unit -> Apple_pie.t option \
       array";
    ]

let%test_unit "option arrays usage that throws" =
  assert_pyml_impls_throw [ "val f : t -> unit option array" ]

let%test_unit "option lists usage that is okay" =
  assert_pyml_impls_are Or_error.is_ok
    [
      "val f : t -> a:int option list -> unit -> int option list";
      "val f : t -> a:float option list -> unit -> float option list";
      "val f : t -> a:string option list -> unit -> int option list";
      "val f : t -> a:bool option list -> unit -> bool option list";
      "val f : t -> a:t option list -> unit -> t option list";
      "val f : t -> a:Apple_pie.t option list -> unit -> Apple_pie.t option \
       list";
    ]

let%test_unit "option lists usage that is NOT okay" =
  assert_pyml_impls_are Or_error.is_error
    [
      "val f : t -> a:int list option -> unit -> int list option";
      "val f : t -> a:float list option -> unit -> float list option";
      "val f : t -> a:string list option -> unit -> int list option";
      "val f : t -> a:bool list option -> unit -> bool list option";
      "val f : t -> a:t list option -> unit -> t list option";
      "val f : t -> a:Apple_pie.t list option -> unit -> Apple_pie.t option \
       list";
    ]

let%test_unit "option lists usage that throws" =
  assert_pyml_impls_throw [ "val f : t -> unit option list" ]

let%test_unit "option Seq.ts usage that is okay" =
  assert_pyml_impls_are Or_error.is_ok
    [
      "val f : t -> a:int option Seq.t -> unit -> int option Seq.t";
      "val f : t -> a:float option Seq.t -> unit -> float option Seq.t";
      "val f : t -> a:string option Seq.t -> unit -> int option Seq.t";
      "val f : t -> a:bool option Seq.t -> unit -> bool option Seq.t";
      "val f : t -> a:t option Seq.t -> unit -> t option Seq.t";
      "val f : t -> a:Apple_pie.t option Seq.t -> unit -> Apple_pie.t option \
       Seq.t";
    ]

let%test_unit "option Seq.ts usage that is NOT okay" =
  assert_pyml_impls_are Or_error.is_error
    [
      "val f : t -> a:int Seq.t option -> unit -> int Seq.t option";
      "val f : t -> a:float Seq.t option -> unit -> float Seq.t option";
      "val f : t -> a:string Seq.t option -> unit -> int Seq.t option";
      "val f : t -> a:bool Seq.t option -> unit -> bool Seq.t option";
      "val f : t -> a:t Seq.t option -> unit -> t Seq.t option";
      "val f : t -> a:Apple_pie.t Seq.t option -> unit -> Apple_pie.t option \
       Seq.t";
    ]

let%test_unit "option Seq.ts usage that throws" =
  assert_pyml_impls_throw [ "val f : t -> unit option Seq.t" ]

(* Placeholder types *)

let%test_unit "todo and not_implemented by themselves are okay" =
  assert_pyml_impls_are Or_error.is_ok
    [ "val f : 'a todo"; "val f : 'a not_implemented" ]

let%test_unit "todo and not_implemented can't be with other stuff" =
  assert_pyml_impls_are Or_error.is_error
    [
      "val f : t -> 'a todo -> unit";
      "val f : t -> 'a not_implemented -> unit";
      "val f : t -> 'a todo -> unit -> unit";
      "val f : t -> 'a not_implemented -> unit -> unit";
      "val f : 'a todo -> unit";
      "val f : 'a not_implemented -> unit";
      "val f : 'a todo -> unit -> unit";
      "val f : 'a not_implemented -> unit -> unit";
      "val f : unit -> 'a todo -> unit";
      "val f : unit ->'a not_implemented -> unit";
      "val f : unit ->'a todo -> unit -> unit";
      "val f : unit ->'a not_implemented -> unit -> unit";
    ]
