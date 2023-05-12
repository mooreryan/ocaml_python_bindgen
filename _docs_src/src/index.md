---
main: true
---

# OCaml-Python Bindings Generator

<!-- [![Build and Test](https://github.com/mooreryan/ocaml_python_bindgen/actions/workflows/build_and_test.yml/badge.svg?branch=main)](https://github.com/mooreryan/ocaml_python_bindgen/actions/workflows/build_and_test.yml) [![Build and Test Static](https://github.com/mooreryan/ocaml_python_bindgen/actions/workflows/build_and_test_static.yml/badge.svg?branch=main)](https://github.com/mooreryan/ocaml_python_bindgen/actions/workflows/build_and_test_static.yml) [![Generate Docs](https://github.com/mooreryan/ocaml_python_bindgen/actions/workflows/generate_docs.yml/badge.svg?branch=main)](https://github.com/mooreryan/ocaml_python_bindgen/actions/workflows/generate_docs.yml) -->

[![code on GitHub](https://img.shields.io/badge/code-GitHub-blue)](https://github.com/mooreryan/ocaml_python_bindgen)

<!-- [![GitHub issues](https://img.shields.io/github/issues/mooreryan/ocaml_python_bindgen)](https://github.com/mooreryan/ocaml_python_bindgen/issues)  -->

<!-- [![Coverage Status](https://coveralls.io/repos/github/mooreryan/ocaml_python_bindgen/badge.svg?branch=main)](https://coveralls.io/github/mooreryan/ocaml_python_bindgen?branch=main) -->

Generate Python bindings with [pyml](https://github.com/thierry-martinez/pyml) directly from OCaml value specifications.

While you _could_ write all your Python bindings by hand, it can be tedious and it gets old real quick. While `pyml_bindgen` can't yet auto-generate all the bindings you may need, it can definitely take care of a lot of the tedious and repetitive work you need to do when writing bindings for a big Python library!! 💖

## How to get started

Getting started with a new package or library and going through lots of docs can be frustrating. Here's the order I would suggest you look at these docs

- Read the installing and quick start sections of this page.
- Then read through the [getting started](getting-started.md) tutorial. If you only read one page in the docs, make it this one! It explains most of what you need to know to get started with a simple example, while not getting bogged down in too much details.
- Next, check out some working [examples](https://github.com/mooreryan/ocaml_python_bindgen/tree/main/examples) on GitHub.
- Finally, there are some more (potentially) important details in the Rules and Miscellaneous sections of this site.

If you have any questions or issues, please [let me know](https://github.com/mooreryan/ocaml_python_bindgen/issues) about it on GitHub!

_Note: I try to keep this doc updated, but it may sometimes get out-of-sync with the latest `pyml_bindgen`. For the most up-to-date info, see the [examples](https://github.com/mooreryan/ocaml_python_bindgen/tree/main/examples), [tests](https://github.com/mooreryan/ocaml_python_bindgen/tree/main/test), and [dev tests](https://github.com/mooreryan/ocaml_python_bindgen/tree/main/test_dev), which are tested and kept up-to-date under CI._

## Installing

### Using Opam

`pyml_bindgen` is available on [Opam](https://opam.ocaml.org/packages/pyml_bindgen/). You can install it in the normal way:

```bash
$ opam install pyml_bindgen
```

### Installing from sources

If you want to install from sources, e.g., to track the main branch or a development branch, but you do not want to install all the test and development packages, clone the repository, checkout the branch you want to follow and run opam install manually:

```bash
$ git clone https://github.com/mooreryan/ocaml_python_bindgen.git
$ git checkout dev
$ opam install .
```

This will save a lot of install time as it avoids some heavy packages.

### Development

If instead, you want to work on `pyml_bindgen` development, will need to ensure you have the test dependencies, as well as a couple dependencies that are not included in the `opam` file (`core`, `core_bench`, and `bisect_ppx`.)

E.g.,

```bash
$ git clone https://github.com/mooreryan/ocaml_python_bindgen.git
$ opam install . --deps-only --with-doc --with-test
$ opam install core core_bench core_unix bisect_ppx
$ dune build
```

## Quick start

_Note: You can find full examples in the [examples](https://github.com/mooreryan/ocaml_python_bindgen/tree/main/examples) directory on GitHub. One neat thing about the examples there is that you can see how to write Dune [rules](https://dune.readthedocs.io/en/stable/dune-files.html#rule) to automatically generate your `pyml` bindings._

`pyml_bindgen` is a CLI program that generates OCaml modules that bind Python classes via [pyml](https://github.com/thierry-martinez/pyml).

Here's a small example. Take a Python class, `Thing`. (Put it in a file called `thing.py`...this means the Python module will be called `thing`.)

```python
class Thing:
    def __init__(self, x):
        self.x = x

    def add(self, y):
        return self.x + y
```

Now, look at your Python class and decide how you would like to use this class on the OCaml side.

For now, we will just do a direct translation, keeping in mind the rules for writing value specs that `pyml_bindgen` can process. Maybe something like this. (Put it in a file called `val_specs.txt`.)

```ocaml
val __init__ : x:int -> unit -> t

val x : t -> int

val add : t -> y:int -> unit -> int
```

Finally, to generate the OCaml code, run the `pyml_bindgen` program. There are a couple of options you can choose, but let's just keep it simple for now.

```bash
$ pyml_bindgen val_specs.txt thing Thing --caml-module=Thing > lib.ml
```

If you want nicer formatting than that which is generated by `pyml_bindgen`, you can use `ocamlformat`.

```bash
$ ocamlformat --enable-outside-detected-project lib.ml
```

## Next steps

Check out the examples for more info about using and running `pyml_bindgen`. Then, check out the rules that you have to follow when writing value specifications that `pyml_bindgen` can read.

Additionally, you may want to check out this [blog post](https://www.tenderisthebyte.com/blog/2022/04/12/ocaml-python-bindgen/) introducing `pyml_bindgen`.

## License

### Software

[![license MIT or Apache
2.0](https://img.shields.io/badge/license-MIT%20or%20Apache%202.0-blue)](https://github.com/mooreryan/ocaml_python_bindgen)

Copyright (c) 2021 - 2022 Ryan M. Moore.

Licensed under the Apache License, Version 2.0 or the MIT license, at your option. This program may not be copied, modified, or distributed except according to those terms.

### Documentation

<a rel="license" href="http://creativecommons.org/licenses/by/4.0/">
<img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by/4.0/88x31.png" />
</a>

Copyright (c) 2021 - 2022 Ryan M. Moore.

This documentation is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by/4.0/">Creative Commons Attribution 4.0 International License</a>.
