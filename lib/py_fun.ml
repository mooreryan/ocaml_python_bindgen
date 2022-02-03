open! Base
open Or_error
open Or_error.Let_syntax

type py_fun_args =
  [ `Labeled of Oarg.labeled | `Optional of Oarg.optional ] list
[@@deriving sexp]

(* All non- [t] args have to be named. All of the functions with named args need
   to end in unit -> 'ret_type *)
type t =
  (* [val f : t -> 'a]. Properties and attributes are both treated as
     attributes. *)
  | Attribute of { fun_name : string; return_type : Otype.t }
  (* [val f : t -> a:'a -> ... -> unit -> 'b]. Instance methods that take no
     arguments will take [t] and [unit] in spacy.ml code. E.g., [val f : t ->
     unit -> a] would be something like this in python: [t.f() -> 'a] *)
  | Instance_method of {
      fun_name : string;
      return_type : Otype.t;
      (* this can be empty. eg val f : t -> unit -> 'a. penultimate arg IS
         ALWAYS UNIT, so it is dropped. t -> 'a -> unit -> 'b, 'a would be in
         here. *)
      args : py_fun_args;
    }
  (* [val f : a:'a -> ... -> 'b] *)
  | Class_method of {
      fun_name : string;
      return_type : Otype.t;
      (* this can be empty. eg val f : unit -> 'a. penultimate arg (which may be
         first arg) IS ALWAYS UNIT, so it is dropped. 'a -> unit -> 'b, 'a would
         be in here. f : unit -> 'a would be like Class.f() -> 'a in python. *)
      args : py_fun_args;
    }
  (* Same info as class method but the impl is different. *)
  | Module_function of {
      fun_name : string;
      return_type : Otype.t;
      args : py_fun_args;
    }
  | Todo_function of string
  | Not_implemented_function of string
[@@deriving sexp]

(* Python Attribute specs look like this: val : t -> 'a *)
let parse_attribute fun_name args =
  let ary = Array.of_list args in
  match Array.length ary with
  | 2 -> (
      let t_arg = ary.(0) in
      let return_type_arg = ary.(1) in
      let first_good = Oarg.is_positional_t t_arg in
      let second_good = Oarg.is_positional_non_unit return_type_arg in
      match (first_good, second_good) with
      | true, true ->
          let return_type = Oarg.type_ return_type_arg in
          Some (Attribute { fun_name; return_type })
      | _, _ -> None)
  | _n -> None

(* All args must be named other than the first. The first must be t. If the
   final "real" arg is optional, then you need to have a final unit before the
   return value or else the optional argument won't be able to be erased. It's
   actually fairly common for the final arg in python to be optional keyword
   arg. So to keep things the same across the api, all instance methods will
   have the final unit argument :) Then the signature should end in ... -> unit
   -> 'a. *)
let parse_instance_method fun_name args =
  (* Minimum of three args: t -> unit -> 'a *)
  let ary = Array.of_list args in
  let nargs = Array.length ary in
  if nargs < 3 then None
  else
    let t_arg = ary.(0) in
    let penultimate_unit_arg = Array.get ary (nargs - 2) in
    let return_type_arg = Array.last ary in
    let other_args = Array.sub ary ~pos:1 ~len:(nargs - 3) in
    let t_arg_good = Oarg.is_positional_t t_arg in
    let penultimate_unit_arg_good =
      Oarg.is_positional_unit penultimate_unit_arg
    in
    let return_type_arg_good = Oarg.is_positional return_type_arg in
    let other_args = Oarg.parse_labeled_or_optional_non_unit other_args in
    match
      (t_arg_good, return_type_arg_good, penultimate_unit_arg_good, other_args)
    with
    | true, true, true, Ok args ->
        let return_type = Oarg.type_ return_type_arg in
        Some (Instance_method { fun_name; return_type; args })
    | _ -> None

(* One slightly weird thing...you could envision a class method that acutally
   does take an instance of the type as the first argument, but to make it
   easier to differentiate from the instance methods, we will assume any fun
   that starts with an unnamed [t] to be an instance method. If it is a named
   [t] as the first arg, e.g., [apple:t] then it may be a class method. Also
   note that python class methods you can still call on instances...but hey
   :) *)
let parse_class_or_module_method associated_with fun_name args =
  (* Even a class method that takes no args in python will take at least unit ->
     unit in your val_spec. 'a -> unit *)
  let constructor fun_name return_type args = function
    | `Class -> Class_method { fun_name; return_type; args }
    | `Module -> Module_function { fun_name; return_type; args }
  in
  let ary = Array.of_list args in
  match Array.length ary with
  | 0 | 1 -> None
  | 2 -> (
      let first_unit_arg = ary.(0) in
      let return_type_arg = ary.(1) in
      let first_good = Oarg.is_positional_unit first_unit_arg in
      let last_good = Oarg.is_positional return_type_arg in
      match (first_good, last_good) with
      | true, true ->
          let return_type = Oarg.type_ return_type_arg in
          Some (constructor fun_name return_type [] associated_with)
      | _, _ -> None)
  | nargs -> (
      let penultimate_unit_arg = Array.get ary (nargs - 2) in
      let return_type_arg = Array.last ary in
      let other_args = Array.sub ary ~pos:0 ~len:(nargs - 2) in
      let penultimate_unit_arg_good =
        Oarg.is_positional_unit penultimate_unit_arg
      in
      let return_type_arg_good = Oarg.is_positional return_type_arg in
      let other_args = Oarg.parse_labeled_or_optional_non_unit other_args in
      match (penultimate_unit_arg_good, return_type_arg_good, other_args) with
      | true, true, Ok args ->
          let return_type = Oarg.type_ return_type_arg in
          Some (constructor fun_name return_type args associated_with)
      | _ -> None)

let parse_todo_placeholder fun_name args =
  match List.length args with
  | 1 ->
      let arg = List.hd_exn args in
      if Oarg.is_positional_todo arg then Some (Todo_function fun_name)
      else None
  | _ -> None

let parse_not_implemented_placeholder fun_name args =
  match List.length args with
  | 1 ->
      let arg = List.hd_exn args in
      if Oarg.is_positional_not_implemented arg then
        Some (Not_implemented_function fun_name)
      else None
  | _ -> None

(* [associated_with] is ignored unless the parsing matches a class method. *)
let create ?(associated_with = `Class) { Oarg.fun_name; args } =
  match
    ( parse_attribute fun_name args,
      parse_instance_method fun_name args,
      parse_class_or_module_method associated_with fun_name args,
      parse_todo_placeholder fun_name args,
      parse_not_implemented_placeholder fun_name args )
  with
  | Some py_fun, None, None, None, None
  | None, Some py_fun, None, None, None
  | None, None, None, Some py_fun, None
  | None, None, None, None, Some py_fun ->
      return py_fun
  | None, None, Some py_fun, None, None -> (
      match associated_with with
      | `Class -> return py_fun
      | `Module -> return py_fun)
  | _ -> error_string "could not create val_spec"

let labeled_arg_to_kwarg_spec arg =
  let name = Oarg.labeled_name arg in
  let type_ = Oarg.labeled_type arg in
  let py_of_ocaml = Otype.py_of_ocaml type_ in
  (* Adds the semicolon so that you can join all the args with concat "" later
     on. *)
  [%string {| Some ("%{name}", %{py_of_ocaml} %{name});  |}]

(* The ocaml code will have to determine if the caller actually passed in an
   optional arg or just left in out. And then pass it or not to the python
   runtime. *)
let optional_arg_to_kwarg_spec arg =
  let name = Oarg.optional_name arg in
  let type_ = Oarg.optional_type arg in
  let py_of_ocaml = Otype.py_of_ocaml type_ in
  let some_spec =
    (* Adds the semicolon so that you can join all the args with concat "" later
       on. *)
    [%string {| Some ("%{name}", %{py_of_ocaml} %{name})  |}]
  in
  let none_spec = "None" in
  [%string
    {| (match %{name} with | Some %{name} -> %{some_spec} | None -> %{none_spec}); |}]

let arg_to_kwarg_spec = function
  | `Labeled arg -> labeled_arg_to_kwarg_spec arg
  | `Optional arg -> optional_arg_to_kwarg_spec arg

(* let f a ?b ?c () <- this gives a ?b ?c *)
let get_var_names args =
  String.concat ~sep:" "
  @@ List.map args ~f:(function
       | `Labeled arg -> "~" ^ Oarg.labeled_name arg
       | `Optional arg -> "?" ^ Oarg.optional_name arg)

(* TODO mixing optionals and non-optionals is fine on the OCaml side, but it's
   weird from a python standpoint. *)
(* Note: [filter_opt] should be defined by the user, or in the pyml_bindgen cli
   program. It's basically a way to get [List.filter_map Fun.id] whether you're
   using Base or not. *)
let get_kwargs args =
  let arg_list = String.concat ~sep:"" @@ List.map args ~f:arg_to_kwarg_spec in
  [%string {| let kwargs = filter_opt [ %{arg_list} ] in |}]

(* __init__ is a special function in python and is called right on the class
   name like this: Apple(1, 2). *)
(* IMPORTANT this assumes you have an import_module function in scope... it
   should look something like this: [let import_module () =
   Py.Import.import_module "module_name_here"] *)
let init_impl ~class_name ~fun_name return_type args =
  let py_to_ocaml = Otype.py_to_ocaml return_type in
  let get_callable =
    (* This time the class is the callable. *)
    [%string
      {| let callable = Py.Module.get (import_module ()) "%{class_name}" in |}]
  in
  [%string
    "let %{fun_name} %{get_var_names args} () = %{get_callable} %{get_kwargs \
     args} %{py_to_ocaml} @@ Py.Callable.to_function_with_keywords callable \
     [||] kwargs"]

(* IMPORTANT this assumes you have an import_module function in scope... it
   should look something like this: [let import () = Py.Import.import_module
   "module_name_here"] *)
let class_method_impl ~class_name ~fun_name return_type args =
  let py_to_ocaml = Otype.py_to_ocaml return_type in
  let get_class_ =
    [%string
      {| let class_ = Py.Module.get (import_module ()) "%{class_name}" in |}]
  in
  let get_callable =
    [%string
      {| let callable = Py.Object.find_attr_string class_ "%{fun_name}" in |}]
  in
  [%string
    "let %{fun_name} %{get_var_names args} () = %{get_class_} %{get_callable} \
     %{get_kwargs args} %{py_to_ocaml} @@ \
     Py.Callable.to_function_with_keywords callable [||] kwargs"]

(* This is the impl for a python function associated with a module but not a
   class. *)
let module_function_impl fun_name return_type args =
  let py_to_ocaml = Otype.py_to_ocaml return_type in
  let get_callable =
    [%string
      {| let callable = Py.Module.get (import_module ()) "%{fun_name}" in |}]
  in
  [%string
    "let %{fun_name} %{get_var_names args} () = %{get_callable} %{get_kwargs \
     args} %{py_to_ocaml} @@ Py.Callable.to_function_with_keywords callable \
     [||] kwargs"]

(* TODO only the Class_method variant actually uses the class name, but right
   now, you have to pass it in even if you're not generating a class method. *)
let pyml_impl class_name = function
  | Attribute { fun_name; return_type } ->
      let py_to_ocaml = Otype.py_to_ocaml return_type in
      [%string
        "let %{fun_name} t = %{py_to_ocaml} @@ Py.Object.find_attr_string t \
         \"%{fun_name}\""]
  | Instance_method { fun_name; return_type; args } ->
      let py_to_ocaml = Otype.py_to_ocaml return_type in
      let get_callable =
        [%string
          "let callable = Py.Object.find_attr_string t \"%{fun_name}\" in"]
      in
      [%string
        "let %{fun_name} t %{get_var_names args} () = %{get_callable} \
         %{get_kwargs args} %{py_to_ocaml} @@ \
         Py.Callable.to_function_with_keywords callable [||] kwargs"]
  | Class_method { fun_name; return_type; args } -> (
      match fun_name with
      | "__init__" -> init_impl ~class_name ~fun_name return_type args
      | _ -> class_method_impl ~class_name ~fun_name return_type args)
  | Module_function { fun_name; return_type; args } ->
      module_function_impl fun_name return_type args
  | Todo_function fun_name ->
      [%string "let %{fun_name} () = failwith \"todo: %{fun_name}\""]
  | Not_implemented_function fun_name ->
      [%string "let %{fun_name} () = failwith \"not implemented: %{fun_name}\""]
