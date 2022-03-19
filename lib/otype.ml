open! Base
open! Stdio

(* TODO there are some things that the parser disallows with Pytypes.pyobject
   that this code will process. It's currently not always dealt with here
   properly since the parser won't let it through, but you should probably
   change it at some point. *)

(* This is used for Py_obj identity functions. TODO it does lead to a bunch of
   anonymous little identity functions littered throughout the generate code,
   but it's not a big deal. *)
let ident_fun = "(fun x -> x)"

(* Be aware that there is no char type here like in ocaml. *)
type t =
  | Int
  | Float
  | String
  | Bool
  | Unit
  | T
  | Todo
  | Not_implemented
  | Custom of string
  | Array of t
  | List of t
  | Seq of t
  (* The option and or_error variants are a little different...the oarg will
     make sure that you're only allowed to return something that is an option or
     or_error type, and ONLY of T or Custom otype. What I mean is that [val f :
     string option -> unit -> 'a] wouldn't be allowed, but [val f : t -> unit ->
     A.t option] would be allowed. *)
  | Option of t
  | Or_error of t
  | Tuple2 of t * t
  | Tuple3 of t * t * t
  | Tuple4 of t * t * t * t
  | Tuple5 of t * t * t * t * t
  | Py_obj
[@@deriving sexp]

let is_unit = function Unit -> true | _ -> false

let is_t = function T -> true | _ -> false

let is_todo = function Todo -> true | _ -> false

let is_not_implemented = function Not_implemented -> true | _ -> false

module P = struct
  open Angstrom
  open Angstrom.Let_syntax
  include Utils.Angstrom_helpers

  let spaces = take_while Utils.is_space

  let dot = string "."

  let star = string "*"

  (* Parsers for each of the Otype variants. *)
  let int = string "int" <?> "int parser"

  let float = string "float" <?> "float parser"

  let string_ = string "string" <?> "string parser"

  let bool = string "bool" <?> "bool parser"

  let unit = string "unit" <?> "unit parser"

  let array = string "array" <?> "array parser"

  let list = string "list" <?> "list parser"

  let seq = string "Seq.t" <?> "seq parser"

  let option = string "option" <?> "option parser"

  let or_error = string "Or_error.t" <?> "or_error parser"

  let todo = string "'a todo" <?> "todo parser"

  let not_implemented = string "'a not_implemented" <?> "not_implemented parser"

  (* We allow stuff like [int option list] *)
  let option_array = string "option array" <?> "option_array parser"

  let option_list = string "option list" <?> "option_list parser"

  let option_seq = string "option Seq.t" <?> "option_seq parser"

  let pytypes_pyobject = string "Pytypes.pyobject" <?> "pytypes_pyobject parser"

  let py_object_t = string "Py.Object.t" <?> "py_object_t parser"

  (* If you just do string "t", then any arg names that start with t will blow
     up parsing. This is pretty hacky... *)
  let t =
    let%bind t_string = string "t" in
    let p =
      let%bind next_char = peek_char in
      (* No types or custom types (currently) start with lowercase t, so, if you
         have a lower case t followed by more stuff that is ok for a name then,
         the t type parser should fail. *)
      match next_char with
      | Some c ->
          if Utils.is_ok_for_name c then fail "not a t type"
          else return t_string
      | None -> return t_string
    in
    p <?> "t parser"

  (* Custom "types" ...e.g., Doc.t, Span.t, Silly_thing.t, Apple_pie.Is_good.t.
     Fails if it is Seq.t or Or_error.t. Fails for stuff like
     Apple_pie.Is_good.stuff (must end in .t). Or Apple.pie_good. *)
  let custom =
    (* A single module identifier *)
    let id =
      let%bind first = satisfy Utils.is_capital_letter in
      let%bind rest = take_while Utils.is_ok_for_name in
      return [%string "%{first#Char}%{rest}"]
    in
    let ids = sep_by1 dot id in
    let dot_t = string ".t" in
    let p =
      let%bind names = ids in
      let name = String.concat ~sep:"." names in
      let%bind dot_t = dot_t in
      match name ^ dot_t with
      | "Seq.t" -> fail "custom cannot be Seq.t"
      | "Or_error.t" -> fail "custom cannot be Or_error.t"
      | s -> return s
    in
    p <?> "custom parser"

  let py_obj_otype =
    choice ~failure_msg:"Token was not py_obj"
      [
        lift (fun _ -> Py_obj) pytypes_pyobject;
        lift (fun _ -> Py_obj) py_object_t;
      ]
    <?> "py_obj parser"

  (* Not a list, seq, option, etc. Just the type. *)
  let basic_otype =
    choice ~failure_msg:"Token wasn't an otype"
      [
        lift (fun _ -> Int) int;
        lift (fun _ -> Float) float;
        lift (fun _ -> String) string_;
        lift (fun _ -> Bool) bool;
        lift (fun _ -> Unit) unit;
        lift (fun _ -> T) t;
        lift (fun s -> Custom s) custom;
      ]
    <?> "basic_otype parser"

  (* E.g., things that are allowed in tuples. *)
  let non_unit_basic_otype =
    choice ~failure_msg:"Token wasn't an otype"
      [
        lift (fun _ -> Py_obj) py_obj_otype;
        lift (fun _ -> Int) int;
        lift (fun _ -> Float) float;
        lift (fun _ -> String) string_;
        lift (fun _ -> Bool) bool;
        lift (fun _ -> T) t;
        (* lift (fun _ -> Py_obj) pytypes_pyobject; lift (fun _ -> Py_obj)
           py_object_t; *)
        lift (fun s -> Custom s) custom;
      ]
    <?> "non_unit_basic_otype parser"

  (* 'a Seq.t, 'a option, 'a Or_error.t, 'a list. *)
  let compound_otype =
    let%bind t = basic_otype in
    let%bind _space = string " " in
    let p =
      choice
        ~failure_msg:
          "Second token wasn't list, option, Or_error.t, Seq.t, 'option list', \
           or 'option Seq.t'"
        [
          lift (fun _ -> Array (Option t)) option_array;
          lift (fun _ -> List (Option t)) option_list;
          lift (fun _ -> Seq (Option t)) option_seq;
          lift (fun _ -> Array t) array;
          lift (fun _ -> List t) list;
          lift (fun _ -> Seq t) seq;
          lift (fun _ -> Option t) option;
          lift (fun _ -> Or_error t) or_error;
        ]
    in
    p <?> "compound_otype parser"

  let tuple_otype =
    let t2_of_pair (a, b) = Tuple2 (a, b) in
    let t3_of_pair (a, b, c) = Tuple3 (a, b, c) in
    let t4_of_pair (a, b, c, d) = Tuple4 (a, b, c, d) in
    let t5_of_pair (a, b, c, d, e) = Tuple5 (a, b, c, d, e) in
    let%bind elements =
      sep_by1 (spaces *> star <* spaces) non_unit_basic_otype
    in
    match elements with
    | [] -> fail "tuples cannot be empty"
    | [ _ ] -> fail "single otypes are not tuples"
    | [ a; b ] -> lift t2_of_pair @@ return (a, b)
    | [ a; b; c ] -> lift t3_of_pair @@ return (a, b, c)
    | [ a; b; c; d ] -> lift t4_of_pair @@ return (a, b, c, d)
    | [ a; b; c; d; e ] -> lift t5_of_pair @@ return (a, b, c, d, e)
    | _ -> fail "can only do tuples 2-5"

  let tuple_coll_otype =
    let%bind tuple = spaces *> char '(' *> tuple_otype <* char ')' <* spaces in
    choice ~failure_msg:"tuple_coll_otype choice failed"
      [
        lift (fun _ -> List tuple) list;
        lift (fun _ -> Array tuple) array;
        lift (fun _ -> Seq tuple) seq;
      ]

  let placeholder_otype =
    choice ~failure_msg:"Token wasn't an placeholder otype"
      [
        lift (fun _ -> Todo) todo;
        lift (fun _ -> Not_implemented) not_implemented;
      ]
    <?> "placeholder_otype parser"

  let parser_ =
    let p =
      choice ~failure_msg:"not a compound, basic, or placeholder otype"
        [
          (* This order is important. *)
          tuple_coll_otype;
          tuple_otype;
          py_obj_otype;
          compound_otype;
          basic_otype;
          placeholder_otype;
        ]
    in
    spaces *> p <* spaces <?> "otype parser"
end

let custom_module_name s = String.chop_suffix_exn s ~suffix:".t"

let handle_tuple_element f x =
  match x with
  | Int | Float | String | Bool | T | Custom _ | Py_obj -> f x
  | _ ->
      failwith
        "Tuples must contain basic types (Int, Float, String, Bool, T, or \
         Custom)"

(* Convert py types to ocaml types. Some of these failwith things are prevented
   because we only construct otypes with the parsing functions.... *)
let rec py_to_ocaml = function
  | Int -> "Py.Int.to_int"
  | Float -> "Py.Float.to_float"
  | String -> "Py.String.to_string"
  | Bool -> "Py.Bool.to_bool"
  (* Use the ignore function ['a -> unit]. None in pyml is still a pyobject that
     you need to ignore. *)
  | Unit -> "ignore"
  (* Note: T.of_pyobject converts the pyobject INTO the OCaml module type. It's
     opposite of the others. *)
  | T -> "of_pyobject"
  | Todo -> ""
  | Not_implemented -> ""
  (* Note: See comment for T. *)
  | Custom s ->
      let name = custom_module_name s in
      [%string "%{name}.of_pyobject"]
  | Array t -> (
      match t with
      | Array _ | List _ | Seq _ -> failwith "Can't nest containers"
      | t -> "Py.List.to_array_map " ^ py_to_ocaml t)
  | List t -> (
      match t with
      | Array _ | List _ | Seq _ -> failwith "Can't nest containers"
      | t -> "Py.List.to_list_map " ^ py_to_ocaml t)
  | Seq t -> (
      match t with
      | Array _ | List _ | Seq _ -> failwith "Can't nest containers"
      | t -> "Py.Iter.to_seq_map " ^ py_to_ocaml t)
  | Option t -> (
      match t with
      | T | Custom _ -> py_to_ocaml t
      | Option _ -> failwith "Can't have nested options"
      | Unit -> failwith "Can't have unit option"
      | Array _ | List _ | Seq _ | Or_error _ | Todo | Not_implemented
      | Tuple2 _ | Tuple3 _ | Tuple4 _ | Tuple5 _ ->
          (* TODO test*)
          failwith "only basic types can be options"
      | Int | Float | String | Bool | Py_obj ->
          [%string
            "(fun x -> if Py.is_none x then None else Some (%{py_to_ocaml t} \
             x))"])
  | Or_error t -> (
      match t with
      | T | Custom _ -> py_to_ocaml t
      | _ -> failwith "you can only have <t> Or_error.t or <custom> Or_error.t")
  | Tuple2 (a, b) ->
      let conv = handle_tuple_element py_to_ocaml in
      (* You don't need this as an anonymous function for just a single tuple,
         but if you define it this way, it will work when the tuple is inside a
         collection. *)
      [%string
        "(fun x -> t2_map ~fa:%{conv a} ~fb:%{conv b} @@ Py.Tuple.to_tuple2 x)"]
  | Tuple3 (a, b, c) ->
      let conv = handle_tuple_element py_to_ocaml in
      [%string
        "(fun x -> t3_map ~fa:%{conv a} ~fb:%{conv b} ~fc:%{conv c} @@ \
         Py.Tuple.to_tuple3 x)"]
  | Tuple4 (a, b, c, d) ->
      let conv = handle_tuple_element py_to_ocaml in
      [%string
        "(fun x -> t4_map ~fa:%{conv a} ~fb:%{conv b} ~fc:%{conv c} ~fd:%{conv \
         d} @@ Py.Tuple.to_tuple4 x)"]
  | Tuple5 (a, b, c, d, e) ->
      let conv = handle_tuple_element py_to_ocaml in
      [%string
        "(fun x -> t5_map ~fa:%{conv a} ~fb:%{conv b} ~fc:%{conv c} ~fd:%{conv \
         d} ~fe:%{conv e} @@ Py.Tuple.to_tuple5 x)"]
  | Py_obj -> ident_fun

(* Convert ocaml types to py types. Some of these failwith things are prevented
   because we only construct otypes with the parsing functions.... *)
let rec py_of_ocaml = function
  | Int -> "Py.Int.of_int"
  | Float -> "Py.Float.of_float"
  | String -> "Py.String.of_string"
  | Bool -> "Py.Bool.of_bool"
  | Unit -> failwith "Can't use unit here"
  (* Watch out! T.to_pyobject converts the OCaml module TO the python type. It's
     opposite of the others. *)
  | T -> "to_pyobject"
  | Todo -> ""
  | Not_implemented -> ""
  (* Watch out! See comment for T. *)
  | Custom s ->
      let name = custom_module_name s in
      [%string "%{name}.to_pyobject"]
  | Array t -> (
      match t with
      | Array _ | List _ | Seq _ -> failwith "Can't nest containers"
      | t -> "Py.List.of_array_map " ^ py_of_ocaml t)
  | List t -> (
      match t with
      | Array _ | List _ | Seq _ -> failwith "Can't nest containers"
      | t -> "Py.List.of_list_map " ^ py_of_ocaml t)
  | Seq t -> (
      match t with
      | Array _ | List _ | Seq _ -> failwith "Can't nest containers"
      | t -> "Py.Iter.of_seq_map " ^ py_of_ocaml t)
  | Option t -> (
      match t with
      | T | Custom _ -> py_of_ocaml t
      | Option _ -> failwith "Can't have nested options"
      | Unit -> failwith "Can't have unit option"
      | Array _ | List _ | Seq _ | Or_error _ | Todo | Not_implemented
      | Tuple2 _ | Tuple3 _ | Tuple4 _ | Tuple5 _ ->
          (* TODO test this *)
          failwith "only basic types can be options"
      | Int | Float | String | Bool | Py_obj ->
          [%string "(function Some x -> %{py_of_ocaml t} x | None -> Py.none)"])
  | Or_error t -> (
      match t with
      | T | Custom _ -> py_of_ocaml t
      | _ -> failwith "you can only have <t> Or_error.t or <custom> Or_error.t")
  | Tuple2 (a, b) ->
      let conv = handle_tuple_element py_of_ocaml in
      [%string
        "(fun x -> Py.Tuple.of_tuple2 @@ t2_map ~fa:%{conv a} ~fb:%{conv b} x)"]
  | Tuple3 (a, b, c) ->
      let conv = handle_tuple_element py_of_ocaml in
      [%string
        "(fun x -> Py.Tuple.of_tuple3 @@ t3_map ~fa:%{conv a} ~fb:%{conv b} \
         ~fc:%{conv c} x)"]
  | Tuple4 (a, b, c, d) ->
      let conv = handle_tuple_element py_of_ocaml in
      [%string
        "(fun x -> Py.Tuple.of_tuple4 @@ t4_map ~fa:%{conv a} ~fb:%{conv b} \
         ~fc:%{conv c} ~fd:%{conv d} x)"]
  | Tuple5 (a, b, c, d, e) ->
      let conv = handle_tuple_element py_of_ocaml in
      [%string
        "(fun x -> Py.Tuple.of_tuple5 @@ t5_map ~fa:%{conv a} ~fb:%{conv b} \
         ~fc:%{conv c} ~fd:%{conv d} ~fe:%{conv e} x)"]
  | Py_obj -> ident_fun

(* Parse a otype from a string *)
let parse s =
  match Angstrom.parse_string ~consume:Angstrom.Consume.All P.parser_ s with
  | Ok s -> Or_error.return s
  | Error err -> Or_error.errorf "Parsing Otype failed... %s" err
