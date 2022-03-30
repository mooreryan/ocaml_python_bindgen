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

let spaces = Re.compile @@ Re.Perl.re "[ \n]+"

let squash_spaces s = Re.replace_string spaces s ~by:" "

let clean s = String.strip @@ squash_spaces s

let todo_type = "type 'a todo = unit -> 'a"

let not_implemented_type = "type 'a not_implemented = unit -> 'a"

let or_error_re = Re.compile @@ Re.Perl.re "Or_error\\.t"

let todo_re = Re.compile @@ Re.Perl.re "'a todo"

let not_implemented_re = Re.compile @@ Re.Perl.re "'a not_implemented"

(* TODO move all these check needs functions up into the one in pyml_bindgen
   main. *)

(* This would give false positives if the Or_error is in something other than
   the return type. Although, other functions should prevent valid val_specs
   from having or error anywhere else. *)
let check_needs_base s = Re.execp or_error_re s

let check_needs_todo s = Re.execp todo_re s

let check_needs_not_implemented s = Re.execp not_implemented_re s

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

let find_first re s ~sub =
  match Re.exec_opt re s with
  | None -> Or_error.error_string "regex did not match"
  | Some group -> (
      match Re.Group.get_opt group sub with
      | None -> Or_error.error_string "group did not match"
      | Some thing -> Or_error.return thing)

let py_fun_name_attribute =
  (* TODO do we need 0-9 in there? *)
  Re.compile @@ Re.Perl.re "\\[@@py_fun_name\\s+([a-zA-Z_]+)\\]"

let get_py_fun_name s = find_first py_fun_name_attribute s ~sub:1

let py_arg_name_attribute =
  Re.Perl.compile_pat
    "\\[@@py_arg_name\\s+([a-zA-Z0-9_]+)\\s+([a-zA-Z0-9_]+)\\]"

(* Given the attributes on a val_spec, pull out any mappings from ml_name to
   py_name. *)
let get_arg_name_map attrs =
  match attrs with
  | None -> Map.empty (module String)
  | Some attrs ->
      let py_arg_names =
        Re.all py_arg_name_attribute attrs
        |> List.fold
             ~init:(Map.empty (module String))
             ~f:(fun m g ->
               (* For now, blow up if a key is duplicated. TODO *)
               Map.add_exn m ~key:(Re.Group.get g 1) ~data:(Re.Group.get g 2))
      in
      py_arg_names

let find_with_default m ~key ~default = Option.value ~default @@ Map.find m key
