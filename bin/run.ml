open! Base
open! Stdio
open! Lib
open Little_logger
open Or_error.Let_syntax

let spaces = Re2.create_exn "[ \n]+"
let squash_spaces s = Re2.rewrite_exn ~template:" " spaces s
let clean s = String.strip @@ squash_spaces s

let all_whitespace = Re2.create_exn "^\\s*$"
let is_comment = Re2.create_exn "^\\s*#"

let gen_pyml_impl ~py_class ~signature =
  let%bind val_spec = Oarg.parse_val_spec signature in
  let%bind py_fun = Py_fun.create val_spec in
  return @@ clean @@ Py_fun.pyml_impl py_class py_fun

let clean_signatures data =
  data
  |> Re2.split ~include_matches:true (Re2.create_exn "val")
  |> List.filter_map ~f:(fun s ->
         if Re2.matches all_whitespace s then None else Some (clean s))
  |> List.chunks_of ~length:2
  |> List.map ~f:(String.concat ~sep:" ")

let or_error_re = Re2.create_exn "Or_error\\.t"

(* This would give false positives if the Or_error is in something other than
   the return type. Although, other functions should prevent valid val_specs
   from having or error anywhere else. *)
let check_needs_base s = Re2.matches or_error_re s

let read_signatures_file fname =
  let sig_dat =
    fname |> In_channel.read_lines
    |> List.filter ~f:(fun s -> not @@ Re2.matches is_comment s)
    |> String.concat ~sep:" "
  in
  let needs_base = check_needs_base sig_dat in
  let signatures = clean_signatures sig_dat in
  (needs_base, signatures)

let gen_pyml_impls ~py_class ~signatures =
  List.map signatures ~f:(fun signature ->
      let impl = gen_pyml_impl ~py_class ~signature in
      Or_error.tag impl ~tag:[%string "Error generating spec for %{signature}"])

let parse_cli_args () =
  match Sys.get_argv () with
  | [| _prog_name; py_module; py_class; fname |] -> (py_module, py_class, fname)
  | _ ->
      failwith
        "usage: pyml_bindgen.exe py_module py_class val_specs.txt > out.ml"

let print_dbl_endline s = print_endline (s ^ "\n")

let gen_filter_map_impl needs_base =
  if needs_base then "let filter_opt = List.filter_opt"
  else "let filter_opt l = List.filter_map Fun.id l"

let print_full ~caml_module ~shared_signatures ~shared_impls ~signatures ~impls
    ~import_module_impl ~needs_base =
  if needs_base then print_dbl_endline "open! Base";
  print_dbl_endline @@ gen_filter_map_impl needs_base;
  print_dbl_endline import_module_impl;
  print_endline [%string "module %{caml_module} : sig"];
  List.iter shared_signatures ~f:print_dbl_endline;
  List.iter signatures ~f:print_dbl_endline;
  print_endline "end = struct";
  List.iter shared_impls ~f:print_dbl_endline;
  List.iter impls ~f:print_dbl_endline;
  print_endline "end"

let print_impls ~shared_impls ~impls ~import_module_impl ~needs_base =
  if needs_base then print_dbl_endline "open! Base";
  print_dbl_endline @@ gen_filter_map_impl needs_base;
  print_dbl_endline import_module_impl;
  List.iter shared_impls ~f:print_dbl_endline;
  List.iter impls ~f:print_dbl_endline

let abort ?(exit_code = 1) msg =
  Logger.sfatal msg;
  Caml.exit exit_code

(* TODO you could do a similar check with the option returning sigs mixed with
   others, as the only 'a option types should be in the return value. *)
(* Only certain combinations of these two are valid. Otherwise, fail! *)
let assert_base_and_ret_type_good needs_base of_pyo_ret_type =
  match (needs_base, of_pyo_ret_type) with
  | true, `Or_error | false, `No_check | false, `Option -> ()
  | false, `Or_error ->
      abort
        "You said you wanted Or_error return type, but Or_error was not found \
         in the sigs."
  | true, `No_check ->
      abort
        "You said you wanted No_check return type, but Or_error was found in \
         the sigs."
  | true, `Option ->
      abort
        "You said you wanted Option return type, but Or_error was found in the \
         sigs."

let run { Cli.signatures; py_module; py_class; caml_module; of_pyo_ret_type } =
  Logger.set_log_level Logger.Level.Debug;
  let _x = caml_module in
  let import_module_impl = Shared.gen_import_module_impl py_module in
  let shared_signatures = Shared.gen_all_signatures of_pyo_ret_type in
  let shared_impls =
    Shared.gen_all_functions of_pyo_ret_type (`Custom py_class)
  in
  let needs_base, signatures = read_signatures_file signatures in
  assert_base_and_ret_type_good needs_base of_pyo_ret_type;
  (* impls -> implementations *)
  let%bind impls = Or_error.all @@ gen_pyml_impls ~py_class ~signatures in
  match caml_module with
  | Some caml_module ->
      Or_error.return
      @@ print_full ~caml_module ~shared_signatures ~shared_impls ~signatures
           ~impls ~import_module_impl ~needs_base
  | None ->
      Or_error.return
      @@ print_impls ~shared_impls ~impls ~import_module_impl ~needs_base
