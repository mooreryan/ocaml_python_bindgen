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

While there are many ways you may want to write a binding for this class by-hand, `pyml_bindgen` forces you to do the obvious thing write OCaml functions with the same names as the Python methods.  You also need to use named (or optional) arguments.

## Binding constructors

`__init__` in Python constructs an instance of the class.  While you don't usually call `__init__` directly, it is the way to instantiate classes when using `pyml_bindgen`.

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

The other thing to note is that the last argument to method bindings must be `unit`.  See [here](todo.md) for more about why that is.

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

TODO: we only have tests for static methods, but class methods *should* be the same...check it!

Python static methods are methods associated with a class, but that don't have access to class-wide state, or access to object state.  You can still call them on either instances of a class or the class itself, but it won't have access to any of that internal state.

Binding these with `pyml_bindgen` is pretty much like writing val specs for regular OCaml functions, except that each argument must be named (or optional) and the final argument must be `unit`.

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

One thing to keep in mind is that many Python function can take values of different types.  We could bind `x` with an OCaml function that returns `float`.  In cases where you're binding polymorphic python functions, let the rest of your API guide you on how you'd like to type everything.

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

*For more info on `pyml_bindgen` options, see [here](todo.md).*

I ran `lib.ml` through `ocamlformat` so it's easier to read here, but of course, that's optional!

```
$ ocamlformat lib.ml --enable-outside-detected-project
```

And here's the output:

```ocaml
let filter_opt l = List.filter_map Fun.id l

let import_module () = Py.Import.import_module "thing"

module Thing : sig
  type t

  val of_pyobject : Pytypes.pyobject -> t option

  val to_pyobject : t -> Pytypes.pyobject

  val __init__ : x:int -> unit -> t

  val x : t -> int

  val add : t -> y:int -> unit -> int

  val sub : a:int -> b:int -> unit -> int
end = struct
  type t = Pytypes.pyobject

  let is_instance pyo =
    let py_class = Py.Module.get (import_module ()) "Thing" in
    Py.Object.is_instance pyo py_class

  let of_pyobject pyo = if is_instance pyo then Some pyo else None

  let to_pyobject x = x

  let __init__ ~x () =
    let callable = Py.Module.get (import_module ()) "Thing" in
    let kwargs = filter_opt [ Some ("x", Py.Int.of_int x) ] in
    of_pyobject @@ Py.Callable.to_function_with_keywords callable [||] kwargs

  let x t = Py.Int.to_int @@ Py.Object.find_attr_string t "x"

  let add t ~y () =
    let callable = Py.Object.find_attr_string t "add" in
    let kwargs = filter_opt [ Some ("y", Py.Int.of_int y) ] in
    Py.Int.to_int @@ Py.Callable.to_function_with_keywords callable [||] kwargs

  let sub ~a ~b () =
    let class_ = Py.Module.get (import_module ()) "Thing" in
    let callable = Py.Object.find_attr_string class_ "sub" in
    let kwargs =
      filter_opt [ Some ("a", Py.Int.of_int a); Some ("b", Py.Int.of_int b) ]
    in
    Py.Int.to_int @@ Py.Callable.to_function_with_keywords callable [||] kwargs
end
```

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
