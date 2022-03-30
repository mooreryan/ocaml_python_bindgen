open! Base

let ok_or_abort x =
  Or_error.iter_error x ~f:(fun err ->
      Bin_utils.exit ~code:1 @@ Error.to_string_hum err)

(* TODO just fix the run function so it won't raise... *)
let run_wrapper opts =
  Or_error.join @@ Or_error.try_with (fun () -> Bin_utils.run opts)

let fname = (Sys.get_argv ()).(1)

let opts =
  let open Stdio in
  let opts =
    In_channel.with_file fname ~f:(fun ic ->
        Or_error.all @@ List.rev @@ snd
        @@ In_channel.fold_lines ic ~init:(0, []) ~f:(fun (i, things) line ->
               if i > 0 then (i + 1, Cli.opts_of_string line :: things)
               else (i + 1, things)))
  in
  let open Or_error.Let_syntax in
  match%bind opts with
  | [] -> Or_error.error_string "Got no options"
  | opts -> Or_error.return opts

let () =
  match opts with
  | Ok opts -> ok_or_abort @@ Or_error.all_unit @@ List.map opts ~f:run_wrapper
  | Error err -> Bin_utils.exit ~code:1 (Error.to_string_hum err)
