# Handling Tuples

Tuples are sort of weird....As of now, `pyml_bindgen` can't handle tuples directly :(

For now what you need to do is to create a little helper module that "wraps" the tuple you need to pass in to Python or return from Python.

Say you need to get an `int * string` tuple in and out of Python.  You should make a module something like this:

```ocaml
module rec Tuple_int_string : sig
  type t

  val make : int -> string -> t

  val to_pyobject : t -> Pytypes.pyobject
  val of_pyobject : Pytypes.pyobject -> t

  val print_endline : t -> unit
end = struct
  type t = int * string

  let make i s = (i, s)

  let to_pyobject (i, s) =
    Py.Tuple.of_tuple2 (Py.Int.of_int i, Py.String.of_string s)

  let of_pyobject pyo =
    let i, s = Py.Tuple.to_tuple2 pyo in
    (Py.Int.to_int i, Py.String.to_string s)

  let print_endline (i, s) = print_endline @@ string_of_int i ^ " " ^ s
end
```

Then you can put that with the code that `pyml_bindgen` generates for whatever class you're actually trying to bind.

In the val specs that you write, just refer to the `Tuple_int_string` module like any other:

```ocaml
val foo : x:Tuple_int_string.t -> unit -> Tuple_int_string.t
```

As long as you properly wrote the `to_pyobject` and `of_pyobject`, then it should work :)

There is a Cram test [here](https://github.com/mooreryan/pyml_bindgen/tree/main/test/binding_tuples.t) that illustrates this idea.  Just note that some of the bash stuff in the `run.t` file is to automate it, but you'd probably do that part by hand.
