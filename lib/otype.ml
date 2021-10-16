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
  | Custom of string
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

module P = struct
  open Angstrom
  open Angstrom.Let_syntax

  let spaces = take_while Utils.is_space

  let dot = string "."

  (* Parsers for each of the Otype variants. *)
  let int = string "int"
  let float = string "float"
  let string_ = string "string"
  let bool = string "bool"
  let unit = string "unit"
  let list = string "list"
  let seq = string "Seq.t"
  let option = string "option"
  let or_error = string "Or_error.t"

  (* If you just do string "t", then any arg names that start with t will blow
     up parsing. This is pretty hacky... *)
  let t =
    let%bind t_string = string "t" in
    let%bind next_char = peek_char in
    (* No types or custom types (currently) start with lowercase t, so, if you
       have a lower case t followed by more stuff that is ok for a name then,
       the t type parser should fail. *)
    match next_char with
    | Some c ->
        if Utils.is_ok_for_name c then fail "not a t type" else return t_string
    | None -> return t_string

  (* Custom "types" ...e.g., Doc.t, Span.t, Silly_thing.t. Fails if it is Seq.t
     or Or_error.t. *)
  let custom =
    let%bind c = peek_char_fail in
    if Utils.is_capital_letter c then
      let%bind name = take_while Utils.is_ok_for_name in
      let%bind dot = dot in
      let%bind t = t in
      match name ^ dot ^ t with
      | "Seq.t" -> fail "custom cannot be Seq.t"
      | "Or_error.t" -> fail "custom cannot be Or_error.t"
      | s -> return s
    else fail "first letter should be capital"

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

  (* 'a Seq.t, 'a option, 'a Or_error.t, 'a list. *)
  let compound_otype =
    let%bind t = basic_otype in
    let%bind _space = string " " in
    choice ~failure_msg:"Second token wasn't list, option, Or_error.t, or Seq.t"
      [
        lift (fun _ -> List t) list;
        lift (fun _ -> Seq t) seq;
        lift (fun _ -> Option t) option;
        lift (fun _ -> Or_error t) or_error;
      ]

  let compound_or_basic =
    choice ~failure_msg:"Expected compound or basic otype"
      [ compound_otype; basic_otype ]

  let parser_ = spaces *> compound_or_basic <* spaces
end

let custom_module_name s = List.hd_exn @@ String.split s ~on:'.'

(* Convert py types to ocaml types. *)
let rec py_to_ocaml = function
  | Int -> "Py.Int.to_int"
  | Float -> "Py.Float.to_float"
  | String -> "Py.String.to_string"
  | Bool -> "Py.Bool.to_bool"
  (* In OCaml we return unit from functions that don't really return anything.
     In Python, we return None. TODO...need to reconcile this. *)
  | Unit ->
      failwith "Error in py_to_ocaml. TODO: For now, you can't use unit here."
  (* Note: T.of_pyobject converts the pyobject INTO the OCaml module type. It's
     opposite of the others. *)
  | T -> "of_pyobject"
  (* Note: See comment for T. *)
  | Custom s ->
      let name = custom_module_name s in
      [%string "%{name}.of_pyobject"]
  | List t -> (
      match t with
      | List _ -> failwith "Can't have nested lists"
      | t -> "Py.List.to_list_map " ^ py_to_ocaml t)
  | Seq t -> (
      match t with
      | Seq _ -> failwith "Can't have nested Seq.t"
      | t -> "Py.Iter.to_seq_map " ^ py_to_ocaml t)
  | Option t -> (
      match t with
      | T | Custom _ -> py_to_ocaml t
      | _ -> failwith "you can only have <t> option or <custom> option")
  | Or_error t -> (
      match t with
      | T | Custom _ -> py_to_ocaml t
      | _ -> failwith "you can only have <t> Or_error.t or <custom> Or_error.t")

(* Convert ocaml types to py types. *)
let rec py_of_ocaml = function
  | Int -> "Py.Int.of_int"
  | Float -> "Py.Float.of_float"
  | String -> "Py.String.of_string"
  | Bool -> "Py.Bool.of_bool"
  | Unit -> failwith "Can't use unit here"
  (* Watch out! T.to_pyobject converts the OCaml module TO the python type. It's
     opposite of the others. *)
  | T -> "to_pyobject"
  (* Watch out! See comment for T. *)
  | Custom s ->
      let name = custom_module_name s in
      [%string "%{name}.to_pyobject"]
  | List t -> (
      match t with
      | List _ -> failwith "Can't have nested lists"
      | t -> "Py.List.of_list_map " ^ py_of_ocaml t)
  | Seq t -> (
      match t with
      | Seq _ -> failwith "Can't have nested Seq.t"
      | t -> "Py.Iter.of_seq_map " ^ py_of_ocaml t)
  | Option t -> (
      match t with
      | T | Custom _ -> py_of_ocaml t
      | _ -> failwith "you can only have <t> option or <custom> option")
  | Or_error t -> (
      match t with
      | T | Custom _ -> py_of_ocaml t
      | _ -> failwith "you can only have <t> Or_error.t or <custom> Or_error.t")

(* Parse a otype from a string *)
let parse s =
  match Angstrom.parse_string ~consume:Angstrom.Consume.All P.parser_ s with
  | Ok s -> Or_error.return s
  | Error err -> Or_error.errorf "Parsing Otype failed... %s" err
