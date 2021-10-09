open! Base
open! Stdio

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

  (* Custom "types" ...e.g., Doc.t, Span.t, Silly_thing.t *)
  let custom =
    let%bind c = peek_char_fail in
    if Utils.is_capital_letter c then
      let%bind name = take_while Utils.is_ok_for_name in
      let%bind dot = dot in
      let%bind t = t in
      return (name ^ dot ^ t)
    else fail "first letter should be capital"

  (* A list of any otype *)
  let x_list =
    let%bind first =
      choice ~failure_msg:"First token wasn't an otype"
        [ int; float; string_; bool; unit; t; custom ]
    in
    let%bind _space = string " " in
    let%bind list = list in
    return @@ first ^ " " ^ list
end

(* Be aware that there is no char type here like in ocaml. *)
type t = Int | Float | String | Bool | Unit | T | Custom of string | List of t
[@@deriving sexp]

let is_unit = function Unit -> true | _ -> false
let is_t = function T -> true | _ -> false

let custom_module_name s = List.hd_exn @@ String.split s ~on:'.'

let remove_list_suffix s = String.prefix s (String.length s - 5)

(* On user input, you should use parse instead. This doesn't check the
   invariants. *)
let of_string = function
  | "int" -> Int
  | "int list" -> List Int
  | "float" -> Float
  | "float list" -> List Float
  | "string" -> String
  | "string list" -> List String
  | "bool" -> Bool
  | "bool list" -> List Bool
  | "unit" -> Unit
  | "unit list" -> List Unit
  | "t" -> T
  | "t list" -> List T
  | s ->
      if String.is_suffix s ~suffix:" list" then
        let s = remove_list_suffix s in
        List (Custom s)
      else Custom s

(* Convert py types to ocaml types. *)
let rec py_to_ocaml = function
  | Int -> "Py.Int.to_int"
  | Float -> "Py.Float.to_float"
  | String -> "Py.String.to_string"
  | Bool -> "Py.Bool.to_bool"
  | Unit -> failwith "Can't use unit here"
  (* Assumes there is the proper module set up. *)
  (* Watch out! T.of_pyobject converts the pyobject INTO the OCaml module type.
     It's opposite of the others. *)
  | T -> "of_pyobject"
  (* Watch out! See comment for T. *)
  | Custom s ->
      let name = custom_module_name s in
      [%string "%{name}.of_pyobject"]
  | List t -> (
      match t with
      | List _ -> failwith "Can't have nested lists"
      | t -> "Py.List.to_list_map " ^ py_to_ocaml t)

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

(* An angstrom parser for otype values. *)
let parser_ =
  let open Angstrom in
  let f =
    choice ~failure_msg:"Bad type string"
      [ P.x_list; P.int; P.float; P.string_; P.bool; P.unit; P.t; P.custom ]
  in
  P.spaces *> f <* P.spaces

(* Parse a otype from a string *)
let parse s =
  match Angstrom.parse_string ~consume:Angstrom.Consume.All parser_ s with
  | Ok s -> Or_error.return @@ of_string s
  | Error err -> Or_error.errorf "Parsing Otype failed... %s" err
