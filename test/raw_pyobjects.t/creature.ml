module Bug = struct
  module Fly : sig
    type t

    val of_pyobject : Pytypes.pyobject -> t

    val to_pyobject : t -> Pytypes.pyobject

    val make : string -> t
  end = struct
    type t = string

    let of_pyobject = Py.String.to_string

    let to_pyobject = Py.String.of_string

    let make s = s
  end
end
