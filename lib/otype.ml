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
      [ int; float; string_; bool; unit; t; custom ]

  (* 'a Seq.t, 'a option, 'a Or_error.t, 'a list. *)
  let compound_otype =
    let%bind first = basic_otype in
    let%bind _space = string " " in
    let%bind second =
      choice
        ~failure_msg:"Second token wasn't list, option, Or_error.t, or Seq.t"
        [ list; seq; option; or_error ]
    in
    return @@ first ^ " " ^ second
end

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

let custom_module_name s = List.hd_exn @@ String.split s ~on:'.'

let remove_suffix s ~suffix =
  if String.is_suffix s ~suffix then
    String.prefix s (String.length s - String.length suffix)
  else failwith [%string "missing '%{suffix}' suffix"]

(* On user input, you should use parse instead. This doesn't check the
   invariants. IMPORTANT...if you add more variants to [t], you need to update
   this function...the compiler won't catch it because of the custom type case.
   TODO: Because this function doesn't check the input, it will silently let
   things through as custom that shouldn't be. Because of this, if you add a new
   type it will come up in the tests as Custom whatever...just be aware of
   this!! Tbh, I probably shouldn't even have this function and just have the
   parsers generate the right types. *)
let of_string = function
  | "int" -> Int
  | "int list" -> List Int
  | "int Seq.t" -> Seq Int
  | "int option" -> Option Int
  | "int Or_error.t" -> Or_error Int
  | "float" -> Float
  | "float list" -> List Float
  | "float Seq.t" -> Seq Float
  | "float option" -> Option Float
  | "float Or_error.t" -> Or_error Float
  | "string" -> String
  | "string list" -> List String
  | "string Seq.t" -> Seq String
  | "string option" -> Option String
  | "string Or_error.t" -> Or_error String
  | "bool" -> Bool
  | "bool list" -> List Bool
  | "bool Seq.t" -> Seq Bool
  | "bool option" -> Option Bool
  | "bool Or_error.t" -> Or_error Bool
  | "unit" -> Unit
  | "unit list" -> List Unit
  | "unit Seq.t" -> Seq Unit
  | "unit option" -> Option Unit
  | "unit Or_error.t" -> Or_error Unit
  | "t" -> T
  | "t list" -> List T
  | "t Seq.t" -> Seq T
  | "t option" -> Option T
  | "t Or_error.t" -> Or_error T
  | s ->
      if String.is_suffix s ~suffix:" list" then
        let s = remove_suffix s ~suffix:" list" in
        List (Custom s)
      else if String.is_suffix s ~suffix:" Seq.t" then
        let s = remove_suffix s ~suffix:" Seq.t" in
        Seq (Custom s)
      else if String.is_suffix s ~suffix:" option" then
        let s = remove_suffix s ~suffix:" option" in
        Option (Custom s)
      else if String.is_suffix s ~suffix:" Or_error.t" then
        let s = remove_suffix s ~suffix:" Or_error.t" in
        Or_error (Custom s)
      else Custom s

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

(* An angstrom parser for otype values. *)
let parser_ =
  let open Angstrom in
  let f =
    choice ~failure_msg:"Bad type string" [ P.compound_otype; P.basic_otype ]
  in
  P.spaces *> f <* P.spaces

(* Parse a otype from a string *)
let parse s =
  match Angstrom.parse_string ~consume:Angstrom.Consume.All parser_ s with
  | Ok s -> Or_error.return @@ of_string s
  | Error err -> Or_error.errorf "Parsing Otype failed... %s" err
