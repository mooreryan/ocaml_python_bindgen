open! Base

let fname = (Sys.get_argv ()).(1)

let opts =
  let open Stdio in
  In_channel.with_file fname ~f:(fun ic ->
      List.rev @@ snd
      @@ In_channel.fold_lines ic ~init:(0, []) ~f:(fun (i, things) line ->
             if i > 0 then
               (i + 1, Or_error.ok_exn (Cli.opts_of_string line) :: things)
             else (i + 1, things)))

let () =
  match Or_error.all_unit @@ List.map opts ~f:Bin_utils.run with
  | Ok () -> ()
  | Error error -> Bin_utils.exit ~code:1 @@ Error.to_string_hum error
