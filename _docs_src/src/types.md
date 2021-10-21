# Types

Not all OCaml types are allowed.  

There are a lot of [tests](https://github.com/mooreryan/pyml_bindgen/tree/main/test) that exercise the rules here.

## Function arguments

For function arguments, you can use

* `float`
* `string`
* `bool`
* `t` (i.e., the main type of the current module)
* Other module types (e.g., `Span.t`, `Doc.t`, `Apple_pie.t`)
* Arrays of any of the above types
* Lists of any of the above types
* Seq.t of any of the above types
* `'a option`, `'a option array`, `'a option list`, `'a option Seq.t`

## Return types

For return types, you can use all of the above types plus `unit`, and `'a Or_error.t` for types `'a` other than `unit`.  However, you cannot use `unit array`, `unit list`, or `unit Seq.t`.  This is because I haven't decided the best way to handle `unit` and `None` (that's Python's `None`) quite yet!

## Nesting

Note: currently, you're not allowed to have **nested** `array`, `list`, `Seq.t`, or `Or_error.t`.  If you need them, you will have to bind those functions by hand :)

E.g., `'a array list` will fail.

You are allowed to nest `'a option` in arrays, lists, and `Seq.t`s however.

## Dictionaries

TODO mention the hack for Python dictionaries...

## Tuples

Tuples are a little weird in `pyml_bindgen`.  If you need to pass or return tuples to Python functions, see [here](todo.md).
