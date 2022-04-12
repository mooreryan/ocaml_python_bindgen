# Getting Started

To get started, let's revisit the [example](index.md#quick-start) on the main page.  This time, we will add a bit more to it.

```python
class Thing:
    def __init__(self, x):
        self.x = x

    def add(self, y):
        return self.x + y

    @staticmethod
    def sub(a, b):
        return a - b
```

Save that in a file called `thing.py`.  Just to make it clear, the Python module will be called `thing`, and the class in that module will be called `Thing`.  Of course, we can name the OCaml module whatever we'd like, but why not name it `Thing` as well?

While there are many ways you may want to write a binding for this class by-hand, `pyml_bindgen` forces you to do things in a particular way, i.e., using named arguments.

## Binding constructors

`__init__` in Python constructs an instance of the class.  While in Python you don't usually call `__init__` directly, it is the way to instantiate classes when using `pyml_bindgen`.

In val specs for `pyml_bindgen`, we use `t` to represent the OCaml module/Python class you're working on, and so, `__init__` will return `t`.

Python:

```python
def __init__(self, x):
    self.x = x
```

OCaml:

```ocaml
val __init__ : x:int -> unit -> t
```

The other thing to note is that the last argument to method bindings must be `unit`.

### Using a different name for functions

Sometimes you may want to use a different name for a function or an argument on the OCaml side than is used on the Python side.  This will often be the case for binding constructors.  To do so you can use the `py_fun_name` attribute.  Check it out.

```ocaml
val create : x:int -> unit -> t
[@@py_fun_name __init__]
```

This tells `pyml_bindgen` that we want to use `create` on the OCaml side, and bind it to the Python `__init__` function for the class we're currently working on.

For more on this, check out the [attributes](https://github.com/mooreryan/ocaml_python_bindgen/tree/main/examples/attributes) example on GitHub.

## Binding instance methods

Instance methods are those that are called on instances of a Python class.  In Python, instance methods take `self` (a reference to the object) as the first argument.  So when binding instance methods with `pyml_bindgen`, the first argument must be `t`.  The middle arguments should be named (or optional) and the final argument should be `unit`.

Python:

```python
def add(self, y):
    return self.x + y
```

OCaml:

```ocaml
val add : t -> y:int -> unit -> int
```

*The [instance methods](instance-methods.md) section has more info on binding instance methods.*

## Binding static methods

Python static methods are methods associated with a class, but that don't have access to class-wide state, or access to object state.  You can still call them on either instances of a class or the class itself, but it won't have access to any of that internal state.

Binding these with `pyml_bindgen` is pretty much like writing val specs for regular OCaml functions, except that they don't start with a `t` argument, and each argument must be named (or optional) and the final argument must be `unit`.

Python:

```python
@staticmethod
def sub(a, b):
    return a - b
```

OCaml:

```ocaml
val sub : a:int -> b:int -> unit -> int
```

*See [class & static methods](instance-methods.md) for more info on binding static methods.*

## Binding instance attributes

*Note: Currently, you can only bind attribute getters automatically.  If you need setters as well, you'll have to write them by hand :)*

In the `__init__` function of the `Thing` class, you can see that we set an instance variable/attribute `x` on instance creation.  You can expose functions in your OCaml interface to access Python instance attributes, by providing a function with the same name as the attribute that takes `t`.

```ocaml
val x : t -> int
```

*You can find more info on binding attributes in the [attributes & properties](attributes.md) section of the manual.*

## Running pyml_bindgen

Let's put all those val specs into a file called `val_specs.txt`.  Then, we can run `pyml_bindgen`!

```
$ pyml_bindgen val_specs.txt thing Thing --caml-module=Thing --of-pyo-ret-type=no_check > lib.ml
```

* `val_specs.txt` is the file with value specifications
* `thing` is the python module (this time we got it from the name of our Python script
* `Thing` is the name of the Python class we're binding
* The `--caml-module=Thing` option tells `pyml_bindgen` to generate a module and signature called `Thing` based on the val specs you provided.  If you leave this flag out, `pyml_bindgen` will just generate the implementations that you can manually add where you want.
* The `--of-pyo-ret-type=no_check` argument tells `pyml_bindgen` not to check that the Python class is what you expect it to be.  If there is some weird bug in the Python, or a mistake in your bindings, you'll get a runtime error!  The other options for this are `option` and `or_error`, which will check that Python classes are correct, but you'll have to deal with the possibility of error explicitly.

## Using the generated module

While you're here, let's go ahead and make a quick executable that uses the generated module.  Add the following files to your working directory.

`dune`

```
(executable
 (name run)
 (libraries pyml))
```

`run.ml`

```ocaml
(* Remember that we named the generated file lib.ml. *)
open Lib

(* Don't forget to initialize Python! *)
let () = Py.initialize ()

let thing = Thing.__init__ ~x:10 ()

let () = print_endline @@ string_of_int @@ Thing.x thing
let () = print_endline @@ string_of_int @@ Thing.add thing ~y:20 ()
let () = print_endline @@ string_of_int @@ Thing.sub ~a:1 ~b:2 ()
```

Now run it!

```
$ dune exec ./run.exe
10
30
-1
```

## Next steps

These are just a few of the ways you can use `pyml_bindgen`.  I suggest you take a look at the [examples](https://github.com/mooreryan/ocaml_python_bindgen/tree/main/examples) on GitHub for more information.
