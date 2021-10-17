---
main: true
---

# OCaml-Python Bindings Generator

<!-- [![Build and Test](https://github.com/mooreryan/ocaml_python_bindgen/actions/workflows/build_and_test.yml/badge.svg?branch=master)](https://github.com/mooreryan/ocaml_python_bindgen/actions/workflows/build_and_test.yml) [![Build and Test Static](https://github.com/mooreryan/ocaml_python_bindgen/actions/workflows/build_and_test_static.yml/badge.svg?branch=master)](https://github.com/mooreryan/ocaml_python_bindgen/actions/workflows/build_and_test_static.yml) [![Generate Docs](https://github.com/mooreryan/ocaml_python_bindgen/actions/workflows/generate_docs.yml/badge.svg?branch=master)](https://github.com/mooreryan/ocaml_python_bindgen/actions/workflows/generate_docs.yml) -->

<!-- [![code on GitHub](https://img.shields.io/badge/code-GitHub-blue)](https://github.com/mooreryan/ocaml_python_bindgen) [![GitHub issues](https://img.shields.io/github/issues/mooreryan/ocaml_python_bindgen)](https://github.com/mooreryan/ocaml_python_bindgen/issues) [![Coverage Status](https://coveralls.io/repos/github/mooreryan/ocaml_python_bindgen/badge.svg?branch=master)](https://coveralls.io/github/mooreryan/ocaml_python_bindgen?branch=master) -->

Generate Python bindings with [pyml](https://github.com/thierry-martinez/pyml) directly from OCaml value specifications.

While you *could* write all your Python bindings by hand, it can be tedious and it gets old real quick.  While `pyml_bindgen` can't yet auto-generate all the bindings you may need, it can definitely take care of a lot of the tedious and repetitive work you need to do when writing bindings for a big Python library!! 💖

## How to get started

Getting started with a new package or library and going through lots of docs can be frustrating.  Here's the order I would suggest you look at these docs

* Read the installing and quick start sections of this page.
* Then read through the [getting started](getting-started.md) tutorial.  If you only read one page in the docs, make it this one!  It explains most of what you need to know to get started with a simple example, while not getting bogged down in too much details.
* Next, you can either peruse the [rules](todo.md) for writing value specifications that `pyml_bindgen` can understand, or check out [more examples](todo.md).

If you have any questions or issues, please [let me know](https://github.com/mooreryan/ocaml_python_bindgen/issues) about it on GitHub!

## Installing

`pyml_bindgen` is a [Dune](https://dune.readthedocs.io/en/stable/) project, so you *should* be able to clone the repository and build it with `dune` as long as you have the proper dependencies installed 🤞

```
$ git clone https://github.com/mooreryan/pyml_bindgen.git
$ cd pyml_bindgen
$ opam install . --deps-only --with-doc --with-test
$ dune test && dune build --profile=release && dune install
$ pyml_bindgen --help
... help screen should show up ...
```

## Quick start

`pyml_bindgen` is a CLI program that generates OCaml modules that bind Python classes via [pyml](TODO).

Here's a small example.  Take a Python class, `Thing`.  (Put it in a file called `thing.py`...this means the Python module will be called `thing`.)

```python
class Thing:
    def __init__(self, x):
        self.x = x

    def add(self, y):
        return self.x + y
```

Now, look at your Python class and decide how you would like to use this class on the OCaml side.

For now, we will just do a direct translation, keeping in mind the [rules](TODO) for writing value specs that `pyml_bindgen` can process.  Maybe something like this.  (Put it in a file called `val_specs.txt`.)

```ocaml
val __init__ : x:int -> unit -> t

val x : t -> int

val add : t -> y:int -> unit -> int
```

Finally, to generate the OCaml code, run the `pyml_bindgen` program.  There are a couple of options you can choose, but let's just keep it simple for now.

```
$ pyml_bindgen val_specs.txt thing Thing --caml-module=Thing > lib.ml
$ ocamlformat --enable-outside-detected-project lib.ml
```

And here's the output of the `ocamlformat` command.

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
end
```

Check out the [examples](TODO) for more info about using and running `pyml_bindgen`.  Then, check out the [rules](TODO) that you have to follow when writing value specifications that `pyml_bindgen` can read.

## License

### Software

[![license MIT or Apache
2.0](https://img.shields.io/badge/license-MIT%20or%20Apache%202.0-blue)](https://github.com/mooreryan/ocaml_python_bindgen)

Copyright (c) 2021 Ryan M. Moore.

Licensed under the Apache License, Version 2.0 or the MIT license, at your option. This program may not be copied, modified, or distributed except according to those terms.

### Documentation

<a rel="license" href="http://creativecommons.org/licenses/by/4.0/">
<img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by/4.0/88x31.png" />
</a>

Copyright (c) 2021 Ryan M. Moore.

This documentation is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by/4.0/">Creative Commons Attribution 4.0 International License</a>.
