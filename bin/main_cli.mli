open! Base

type opts = {
  signatures : string;
  py_module : string;
  py_class : string;
  associated_with : [ `Class | `Module ];
  caml_module : string option;
  split_caml_module : string option;
  embed_python_source : string option;
  of_pyo_ret_type : [ `No_check | `Option | `Or_error ];
}

val opts_of_string : string -> opts Or_error.t

val parse_argv : unit -> (opts, int) Result.t
(** If successful, return the [opts]. If failure, return exit code. *)
