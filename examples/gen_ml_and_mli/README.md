# Splitting generated modules

This example shows how you can use `pyml_bindgen` to generate separate `.ml` and `.mli` files for the implementations and signatures of the generated OCaml modules.

In the `dune` file, you will see two rules, one to generate `ml` and `mli` files for the `Thing` module, and one to generate `ml` and `mli` files for the `Orange` module.

To do so, you need to provide both the `--caml-module` and `--split-caml-module` options.  Something like this:

```bash
$ pyml_bindgen specs.txt thing Thing --caml-module Thing --split-caml-module .
```

`--split-caml-module .` says to generate a `thing.ml` and `thing.mli` file in the current directory.  You can specify a different directory name to put the generated files in a different directory.  E.g., something like `--split-caml-module files/go/here`.
