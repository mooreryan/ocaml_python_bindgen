open! Base

let is_space = function ' ' -> true | _ -> false

let is_capital_letter = function 'A' .. 'Z' -> true | _ -> false

let is_lowercase_letter = function 'a' .. 'z' -> true | _ -> false

let is_ok_for_name = function
  | 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '_' -> true
  | _ -> false

let read_python_source file_name = Stdio.In_channel.read_all file_name

module Angstrom_helpers = struct
  open Angstrom

  let is_whitepace = function ' ' | '\t' -> true | _ -> false

  let is_whitespace_or_eol = function
    | ' ' | '\t' | '\r' | '\n' -> true
    | _ -> false

  let eoi =
    let open Angstrom.Let_syntax in
    end_of_input
    <|> let%bind bad_thing = take_till is_whitespace_or_eol in
        fail bad_thing
        <?> "parser failed before all input was consumed at token"
end

let spaces = Re2.create_exn "[ \n]+"

let squash_spaces s = Re2.rewrite_exn ~template:" " spaces s

let clean s = String.strip @@ squash_spaces s

let todo_type = "type 'a todo = unit -> 'a"

let not_implemented_type = "type 'a not_implemented = unit -> 'a"

let or_error_re = Re2.create_exn "Or_error\\.t"

let todo_re = Re2.create_exn "'a todo"

let not_implemented_re = Re2.create_exn "'a not_implemented"

(* TODO move all these check needs functions up into the one in pyml_bindgen
   main. *)

(* This would give false positives if the Or_error is in something other than
   the return type. Although, other functions should prevent valid val_specs
   from having or error anywhere else. *)
let check_needs_base s = Re2.matches or_error_re s

let check_needs_todo s = Re2.matches todo_re s

let check_needs_not_implemented s = Re2.matches not_implemented_re s

let check_signatures_file fname =
  let sig_dat = Stdio.In_channel.read_all fname in
  let needs_base = check_needs_base sig_dat in
  let needs_todo = check_needs_todo sig_dat in
  let needs_not_implemented = check_needs_not_implemented sig_dat in
  (needs_base, needs_todo, needs_not_implemented)

let print_dbl_endline s = Stdio.print_endline (s ^ "\n")

let abort ?(exit_code = 1) msg =
  Stdio.prerr_endline ("ERROR: " ^ msg);
  Caml.exit exit_code
