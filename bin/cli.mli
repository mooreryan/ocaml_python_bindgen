open! Base

type opts = {
  signatures : string;
  py_module : string;
  py_class : string;
  caml_module : string option;
}

val parse_cli : unit -> (opts, int) Result.t
(** If successful, return the [opts]. If failure, return exit code. *)
