# Handling Tuples

Tuples are sort of weird....As of now, `pyml_bindgen` can't handle tuples directly :(

For now what you need to do is to create a little helper module that "wraps" the tuple you need to pass in to Python or return from Python.  *(Or just write the binding by hand...)*

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

Then you can put that with the code that `pyml_bindgen` generates for whatever class you're actually trying to bind.  Perhaps something like this...

```ocaml
module rec Tuple_int_string : sig
...
end = struct
...
end

and My_cool_thing : sig

...

val foo : x:Tuple_int_string.t -> unit -> Tuple_int_string.t

...

end
```

(You get the idea.)

In the val specs that you write, just refer to the `Tuple_int_string` module like any other:

```ocaml
val foo : x:Tuple_int_string.t -> unit -> Tuple_int_string.t
```

The key here is to have a module that has working `to_pyobject` and `of_pyobject` functions.  If these two functions know how to properly get your type/module into and out of Python-land, then it should work :)

There is a Cram test [here](https://github.com/mooreryan/pyml_bindgen/tree/main/test/binding_tuples.t) that illustrates this idea.  Just note that some of the bash stuff in the `run.t` file is to automate it, but you'd probably do that part by hand.

*Note: At some point, I will work up a full example with tuples and other types that you can't yet deal with directly in `pyml_bindgen`.
