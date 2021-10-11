# pyml_bindgen

Generate [pyml](https://github.com/thierry-martinez/pyml) bindings from OCaml signatures.

* [Install](#install)
* [Example](#example)
* [Docs](#docs)
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

Now, write some `mli` signatures representing the bindings.  In other words, write signatures for how you want to use this Python class from your OCaml code.  Put it in a file called `signatures.txt`.

```ocaml
val __init__ : x:int -> y:int -> unit -> t option

val x : t -> int
val y : t -> int

val foo : t -> a:int -> b:int -> unit -> int

val bar : a:int -> b:int -> unit -> int
```

*Note: You have to follow certain rules when writing signatures.  See the [docs](#docs) for more info.*

Next, run `pyml_bindgen` on the signatures file to generate an OCaml module with [pyml](https://github.com/thierry-martinez/pyml) bindings.  The [ocamlformat](https://github.com/ocaml-ppx/ocamlformat) command is optional, of course.

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

As you see, it generated an OCaml module called `Silly`.  Now, you can use `Lib.Silly` like any other OCaml module, but it will be running Python under the hood.  Just don't forget to initialize the Python interpreter first.

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

*Note: You don't need to use [Base](TODO); I just like it.*

Oh, and don't forget your [Dune](TODO) file either...

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

## Docs

I'm still working on them :) But in the meantime, there are [tests](https://github.com/mooreryan/pyml_bindgen/tree/main/test) that demonstrate many of the rules for properly writing signatures.   Check 'em out!

## License

[![license MIT or Apache
2.0](https://img.shields.io/badge/license-MIT%20or%20Apache%202.0-blue)](https://github.com/mooreryan/pasv)

Copyright (c) 2021 Ryan M. Moore.

Licensed under the Apache License, Version 2.0 or the MIT license, at your option. This program may not be copied, modified, or distributed except according to those terms.
