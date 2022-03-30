open! Base

(* Each of these have their own type in addition to being in the variant type so
   that we can make sure certain things are passed to certain functions by
   callers. *)

(* posistional can be an option type...'optional' refers to ?a:string and stuff
   like that. *)
type positional = { type_ : Otype.t } [@@deriving sexp]

type labeled = { ml_name : string; py_name : string; type_ : Otype.t }
[@@deriving sexp]

(* Kind of confusing, but these are not things like a:string option, but
   ?a:string. It's optional in the sense of you don't need to pass it in. *)
type optional = { ml_name : string; py_name : string; type_ : Otype.t }
[@@deriving sexp]

let make_positional type_ : positional = { type_ }

let make_labeled ~ml_name ~py_name type_ : labeled = { ml_name; py_name; type_ }

let make_optional ~ml_name ~py_name type_ : optional =
  { ml_name; py_name; type_ }

let optional_ml_name (x : optional) : string = x.ml_name

let optional_py_name (x : optional) : string = x.py_name

let optional_type (x : optional) : Otype.t = x.type_

let labeled_ml_name (x : labeled) : string = x.ml_name

let labeled_py_name (x : labeled) : string = x.py_name

let labeled_type (x : labeled) : Otype.t = x.type_

type t = Positional of positional | Labeled of labeled | Optional of optional
[@@deriving sexp]

let update_arg_py_name name_map arg =
  match arg with
  | Positional arg -> Positional arg
  | Labeled arg ->
      let py_name =
        Utils.find_with_default name_map ~key:arg.ml_name ~default:arg.py_name
      in
      Labeled { arg with py_name }
  | Optional arg ->
      let py_name =
        Utils.find_with_default name_map ~key:arg.ml_name ~default:arg.py_name
      in
      Optional { arg with py_name }

type val_spec = { ml_fun_name : string; args : t list } [@@deriving sexp]

let type_ = function
  | Positional { type_ } -> type_
  | Labeled { type_; _ } -> type_
  | Optional { type_; _ } -> type_

let is_positional = function
  | Positional _ -> true
  | Labeled _ | Optional _ -> false

let is_positional_unit = function
  | Positional { type_ } -> Otype.is_unit type_
  | Labeled _ | Optional _ -> false

let is_positional_non_unit = function
  | Positional { type_ } -> not (Otype.is_unit type_)
  | Labeled _ | Optional _ -> false

let is_positional_t = function
  | Positional { type_ } -> Otype.is_t type_
  | Labeled _ | Optional _ -> false

let is_positional_todo = function
  | Positional { type_ } -> Otype.is_todo type_
  | Labeled _ | Optional _ -> false

let is_positional_not_implemented = function
  | Positional { type_ } -> Otype.is_not_implemented type_
  | Labeled _ | Optional _ -> false

let parse_labeled_or_optional_non_unit args =
  let open Or_error in
  all @@ Array.to_list
  @@ Array.map args ~f:(function
       | Positional _ -> error_string "can't be positional"
       | Labeled { type_; ml_name; py_name } ->
           if Otype.is_unit type_ then error_string "cannot be labeled unit"
           else return @@ `Labeled ({ type_; ml_name; py_name } : labeled)
       | Optional { type_; ml_name; py_name } ->
           if Otype.is_unit type_ then error_string "cannot be optional unit"
           else return @@ `Optional ({ type_; ml_name; py_name } : optional))

