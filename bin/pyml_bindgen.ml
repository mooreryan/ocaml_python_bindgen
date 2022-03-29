open! Base

let main () =
  match Cli.parse_cli () with
  | Ok opts -> (
      match Bin_utils.run opts with
      | Ok _ -> Caml.exit 0
      (* TODO non-zero exit code here? *)
      | Error err -> Stdio.prerr_endline @@ Error.to_string_hum err)
  | Error exit_code -> Caml.exit exit_code

let () = main ()
