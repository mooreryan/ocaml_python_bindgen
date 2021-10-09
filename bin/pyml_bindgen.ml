open! Base
open Stdio

let main () =
  match Cli.parse_cli () with
  | Ok opts -> (
      match Run.run opts with
      | Ok _ -> Caml.exit 0
      | Error err -> prerr_endline @@ Error.to_string_hum err)
  | Error exit_code -> Caml.exit exit_code

let () = main ()
