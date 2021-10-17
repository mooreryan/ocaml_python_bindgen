# Types

Not all OCaml types are allowed.  For function arguments, you can use:

* `int`
* `float`
* `string`
* `bool`
* `t` (i.e., the main type of the current module)
* Other module types (e.g., `Span.t`, `Doc.t`, `Apple_pie.t`)
* Lists of any of the above types
* Seq.t of any of the above types

For return types, you can use all of the above types plus `unit`.   You can also return `'a list` and `'a Seq.t` as well.

Additionally, you can return `'a option` and `'a Or_error.t` for certain types `'a`.  Currently, you can only have `t option`, `t Or_error.t`, `<custom> option`, and `<custom> Or_error.t`.  I actually have no idea why I did this...I almost certainly will change it :)

Oh, and one more thing about `unit`...you can't use it with `list` and `Seq.t`.  This is because I haven't decided the best way to handle `unit` and `None` (that's Python's `None`) quite yet!

There are a lot of [tests](https://github.com/mooreryan/pyml_bindgen/tree/main/test) that exercise the rules here.

*Note: currently, you're not allowed to have **nested** `list`, `Seq.t`, `option`, or `Or_error.t`.  If you need them, you will have to bind those functions by hand :)*

## Dictionaries

TODO mention the hack for Python dictionaries...

## Tuples

Tuples are a little weird in `pyml_bindgen`.  If you need to pass or return tuples to Python functions, see [here](todo.md).
