open! Base

type opts = {
  signatures : string;
  py_module : string;
  py_class : string;
  caml_module : string option;
  of_pyo_ret_type : [ `No_check | `Option | `Or_error ];
  associated_with : [ `Class | `Module ];
  embed_python_source : string option;
}

val parse_cli : unit -> (opts, int) Result.t
(** If successful, return the [opts]. If failure, return exit code. *)