module P = struct
  open! Angstrom
  open! Angstrom.Let_syntax
  include Utils.Angstrom_helpers

  let spaces = take_while Utils.is_space

  let val_ = spaces *> string "val" <* spaces

  let arrow = spaces *> string "->" <* spaces

  let colon = spaces *> string ":" <* spaces

  let question_mark = spaces *> string "?" <* spaces

  let all_underscores = Re.compile @@ Re.Perl.re "^_+$"

  (* apple:int <- arg name is the first part of that. *)
  let arg_name =
    let%bind first_char = peek_char_fail in
    if Utils.is_lowercase_letter first_char || Char.(first_char = '_') then
      let%bind name = spaces *> take_while1 Utils.is_ok_for_name <* spaces in
      match Otype.parse name with
      | Ok _ -> fail "arg name cannot be the same as an otype"
      | Error _ ->
          (* One last check...names can't be all underscores. *)
          if Re.execp all_underscores name then
            fail "name can't be all underscores"
          else return name
    else fail "first letter of arg name must be lowercase letter or underscore"

  (* apple:int <- arg type is the second part of that. Note you can use
     Otype.of_string on values produced by this as the parser will fail on bad
     otype strings. *)
  let arg_type = Otype.P.parser_ <?> "arg_type parser"

  (* string; int; Doc.t *)
  let positional =
    let%bind type_ = arg_type in
    return @@ Positional (make_positional type_) <?> "positional parser"

  (* apple:int list; pie:Fruit.t *)
  let labeled =
    let%bind ml_name = arg_name in
    let%bind _sep = colon in
    let%bind type_ = arg_type in
    (* TODO for now the name is the same. *)
    return @@ Labeled (make_labeled ~ml_name ~py_name:ml_name type_)
    <?> "labeled parser"

  (* ?apple:int list; ?pie:Fruit.t *)
  let optional =
    let%bind _qm = question_mark in
    let%bind ml_name = arg_name in
    let%bind _sep = colon in
    let%bind type_ = arg_type in
    (* TODO for now the name is the same. *)
    return @@ Optional (make_optional ~ml_name ~py_name:ml_name type_)
    <?> "optional parser"

  (* Any of the three arg types. *)
  let arg =
    choice ~failure_msg:"Input doesn't look like a valid Arg"
      [ positional; labeled; optional ]
    <?> "arg parser"

  (* int -> fruit:string -> unit *)
  let args = sep_by arrow arg <?> "args parser"

  (* e.g., val f : int -> fruit:string -> unit*)
  let val_spec =
    let p =
      let%bind _val = val_ in
      (* function names and arg names parse the same *)
      let%bind ml_fun_name = arg_name in
      (* TODO *)
      let%bind _colon = colon in
      let%bind args = args in
      return { ml_fun_name; args }
    in
    p <* eoi <?> "val_spec parser"
end

let parse_val_spec s =
  let s = String.strip s in
  (* We use prefix here as [val_spec] has a custom end of input check. *)
  match Angstrom.parse_string ~consume:Angstrom.Consume.Prefix P.val_spec s with
  | Ok val_spec -> Or_error.return val_spec
  | Error err -> Or_error.errorf "Parsing val_spec failed... %s" err

let val_spec_needs_tuple2 val_spec =
  List.exists val_spec.args ~f:(fun oarg ->
      match type_ oarg with
      | Tuple2 _ | Array (Tuple2 _) | List (Tuple2 _) | Seq (Tuple2 _) -> true
      | _ -> false)

let val_spec_needs_tuple3 val_spec =
  List.exists val_spec.args ~f:(fun oarg ->
      match type_ oarg with
      | Tuple3 _ | Array (Tuple3 _) | List (Tuple3 _) | Seq (Tuple3 _) -> true
      | _ -> false)

let val_spec_needs_tuple4 val_spec =
  List.exists val_spec.args ~f:(fun oarg ->
      match type_ oarg with
      | Tuple4 _ | Array (Tuple4 _) | List (Tuple4 _) | Seq (Tuple4 _) -> true
      | _ -> false)

let val_spec_needs_tuple5 val_spec =
  List.exists val_spec.args ~f:(fun oarg ->
      match type_ oarg with
      | Tuple5 _ | Array (Tuple5 _) | List (Tuple5 _) | Seq (Tuple5 _) -> true
      | _ -> false)
