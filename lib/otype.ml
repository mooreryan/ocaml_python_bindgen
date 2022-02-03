open! Base
open! Stdio

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
[@@deriving sexp]

let is_unit = function Unit -> true | _ -> false

let is_t = function T -> true | _ -> false

let is_todo = function Todo -> true | _ -> false

let is_not_implemented = function Not_implemented -> true | _ -> false

module P = struct
  open Angstrom
  open Angstrom.Let_syntax

  let spaces = take_while Utils.is_space

  let dot = string "."

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

  (* Custom "types" ...e.g., Doc.t, Span.t, Silly_thing.t. Fails if it is Seq.t
     or Or_error.t. *)
  let custom =
    let%bind c = peek_char_fail in
    let p =
      if Utils.is_capital_letter c then
        let%bind name = take_while Utils.is_ok_for_name in
        let%bind dot = dot in
        let%bind t = t in
        match name ^ dot ^ t with
        | "Seq.t" -> fail "custom cannot be Seq.t"
        | "Or_error.t" -> fail "custom cannot be Or_error.t"
        | s -> return s
      else fail "first letter should be capital"
    in
    p <?> "custom parser"

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

  let placeholder_otype =
    choice ~failure_msg:"Token wasn't an placeholder otype"
      [
        lift (fun _ -> Todo) todo;
        lift (fun _ -> Not_implemented) not_implemented;
      ]
    <?> "placeholder_otype parser"

  let parser_ =
    let p =
      choice ~failure_msg:"otype parser_ failed"
        [ compound_otype; basic_otype; placeholder_otype ]
    in
    spaces *> p <* spaces <?> "parser_"
end

let custom_module_name s = List.hd_exn @@ String.split s ~on:'.'

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
      | Array _ | List _ | Seq _ | Or_error _ | Todo | Not_implemented ->
          failwith "only basic types can be options"
      | Int | Float | String | Bool ->
          [%string
            "(fun x -> if Py.is_none x then None else Some (%{py_to_ocaml t} \
             x))"])
  | Or_error t -> (
      match t with
      | T | Custom _ -> py_to_ocaml t
      | _ -> failwith "you can only have <t> Or_error.t or <custom> Or_error.t")

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
      | Array _ | List _ | Seq _ | Or_error _ | Todo | Not_implemented ->
          failwith "only basic types can be options"
      | Int | Float | String | Bool ->
          [%string "(function Some x -> %{py_of_ocaml t} x | None -> Py.none)"])
  | Or_error t -> (
      match t with
      | T | Custom _ -> py_of_ocaml t
      | _ -> failwith "you can only have <t> Or_error.t or <custom> Or_error.t")

(* Parse a otype from a string *)
let parse s =
  match Angstrom.parse_string ~consume:Angstrom.Consume.All P.parser_ s with
  | Ok s -> Or_error.return s
  | Error err -> Or_error.errorf "Parsing Otype failed... %s" err
