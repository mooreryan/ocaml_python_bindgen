# Attributes

You can attach certain attributes to your value specifications to change their behavior.

Currently, the only recognized attributes are `py_fun_name` and `py_arg_name`.

You can use them to bind a Python method names and argument names to something else on the OCaml side.

## Example

For example, rather than having a `Cat.__init__` method to call from the OCaml side (i.e., to make a new Python `Cat` object), you can bind the Python `__init__` function to something more idiomatic like `create` or whatever you want.

```ocaml
val create : t -> ...
[@@py_fun_name __init__]
```

Another common use for this is to bind the Python `__str__` method for a class to `to_string` on the OCaml side.

You can do this with any function. One reason is that you may want to have some type safety with a polymorphic Python function. While you could pass in [Py.Object.t](https://mooreryan.github.io/ocaml_python_bindgen/types/#pytypes) directly, you could also use attributes to bind multiple OCaml functions to the same Python method. E.g.,

```ocaml
val eat : t -> num_mice:int -> unit -> unit

val eat_part : t -> num_mice:float -> unit -> unit
[@@py_fun_name eat]
```

In this case, we have one `eat` function for `int` and one for `float`.

## Full example

For a full working example see the [attributes](https://github.com/mooreryan/ocaml_python_bindgen/tree/main/examples/attributes) example on GitHub.

The linked example also shows how to use `py_arg_name`.

## Warning

- If you specify the `py_fun_name` more than once, it will do something wonky. Eventually, the program will treat this as an error, but for now, it is on you to avoid doing it.
- Attributes have to start a line. I.e., if you have more than one attribute, you can't put them on the same line. They must go on separate lines.
