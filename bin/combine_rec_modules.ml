open! Base

module Cli = struct
  open Cmdliner

  (* Use string rather than file so we can do the nicer file checking. *)
  let files_term =
    let doc =
      "OCaml source files.  You can also pass in /dev/stdin to read from \
       standard input."
    in
    Arg.(non_empty & pos_all string [] & info [] ~docv:"FILE" ~doc)

  let info =
    let doc = "combine recursive modules into a single file" in
    let man =
      [
        `S Manpage.s_description;
        `P
          "You often need to generate recursive modules when binding cyclic \
           Python classes.  Since pyml_bindgen doesn't allow you to generate \
           recursive modules automatically, you can use this tool to convert \
           them.  It combines multiple pyml_bindgen generated OCaml modules \
           into a single file.";
        `P
          "While you could combine generated modules by hand, this tool helps \
           speed up the process when combining a lot of modules, or when you \
           need to automate the process (e.g., in a Dune rule or shell \
           script).";
        `S Manpage.s_examples;
        `P
          "Imagine you generated the files a.ml and b.ml with pyml_bindgen.  \
           Module A refers to module B and module B refers to module A, so \
           they are recursive modules.  However, pyml_bindgen doesn't \
           automatically generate them as recursive modules.  Instead, you can \
           use combine_rec_modules.";
        `P "a.ml contents:";
        `Pre "  module A : sig ... end = struct ... end";
        `P "b.ml contents:";
        `Pre "  module B : sig ... end = struct ... end";
        `P "Run combine_rec_modules:";
        `Pre "  \\$ combine_rec_modules a.ml b.ml > lib.ml";
        `P "Then lib.ml contents will be:";
        `Pre
          "module rec A : sig ... end = struct ... end\n\
           and B : sig ... end = struct ... end";
        `P "===";
        `P
          "You will often use this program with combine_rec_modules and \
           ocamlformat.";
        `Pre
          "  \\$ gen_multi cli_specs.tsv \\\\ \n\
          \    | combine_rec_modules /dev/stdin \\\\ \n\
          \    | ocamlformat --name a.ml - \\\\ \n\
          \    > lib.ml";
        `S Manpage.s_bugs;
        `P
          "Please report any bugs or issues on GitHub. \
           (https://github.com/mooreryan/pyml_bindgen/issues)";
        `S Manpage.s_see_also;
        `P
          "For full documentation, please see the GitHub page. \
           (https://github.com/mooreryan/pyml_bindgen)";
        `S Manpage.s_authors;
        `P "Ryan M. Moore <https://orcid.org/0000-0003-3337-8184>";
      ]
    in
    Cmd.info "combine_rec_modules" ~version:Lib.Version.version ~doc ~man
      ~exits:[]

  let parse_argv () =
    match Cmd.eval_value @@ Cmd.v info files_term with
    | Ok (`Ok files) -> Ok files
    | Ok `Help | Ok `Version -> Error 0
    | Error _ -> Error 1
end

let module_re = Re.Perl.compile_pat "module ([a-zA-Z0-9_]+)"

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

let check_fnames fnames =
  let errors =
    List.filter_map fnames ~f:(fun fname ->
        if Caml.Sys.file_exists fname then None else Some fname)
  in
  match errors with
  | [] -> ()
  | [ fname ] ->
      let msg = [%string "ERROR -- File %{fname} does not exist"] in
      Bin_utils.exit ~code:1 msg
  | fnames ->
      let fnames = String.concat fnames ~sep:", " in
      let msg = [%string "ERROR -- These files do not exist: %{fnames}"] in
      Bin_utils.exit ~code:1 msg

(* TODO this will exit with an error code, but stuff will still be printed to
   the outfile. Could be confusing. *)
let check_modules_seen = function
  | 0 ->
      Bin_utils.exit ~code:1
        [%string "ERROR -- I didn't see any modules in the input files"]
  | 1 ->
      Bin_utils.exit ~code:1
        [%string "ERROR -- I only saw one module in the input files"]
  | _n -> ()

let run fnames =
  check_fnames fnames;
  let modules_seen = List.fold fnames ~init:0 ~f:process_file in
  check_modules_seen modules_seen

let main () =
  match Cli.parse_argv () with
  | Ok fnames -> run fnames
  | Error exit_code -> Caml.exit exit_code

let () = main ()
