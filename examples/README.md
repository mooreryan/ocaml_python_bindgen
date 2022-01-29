# Examples

In this directory you will find some full examples.  Each example contains

* Value specification files to specify the bindings
* Python code/modules that we want to bind
* Tests that are run whenever you run `dune test` in the source directory
* Automatic generation of OCaml bindings using Dune [rules](https://dune.readthedocs.io/en/stable/dune-files.html#rule)

The auto-generation of bindings is particularly sweet!  If you update any of the spec files, dune will pick up the change and regenerate the OCaml binding code automatically when you run `dune build`!
