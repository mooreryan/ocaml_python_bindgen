# Attributes

This directory has an example of using the `py_fun_name` attribute.  It allows you to use different names for functions on the OCaml side than the original Python library had used.

For example, rather than having a `Cat.__init__` method to call from the OCaml side (i.e., to make a new Python `Cat` object), you can bind the Python `__init__` function to something more idiomatic like `create` or whatever you want.

```ocaml
val create : t -> ...
[@@py_fun_name __init__]
```

Another common use for this is to bind the Python `__str__` method for a class to `to_string` on the OCaml side.

You can do this with any function.  One reason is that you may want to have some type safety with a polymorphic Python function.  While you could pass in [Py.Object.t](https://mooreryan.github.io/ocaml_python_bindgen/types/#pytypes) directly, you could also use attributes to bind multiple OCaml functions to the same Python method.  E.g.,

```ocaml
val eat : t -> num_mice:int -> unit -> unit

val eat_part : t -> num_mice:float -> unit -> unit
[@@py_fun_name eat]
```

In this case, we have one `eat` function for `int` and one for `float`.
