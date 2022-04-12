## Unreleased

### Added

- Add helper scripts for binding cyclic Python classes
  - `gen_multi` is a wrapper for `pyml_bindgen` that takes a TSV file of command line specs, and runs `pyml_bindgen` on each of them.
  - `combine_rec_modules` is a small program that takes generated OCaml modules and "converts" them into recursive modules
  - You can combine these two to make it easier to generate recursive modules, which can be useful for binding Python classes that reference each other.
- Add support for `py_arg_name` attribute. It lets you use different argument names in the OCaml bindings than used in the Python functions.
- Add `--split-caml-module` option to split generated module into separate `ml` and `mli` files.

## 0.3.1 (2022-03-23)

### Changed

- Reduce number of dependencies (including when installing from the GitHub repository).
  - Use `re` instead of `re2` for regular expressions.
  - Drop some of the dev dependencies from the `opam` file.

## 0.3.0 (2022-03-18)

### Added

- Allow nested module types in val specs (e.g., `Food.Dessert.Apple_pie.t`)
- Allow using `Pytypes.pyobject` and `Py.Object.t` in val specs
- Better error messages when parser or `py_fun` creation fails
- You can now use attributes on value specifications.
  - Currently the only one available is `py_fun_name`.
  - It allows you to decouple the Python method name and the generated OCaml function name.
  - See the examples directory on GitHub for more info.
- You can now bind tuples with 2, 3, 4, or 5 elements.
  - They can be passed in as arguments, or returned from functions.
  - Only basic types and Python objects are allowed in tuples.
  - You can also put tuples inside of collections, e.g., `(int * string) list`, but not Options or Or_errors.

### Changed

- Updated docs
- Update to dune 3
- Update to cmdliner 1.1

### Fixed

- Fix some small `otype` bugs

## 0.2.0 (2022-02-02)

- Allow embedding Python source directly into generated OCaml module with the `--embed-python-source` CLI option. See this [issue](https://github.com/mooreryan/ocaml_python_bindgen/issues/5) for more info.
- Fix bug in val spec parsing
- Update docs
- Add full examples in the `examples` directory

## 0.1.2 (2021-12-07)

- Use specific `ocamlformat` version for the tests. See this Opam repository [pull request](https://github.com/ocaml/opam-repository/pull/20162#issuecomment-987010684) for more info.

## 0.1.1 (2021-11-04)

- Update lower bounds for dependencies
- Fix tests to work with BusyBox/Alpine `grep` command

## 0.1.0 (2021-10-31)

Initial release!
