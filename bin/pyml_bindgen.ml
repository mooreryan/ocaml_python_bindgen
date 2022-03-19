open! Base
open! Stdio
open! Lib
open Or_error.Let_syntax

let spaces = Re2.create_exn "[ \n]+"

let squash_spaces s = Re2.rewrite_exn ~template:" " spaces s

let clean s = String.strip @@ squash_spaces s

let todo_type = "type 'a todo = unit -> 'a"

let not_implemented_type = "type 'a not_implemented = unit -> 'a"

type shared_impl_needs = {
  mutable t2 : bool;
  mutable t3 : bool;
  mutable t4 : bool;
  mutable t5 : bool;
}

let shared_impl_needs = { t2 = false; t3 = false; t4 = false; t5 = false }

(* TODO would be nice to check for needs outside of this function.... *)
let gen_pyml_impl ~associated_with ~py_class ~spec =
  let py_fun_name_attribute =
    Re2.create_exn "\\[@@py_fun_name\\s+([a-zA-Z_]+)\\]"
  in
  let get_py_fun_name s =
    Re2.find_first ~sub:(`Index 1) py_fun_name_attribute s
  in
  let%bind val_spec = Oarg.parse_val_spec spec.Specs_file.val_spec in
  shared_impl_needs.t2 <-
    shared_impl_needs.t2 || Oarg.val_spec_needs_tuple2 val_spec;
  shared_impl_needs.t3 <-
    shared_impl_needs.t3 || Oarg.val_spec_needs_tuple3 val_spec;
  shared_impl_needs.t4 <-
    shared_impl_needs.t4 || Oarg.val_spec_needs_tuple4 val_spec;
  shared_impl_needs.t5 <-
    shared_impl_needs.t5 || Oarg.val_spec_needs_tuple5 val_spec;
  (* Will use the same name as ml_fun if the py_fun_name attr is not present. *)
  let%bind py_fun_name =
    match spec.Specs_file.attrs with
    | None -> Or_error.return val_spec.ml_fun_name
    | Some attrs -> get_py_fun_name attrs
  in
  let%bind py_fun = Py_fun.create val_spec ~py_fun_name ~associated_with in
  return @@ clean @@ Py_fun.pyml_impl py_class py_fun

let or_error_re = Re2.create_exn "Or_error\\.t"

let todo_re = Re2.create_exn "'a todo"

let not_implemented_re = Re2.create_exn "'a not_implemented"

(* This would give false positives if the Or_error is in something other than
   the return type. Although, other functions should prevent valid val_specs
   from having or error anywhere else. *)
let check_needs_base s = Re2.matches or_error_re s

let check_needs_todo s = Re2.matches todo_re s

let check_needs_not_implemented s = Re2.matches not_implemented_re s

let check_signatures_file fname =
  let sig_dat = In_channel.read_all fname in
  let needs_base = check_needs_base sig_dat in
  let needs_todo = check_needs_todo sig_dat in
  let needs_not_implemented = check_needs_not_implemented sig_dat in
  (needs_base, needs_todo, needs_not_implemented)

let gen_pyml_impls ~associated_with ~py_class ~specs =
  List.map specs ~f:(fun spec ->
      let impl = gen_pyml_impl ~associated_with ~py_class ~spec in
      (* TODO sexp here *)
      Or_error.tag impl
        ~tag:[%string "Error generating spec for '%{spec.val_spec}'"])

let print_dbl_endline s = print_endline (s ^ "\n")

let gen_filter_opt_impl needs_base =
  if needs_base then "let filter_opt = List.filter_opt"
  else "let filter_opt l = List.filter_map Fun.id l"

let gen_t2_map_impl () = "let t2_map (a, b) ~fa ~fb = (fa a, fb b)"

let gen_t3_map_impl () = "let t3_map (a, b, c) ~fa ~fb ~fc = (fa a, fb b, fc c)"

let gen_t4_map_impl () =
  "let t4_map (a, b, c, d) ~fa ~fb ~fc ~fd  = (fa a, fb b, fc c, fd d)"

let gen_t5_map_impl () =
  "let t5_map (a, b, c, d, e) ~fa ~fb ~fc ~fd ~fe = (fa a, fb b, fc c, fd d, \
   fe e)"

(* I'm going to put the todo and not_implemented types inside the generated
   module. While I could put them outside, it makes it more annoying when
   catting together generated files, so we will go with a bit of duplication. *)
let print_full ~caml_module ~shared_signatures ~shared_impls ~specs ~impls
    ~import_module_impl ~needs_base ~needs_todo ~needs_not_implemented
    ~needs_tuple2 ~needs_tuple3 ~needs_tuple4 ~needs_tuple5 =
  if needs_base then print_dbl_endline "open! Base";
  print_endline [%string "module %{caml_module} : sig"];
  if needs_todo then print_dbl_endline todo_type;
  if needs_not_implemented then print_dbl_endline not_implemented_type;
  List.iter shared_signatures ~f:print_dbl_endline;
  List.iter specs ~f:(fun spec -> print_dbl_endline spec.Specs_file.val_spec);
  print_endline "end = struct";
  if needs_todo then print_dbl_endline todo_type;
  if needs_not_implemented then print_dbl_endline not_implemented_type;
  print_dbl_endline @@ gen_filter_opt_impl needs_base;
  if needs_tuple2 then print_dbl_endline @@ gen_t2_map_impl ();
  if needs_tuple3 then print_dbl_endline @@ gen_t3_map_impl ();
  if needs_tuple4 then print_dbl_endline @@ gen_t4_map_impl ();
  if needs_tuple5 then print_dbl_endline @@ gen_t5_map_impl ();
  print_dbl_endline import_module_impl;
  List.iter shared_impls ~f:print_dbl_endline;
  List.iter impls ~f:print_dbl_endline;
  print_endline "end"

let print_impls ~shared_impls ~impls ~import_module_impl ~needs_base ~needs_todo
    ~needs_not_implemented ~needs_tuple2 ~needs_tuple3 ~needs_tuple4
    ~needs_tuple5 =
  if needs_base then print_dbl_endline "open! Base";
  if needs_todo then print_dbl_endline todo_type;
  if needs_not_implemented then print_dbl_endline not_implemented_type;
  print_dbl_endline @@ gen_filter_opt_impl needs_base;
  if needs_tuple2 then print_dbl_endline @@ gen_t2_map_impl ();
  if needs_tuple3 then print_dbl_endline @@ gen_t3_map_impl ();
  if needs_tuple4 then print_dbl_endline @@ gen_t4_map_impl ();
  if needs_tuple5 then print_dbl_endline @@ gen_t5_map_impl ();
  print_dbl_endline import_module_impl;
  List.iter shared_impls ~f:print_dbl_endline;
  List.iter impls ~f:print_dbl_endline

let abort ?(exit_code = 1) msg =
  prerr_endline ("ERROR: " ^ msg);
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

let run
    {
      Cli.signatures;
      py_module;
      py_class;
      caml_module;
      of_pyo_ret_type;
      associated_with;
      embed_python_source;
    } =
  let import_module_impl =
    Shared.gen_import_module_impl ?python_source:embed_python_source py_module
  in
  let shared_signatures = Shared.gen_all_signatures of_pyo_ret_type in
  let shared_impls =
    Shared.gen_all_functions of_pyo_ret_type (`Custom py_class)
  in
  let specs = Specs_file.read signatures in
  let needs_base, needs_todo, needs_not_implemented =
    check_signatures_file signatures
  in
  assert_base_and_ret_type_good needs_base of_pyo_ret_type;
  (* impls -> implementations *)
  let%bind impls =
    Or_error.all @@ gen_pyml_impls ~associated_with ~py_class ~specs
  in
  let needs_tuple2 = shared_impl_needs.t2 in
  let needs_tuple3 = shared_impl_needs.t3 in
  let needs_tuple4 = shared_impl_needs.t4 in
  let needs_tuple5 = shared_impl_needs.t5 in
  match caml_module with
  | Some caml_module ->
      Or_error.return
      @@ print_full ~caml_module ~shared_signatures ~shared_impls ~specs ~impls
           ~import_module_impl ~needs_base ~needs_todo ~needs_not_implemented
           ~needs_tuple2 ~needs_tuple3 ~needs_tuple4 ~needs_tuple5
  | None ->
      Or_error.return
      @@ print_impls ~shared_impls ~impls ~import_module_impl ~needs_base
           ~needs_todo ~needs_not_implemented ~needs_tuple2 ~needs_tuple3
           ~needs_tuple4 ~needs_tuple5

let main () =
  match Cli.parse_cli () with
  | Ok opts -> (
      match run opts with
      | Ok _ -> Caml.exit 0
      | Error err -> prerr_endline @@ Error.to_string_hum err)
  | Error exit_code -> Caml.exit exit_code

let () = main ()
