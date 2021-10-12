# pyml_bindgen

Generate [pyml](https://github.com/thierry-martinez/pyml) bindings from OCaml value specifications.

While you *could* write all your `pyml` bindings by hand, it can be tedious and it gets old real quick.  While `pyml_bindgen` can't yet auto-generate all the bindings you may need, it can definitely take care of a lot of the tedious and repetitive work you need to do when writing bindings for a big Python library!! 💖

* [Install](#install)
* [Example](#example)
* [Docs](#docs)
* [Value specification rules](#value-specification-rules)
  * [Types](#types)
  * [Function and argument names](#function-and-argument-names)
  * [Attributes & properties](#attributes--properties)
  * [Instance methods](#instance-methods)
  * [Class/static methods](#classstatic-methods)
* [License](#license)

## Install

`pyml_bindgen` is a [Dune](https://dune.readthedocs.io/en/stable/) project, so you *should* be able to clone the repository and build it with `dune` as long as you have the proper dependencies installed 🤞

```
$ git clone https://github.com/mooreryan/pyml_bindgen.git
$ cd pyml_bindgen
$ opam install . --deps-only --with-doc --with-test
$ dune test && dune build --profile=release && dune install
$ pyml_bindgen --help
... help screen should show up ...
```

## Example

Here's a simple Python class...just an initializer (`__init__`), instance method (`foo`), and class method (aka static method) `bar`.  Put it in a file called `silly_module.py`.

```python
class Silly:
    def __init__(self, x, y):
        self.x = x
        self.y = y

    def foo(self, a, b):
        return a + b + self.x + self.y

    @staticmethod
    def bar(a, b):
        return a + b
```

Now, write some `mli` value specifications representing the bindings.  In other words, write value specs for how you want to use this Python class from your OCaml code.  Put it in a file called `signatures.txt`.

```ocaml
val __init__ : x:int -> y:int -> unit -> t option

val x : t -> int
val y : t -> int

val foo : t -> a:int -> b:int -> unit -> int

val bar : a:int -> b:int -> unit -> int
```

*Note: You have to follow certain rules when writing value specifications.  See the [docs](#docs) for more info.*

Next, run `pyml_bindgen` on the value specifications file to generate an OCaml module with [pyml](https://github.com/thierry-martinez/pyml) bindings.  The [ocamlformat](https://github.com/ocaml-ppx/ocamlformat) command is optional, of course.

*For now, you have to run this manually on the specs you write.  One day, it would be nice to turn this into a ppx, but it's not too bad to run yourself :)*

```
$ pyml_bindgen --caml-module=Silly signatures.txt silly_module Silly > lib.ml
$ ocamlformat --enable-outside-detected-project lib.ml
```

After running `ocamlformat`, `lib.ml` should look something like this.

```ocaml
let filter_opt l = List.filter_map Fun.id l

let import_module () = Py.Import.import_module "silly"

module Silly : sig
  type t

  val of_pyobject : Pytypes.pyobject -> t option

  val to_pyobject : t -> Pytypes.pyobject

  val __init__ : x:int -> y:int -> unit -> t option

  val x : t -> int

  val y : t -> int

  val foo : t -> a:int -> b:int -> unit -> int

  val bar : a:int -> b:int -> unit -> int
end = struct
  type t = Pytypes.pyobject

  let is_instance pyo =
    let py_class = Py.Module.get (import_module ()) "Silly" in
    Py.Object.is_instance pyo py_class

  let of_pyobject pyo = if is_instance pyo then Some pyo else None

  let to_pyobject x = x

  let __init__ ~x ~y () =
    let callable = Py.Module.get (import_module ()) "Silly" in
    let kwargs =
      filter_opt [ Some ("x", Py.Int.of_int x); Some ("y", Py.Int.of_int y) ]
    in
    of_pyobject @@ Py.Callable.to_function_with_keywords callable [||] kwargs

  let x t = Py.Int.to_int @@ Py.Object.find_attr_string t "x"

  let y t = Py.Int.to_int @@ Py.Object.find_attr_string t "y"

  let foo t ~a ~b () =
    let callable = Py.Object.find_attr_string t "foo" in
    let kwargs =
      filter_opt [ Some ("a", Py.Int.of_int a); Some ("b", Py.Int.of_int b) ]
    in
    Py.Int.to_int @@ Py.Callable.to_function_with_keywords callable [||] kwargs

  let bar ~a ~b () =
    let class_ = Py.Module.get (import_module ()) "Silly" in
    let callable = Py.Object.find_attr_string class_ "bar" in
    let kwargs =
      filter_opt [ Some ("a", Py.Int.of_int a); Some ("b", Py.Int.of_int b) ]
    in
    Py.Int.to_int @@ Py.Callable.to_function_with_keywords callable [||] kwargs
end
```

As you see, it generated an OCaml module called `Silly` with some additional useful functions.  Now that wouldn't be too bad to write by hand, but if you have a bunch of big Python classes, with lots of functions and a complicated interface, it can get really messy really fast!

You can now use `Lib.Silly` like any other OCaml module, but it will be running Python under the hood.  Just don't forget to initialize the Python interpreter first.  Check it out!

```ocaml
(* Save this in run.ml *)
open! Base
open Lib
open Stdio

let () = Py.initialize ()

let silly = Option.value_exn (Silly.__init__ ~x:1 ~y:2 ())

let () = print_endline ("x: " ^ Int.to_string (Silly.x silly))
let () = print_endline ("y: " ^ Int.to_string (Silly.y silly))
let () = print_endline ("foo: " ^ Int.to_string (Silly.foo silly ~a:10 ~b:20 ()))
let () = print_endline ("bar: " ^ Int.to_string (Silly.bar ~a:10 ~b:20 ()))
```

*Note: You don't need to use [Base](https://ocaml.janestreet.com/ocaml-core/latest/doc/base/index.html) in your code.  It's used here as this example is taken from the [tests](https://github.com/mooreryan/pyml_bindgen/tree/main/test/basic_class_binding.t).*

Oh, and don't forget your [Dune](https://dune.readthedocs.io) file either...

```
(executable
 (names run)
 (libraries base pyml stdio))
```

Finally, go ahead an run it.

```
$ dune exec ./run.exe
x: 1
y: 2
foo: 33
bar: 30
```
There you go....Hello, (Python) World!

## Value specification rules

You have to follow some rules while writing value specifications for functions you want to bind.

To start, there are (more or less) three types of methods in Python that you can to bind:  attributes/properties, instance methods, and class/static methods.

`pyml_bindgen` figures out which type of method you want to bind by looking at the value specifications.

*Note: there are [tests](https://github.com/mooreryan/pyml_bindgen/tree/main/test) that demonstrate many of the rules for properly writing value specifications.   Check 'em out!*

### Types

Not all OCaml types are allowed.  For function arguments, you can use

* `int`
* `float`
* `string`
* `bool`
* `t` (i.e., the main type of the current module)
* Other module types (e.g., `Span.t`, `Doc.t`, `Apple_pie.t`)
* Lists of any of the above types

For return types, you can use all of the above types plus `unit`.   Additionally, you can return `'a option` and `'a Or_error.t` where `'a'` is any of the previously mentioned types.

TODO mention the hack for Python dictionaries...

### Function and argument names

You can't pick just any old name for your functions and arguments :)

The main thing to remember is in addition to being valid OCaml names, they must also be [valid python names](https://docs.python.org/3/reference/lexical_analysis.html#identifiers).  This is because we pass the function name and argument names "as-is" to Python.

In addition to that, there are a couple other things to keep in mind.

* Argument names that match any of the types mentioned [above](#allowed-types) are not allowed.
* Argument names that start with any of the types mentioned [above](#allowed-types) are not allowed.  (E.g., `val foo : t -> int_thing:string -> unit -> float` will fail.)
* Argument names that end with any of the above types are actually okay.  You probably shouldn't name them like this but it works.  Really, it's just an artifact of the parsing :) This will probably be fixed at some point....
* Function names and arguments can start with underscores (e.g., `__init__`) but they cannot be *all* underscores.  E.g., `val ____ : ...` will not parse.

### Attributes & properties

Value specifications that take a single argument `t` will be interpreted as bindings to Python attributes or properties.

Value specs for attributes and properties look like this:

```ocaml
val f : t -> 'a
```

#### Rules

* The first and only function argument must be `t`.
* The return type can be any of the types mentioned [above](#allowed-types).

#### Examples

```ocaml
val x : t -> int
val name : t -> string
val price : t -> float
```

### Instance methods

Value specs for instance methods look like this:

```ocaml
val f : t -> a:'a -> ?b:'b -> ... -> unit -> 'c
```

#### Rules

* The first argument must be `t`.
* The final function argument (penultimate type expression) must be `unit`.
* The return type can be any of the types mentioned [above](#allowed-types).
* The remaining function arguments must either be named or optional.  The types of these arguments can be any of the types mentioned [above](#allowed-types).

Note on the final unit argument...I require all arguments that bind to Python method arguments be named or optional.  Python will often have optional named arguments at the end of a function's arguments.  In OCaml, these can't be erased unless you have a unit argument that comes after.  So, to keep the APIs all looking similar, I decided that all instance and static methods would end in a final unit argument.  This may change in the future, but for now, that's how it works :)

#### Examples

```ocaml
val add_item : t -> fruit:string -> price:float -> unit -> unit
val subtract : t -> x:int -> ?y:int -> unit -> int
```

### Class/static methods

Value specs for class/static methods look like this:

```ocaml
val f : a:'a -> ?b:'b -> ... -> unit -> 'c
```

#### Rules

* The final function argument (penultimate type expression) must be `unit`.
* The return type can be any of the types mentioned [above](#allowed-types).
* The remaining function arguments must either be named or optional.  The types of these arguments can be any of the types mentioned [above](#allowed-types).

#### Examples

```ocaml
val add_item : fruit:string -> price:float -> unit -> unit
val subtract : x:int -> ?y:int -> unit -> int
```

## Miscellaneous

### You can only bind methods, not functions

Currently, you can only bind to functions within Python classes (a.k.a., Python methods).  At some point, I will change it so you can also bind Python functions that aren't associated with a class.

Here's what I mean.  A function that isn't associated with a class currently cannot be bound with `pyml_bindgen`.

```python
# Can't bind this
def foo(x, y):
    return x + y
```

But that same function associated with a class, can be bound by `pyml_bindgen`.

```python
# Can bind this
class Apple:
    @staticmethod
    def foo(x, y):
        return x + y
```

Let me just be clear that `pyml` can bind this function just fine, only, you would need to write this binding by hand.

## License

[![license MIT or Apache
2.0](https://img.shields.io/badge/license-MIT%20or%20Apache%202.0-blue)](https://github.com/mooreryan/pasv)

Copyright (c) 2021 Ryan M. Moore.

Licensed under the Apache License, Version 2.0 or the MIT license, at your option. This program may not be copied, modified, or distributed except according to those terms.
