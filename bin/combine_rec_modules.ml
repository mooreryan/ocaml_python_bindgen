open! Base

let module_re = Re.Perl.compile_pat "module ([a-zA-Z0-9_])+"

let first_module name = "module rec " ^ name

let non_first_module name = "and " ^ name

let fix_module_line modules_seen group =
  let module_name = Re.Group.get group 1 in
  let is_first_module = modules_seen = 0 in
  if is_first_module then first_module module_name
  else non_first_module module_name

let process_module_line modules_seen line =
  let new_line = Re.replace module_re line ~f:(fix_module_line modules_seen) in
  Stdio.print_endline new_line;
  modules_seen + 1

let process_non_module_line modules_seen line =
  Stdio.print_endline line;
  modules_seen

let process_line modules_seen line =
  if Re.execp module_re line then process_module_line modules_seen line
  else process_non_module_line modules_seen line

let process_file modules_seen fname =
  Stdio.In_channel.with_file fname ~f:(fun ic ->
      Stdio.In_channel.fold_lines ic ~init:modules_seen ~f:process_line)

let usage =
  [%string
    "pyml_bindgen version: %{Lib.Version.version}\n\
     usage: combine_rec_modules <a.ml> [b.ml ...] > lib.ml"]

let exit ?(code = 0) msg =
  Stdio.prerr_endline msg;
  Caml.exit code

(* Ensures there is at least one file given. *)
let parse_args args =
  match Array.to_list args with
  | [ _exe ] -> exit usage
  | _exe :: fnames -> fnames
  | [] -> assert false

let check_fnames fnames =
  let errors =
    List.filter_map fnames ~f:(fun fname ->
        if Caml.Sys.file_exists fname then None else Some fname)
  in
  match errors with
  | [] -> ()
  | [ fname ] ->
      let msg = [%string "ERROR -- File %{fname} does not exist"] in
      exit ~code:1 msg
  | fnames ->
      let fnames = String.concat fnames ~sep:", " in
      let msg = [%string "ERROR -- These files do not exist: %{fnames}"] in
      exit ~code:1 msg

(* TODO this will exit with an error code, but stuff will still be printed to
   the outfile. Could be confusing. *)
let check_modules_seen = function
  | 0 ->
      exit ~code:1
        [%string "ERROR -- I didn't see any modules in the input files"]
  | 1 ->
      exit ~code:1 [%string "ERROR -- I only saw one module in the input files"]
  | _n -> ()

let () =
  let fnames = parse_args (Sys.get_argv ()) in
  check_fnames fnames;
  let modules_seen = List.fold fnames ~init:0 ~f:process_file in
  check_modules_seen modules_seen
