open! Base

type t

val of_pyobject : Pytypes.pyobject -> t Or_error.t

val to_pyobject : t -> Pytypes.pyobject

val create : flavor:string -> unit -> t Or_error.t

val flavor : t -> string
