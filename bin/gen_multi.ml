open! Base

module Cli = struct
  open Cmdliner

  let file_term =
    let doc =
      "TSV file with CLI opts.  The first line (header) is ignored.  The \
       columns should be should be: signatures [tab] py_module [tab] py_class \
       [tab] associated_with [tab] caml_module [tab] embed_python_source [tab] \
       of_pyo_ret_type."
    in
    Arg.(
      required & pos 0 (some non_dir_file) None & info [] ~docv:"CLI_OPTS" ~doc)

  let info =
    let doc = "generate multiple pyml_bindgen bindings with one command" in
    let man =
      [
        `S Manpage.s_description;
        `P
          "In some cases, it can be simpler to use a single command to \
           generate multiple bindings.";
        `P
          "The input file is a 7 column TSV file.  Each column matches one of \
           the arguments to pyml_bindgen that you would give on the command \
           line.  The order of the columns must be: signatures, py_module, \
           py_class, associated_with, caml_module, embed_python_source, and \
           of_pyo_return_type.";
        `P
          "You fill in the columns more or less in the same way as you would \
           pass things in to pyml_bindgen.  For optional flags, if you don't \
           want to apply then, you can leave them blank, or you can use NA or \
           na.";
        `S Manpage.s_examples;
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
    Cmd.info "gen_multi" ~version:Lib.Version.version ~doc ~man ~exits:[]

  let parse_argv () =
    match Cmd.eval_value @@ Cmd.v info file_term with
    | Ok (`Ok files) -> Ok files
    | Ok `Help | Ok `Version -> Error 0
    | Error _ -> Error 1
end

let ok_or_abort x =
  Or_error.iter_error x ~f:(fun err ->
      Bin_utils.exit ~code:1 @@ Error.to_string_hum err)

(* TODO just fix the run function so it won't raise... *)
let run_wrapper opts =
  Or_error.join @@ Or_error.try_with (fun () -> Bin_utils.run opts)

(* Each row of the input file is a pyml_bindgen CLI specification. *)
let get_cli_opts fname =
  let open Stdio in
  let open Or_error.Let_syntax in
  let opts =
    In_channel.with_file fname ~f:(fun ic ->
        Or_error.all @@ List.rev @@ snd
        @@ In_channel.fold_lines ic ~init:(0, []) ~f:(fun (i, things) line ->
               if i > 0 then (i + 1, Main_cli.opts_of_string line :: things)
               else (i + 1, things)))
  in
  match%bind opts with
  | [] -> Or_error.error_string "Got no options"
  | opts -> Or_error.return opts

let run fname =
  match get_cli_opts fname with
  | Ok opts -> ok_or_abort @@ Or_error.all_unit @@ List.map opts ~f:run_wrapper
  | Error err -> Bin_utils.exit ~code:1 (Error.to_string_hum err)

let main () =
  match Cli.parse_argv () with
  | Ok fname -> run fname
  | Error exit_code -> Caml.exit exit_code

let () = main ()
