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

You are allowed to nest `'a option` in arrays, lists, and `Seq.t`s (e.g., `'a option list`); however, this will not work with `Or_error.t`.

## Dictionaries & Tuples

See [here](dictionaries.md) and [here](dictionaries-2.md) for examples of binding dictionaries.

If you need to pass or return tuples to Python functions, see [here](tuples.md); however, the same ideas apply to tuples as are covered in the above links for dictionaries.

## Placeholders

There are two placeholders you can use: `todo` and `not_implemented`.

If you're binding a large library and you aren't planning on implementing a function, but you want it in the signature for whatever reason, you can use `not_implemented`.  If you are planning to come back and implement a function later, you can use `todo`.

```ocaml
val f : 'a todo
val g : 'a not_implemented
```

These are special in that you can't just use them anywhere, it has to be exactly as above.

The generated functions for the above signatures will be like this:

```ocaml
let f () = failwith "todo: f"
let g () = failwith "not implemented: g"
```

So if a user actually calls these functions, the program will throw.
