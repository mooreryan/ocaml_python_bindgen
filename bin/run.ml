open! Base
open! Stdio
open! Lib

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

let read_signatures_file fname =
  In_channel.read_lines fname
  |> List.filter ~f:(fun s -> not @@ Re2.matches is_comment s)
  |> String.concat ~sep:" " |> clean_signatures

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

let print_full ~caml_module ~shared_signatures ~shared_impls ~signatures ~impls
    ~import_module_impl =
  print_dbl_endline import_module_impl;
  print_endline [%string "module %{caml_module} : sig"];
  List.iter shared_signatures ~f:print_dbl_endline;
  List.iter signatures ~f:print_dbl_endline;
  print_endline "end = struct";
  List.iter shared_impls ~f:print_dbl_endline;
  List.iter impls ~f:print_dbl_endline;
  print_endline "end"

let print_impls ~shared_impls ~impls ~import_module_impl =
  print_dbl_endline import_module_impl;
  List.iter shared_impls ~f:print_dbl_endline;
  List.iter impls ~f:print_dbl_endline

let run { Cli.signatures; py_module; py_class; caml_module } =
  let _x = caml_module in
  let import_module_impl = Shared.gen_import_module_impl py_module in
  let shared_signatures = Shared.gen_all_signatures () in
  let shared_impls = Shared.gen_all_functions ~py_class in
  let signatures = read_signatures_file signatures in
  (* impls -> implementations *)
  let%bind impls = Or_error.all @@ gen_pyml_impls ~py_class ~signatures in
  match caml_module with
  | Some caml_module ->
      Or_error.return
      @@ print_full ~caml_module ~shared_signatures ~shared_impls ~signatures
           ~impls ~import_module_impl
  | None ->
      Or_error.return @@ print_impls ~shared_impls ~impls ~import_module_impl
