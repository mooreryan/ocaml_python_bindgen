open! Base

(* TODO better to move this check into the Cmdliner section. *)
let check_opts (opts : Main_cli.opts) =
  match (opts.caml_module, opts.split_caml_module) with
  | None, Some _ ->
      Bin_utils.exit ~code:1
        "ERROR: --split-caml-module was given but --caml-module was not"
  | None, None | Some _, None | Some _, Some _ -> ()

let main () =
  match Main_cli.parse_argv () with
  | Ok opts -> (
      check_opts opts;
      match Bin_utils.run opts with
      | Ok _ -> Caml.exit 0
      (* TODO non-zero exit code here? *)
      | Error err -> Stdio.prerr_endline @@ Error.to_string_hum err)
  | Error exit_code -> Caml.exit exit_code

let () = main ()
