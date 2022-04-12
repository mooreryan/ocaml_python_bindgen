# Class & Static Methods; Functions

Value specs for class/static methods look like this:

```ocaml
val f : a:'a -> ?b:'b -> ... -> unit -> 'c
```

## Rules

* The final function argument (penultimate type expression) must be `unit`.
* The return type can be any of the [types](./types.md) mentioned earlier.
* The remaining function arguments must either be named or optional.  The types of these arguments can be any of the types mentioned earlier.

## Examples

```ocaml
val add_item : fruit:string -> price:float -> unit -> unit
val subtract : x:int -> ?y:int -> unit -> int
```

## Binding `__init__`

`__init__` methods are called when constructing new Python objects.  Here is an example.

Python:

```python
class Person:
    def __init__(self, name, age):
	    self.name = name
        self.age = age
```

And the OCaml binding....

```ocaml
val __init__ : name:string -> age:int -> unit -> t
```

If you want to generate functions that ensure the class is correct, you can return `t option` or `t Or_error.t` instead.

### Using a different name

You can use a more natural name for the `__init__` function.  E.g., something like `create` by using [attributs](./ocaml-attributes.md).

```ocaml
val create : name:string -> age:int -> unit -> t
[@@py_fun_name __init__]
```

## Functions

You can also bind functions that are not associated with a class.

The rules are the same for the class and static methods.  To tell `pyml_bindgen` that you are actually binding module functions rather than class methods, you have to pass in a command line option `--associated-with module`.
