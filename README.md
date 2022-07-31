# OCaml-Python Bindings Generator

[![Build and test](https://github.com/mooreryan/ocaml_python_bindgen/actions/workflows/build_and_test.yml/badge.svg?branch=main)](https://github.com/mooreryan/ocaml_python_bindgen/actions/workflows/build_and_test.yml) [![Coverage Status](https://coveralls.io/repos/github/mooreryan/ocaml_python_bindgen/badge.svg?branch=main)](https://coveralls.io/github/mooreryan/ocaml_python_bindgen?branch=main)

Generate Python bindings with [pyml](https://github.com/thierry-martinez/pyml) directly from OCaml value specifications.

While you _could_ write all your Python bindings by hand, it can be tedious and it gets old real quick. While `pyml_bindgen` can't yet auto-generate all the bindings you may need, it can definitely take care of a lot of the tedious and repetitive work you need to do when writing bindings for a big Python library!! 💖

## Quick start

First, install `pyml_bindgen`. It is available on [Opam](https://opam.ocaml.org/packages/pyml_bindgen/).

```
$ opam install pyml_bindgen
```

Say you have a Python class you want to bind and use in OCaml. (Filename: `adder.py`)

```python
class Adder:
    @staticmethod
    def add(x, y):
        return x + y
```

To do so, you write OCaml value specifications for the class and methods you want to bind. (Filename: `val_specs.txt`)

```ocaml
val add : x:int -> y:int -> unit -> int
```

Then, you run `pyml_bindgen`.

```
$ pyml_bindgen val_specs.txt adder Adder --caml-module Adder > lib.ml
```

Now you can use your generated functions in your OCaml code. (Filename: `run.ml`)

```ocaml
open Lib

let () = Py.initialize ()

let result = Adder.add ~x:1 ~y:2 ()

let () = assert (result = 3)
```

Finally, set up a dune file and run it.

```
(executable
 (name run)
 (libraries pyml))
```

```
$ dune exec ./run.exe
```

## Documentation

For information on installing and using `pyml_bindgen`, check out the [docs](https://mooreryan.github.io/ocaml_python_bindgen/).

Additionally, you can find examples in the [examples](https://github.com/mooreryan/ocaml_python_bindgen/tree/main/examples) directory. One neat thing about these examples is that you can see how to write Dune [rules](https://dune.readthedocs.io/en/stable/dune-files.html#rule) to automatically generate your `pyml` bindings.

You may also want to check out my [blog post](https://www.tenderisthebyte.com/blog/2022/04/12/ocaml-python-bindgen/) introducing `pyml_bindgen`.

## Installing from sources

If you want to install from sources, e.g., to track the main branch or a development branch, but you do not want to install all the test and development packages, clone the repository, checkout the branch you want to follow and run opam install manually:

```
$ git clone https://github.com/mooreryan/ocaml_python_bindgen.git
# Checkout whatever branch you want, in this case `dev`.
$ git checkout dev
$ opam install ./pyml_bindgen.opam
```

This will save a lot of install time as it avoids some heavy packages.

## Development

If instead, you want to work on `pyml_bindgen` development, will need to ensure you have the test dependencies, as well as a couple dependencies that are not included in the `opam` file (`core`, `core_bench`, and `bisect_ppx`.)

E.g.,

```
$ git clone https://github.com/mooreryan/ocaml_python_bindgen.git
$ opam install . --deps-only --with-doc --with-test
$ opam install core core_bench core_unix bisect_ppx
$ dune build
```

## License

[![license MIT or Apache
2.0](https://img.shields.io/badge/license-MIT%20or%20Apache%202.0-blue)](https://github.com/mooreryan/pasv)

Copyright (c) 2021 - 2022 Ryan M. Moore.

Licensed under the Apache License, Version 2.0 or the MIT license, at your option. This program may not be copied, modified, or distributed except according to those terms.
