# Attributes

This directory has an example of using the `py_fun_name` and `py_arg_name` attributes.

## `py_fun_name`

`py_fun_name` allows you to use different names for functions on the OCaml side than the original Python library had used.

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

## `py_arg_name`

`py_arg_name` allows you to use different argument names on the OCaml side from those that are used on the Python side.

For example, you may have a Python function that has an argument name that is the same as some reserved OCaml keyword. In this case, you can use `py_arg_name` to map it to something else on the OCaml side.

```ocaml
val f : t -> method_:string -> unit -> string
[@@py_arg_name method_ method]
```

As you see, the attribute is followed by two items, the first is the argument name on the OCaml side, and the second is the argument name on the Python side (i.e., as it will be called in Python).

## Multiple attributes

You can use multiple attributes on a single val spec. Here is one from this example project.

```ocaml
val say_this : t -> w:string -> x:string -> y:string -> z:string -> unit -> string
[@@py_fun_name say]
[@@py_arg_name w a]
[@@py_arg_name x b]
[@@py_arg_name y c]
[@@py_arg_name z d]
```

Here is the python function.

```python
class Cat:

    ...

    def say(self, a, b, c, d):
        return(f'{self.name} says {a}, {b}, {c} and {d}.')
```

As you see, the Python function is called `say` and not `say_this`. Also, the arguments to the Python function are `a`, `b`, `c`, and `d`, whereas we bind them to `w`, `x`, `y`, and `z` on the OCaml side.

_Note: Multiple attributes on the same value spec must go on separate lines._
