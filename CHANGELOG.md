## Unreleased

### Added

* Allow nested module types in val specs (e.g., `Food.Dessert.Apple_pie.t`)
* Allow using `Pytypes.pyobject` and `Py.Object.t` in val specs
* Better error messages when parser or `py_fun` creation fails

### Changed

* Updated docs

### Fixed

* Fix some small `otype` bugs

## 0.2.0 (2022-02-02)

* Allow embedding Python source directly into generated OCaml module with the `--embed-python-source` CLI option.  See this [issue](https://github.com/mooreryan/ocaml_python_bindgen/issues/5) for more info.
* Fix bug in val spec parsing
* Update docs
* Add full examples in the `examples` directory

## 0.1.2 (2021-12-07)

* Use specific `ocamlformat` version for the tests.  See this Opam repository [pull request](https://github.com/ocaml/opam-repository/pull/20162#issuecomment-987010684) for more info.

## 0.1.1 (2021-11-04)

* Update lower bounds for dependencies
* Fix tests to work with BusyBox/Alpine `grep` command

## 0.1.0 (2021-10-31)

Initial release!
