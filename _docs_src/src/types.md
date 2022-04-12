# Types

Not all OCaml types are allowed.

There are a lot of [tests](https://github.com/mooreryan/pyml_bindgen/tree/main/test) that exercise the rules here.

## Function arguments

For function arguments, you can use

- `float`
- `string`
- `bool`
- `t` (i.e., the main type of the current module)
- Other module types (e.g., `Span.t`, `Doc.t`, `Yummy.Apple_pie.t`)
- Arrays of any of the above types
- Lists of any of the above types
- Seq.t of any of the above types
- `'a option`, `'a option array`, `'a option list`, `'a option Seq.t`
- `Pytypes.pyobject` or `Py.Object.t` if you need to deal with `pytypes` directly
- Certain kinds of [tuples](tuples.md)

Note that your custom types must be newly minted modules. E.g.,

```ocaml
(* This is okay *)
module Doc = struct
  type t
  let of_pyobject ...
  let to_pyobject ...
  ...
end

(* But this is not *)
type doc
let doc_of_pyobject ...
let doc_to_pyobject ...
```

## Return types

For return types, you can use all of the above types plus `unit`, and `'a Or_error.t` for types `'a` other than `unit`. However, you cannot use `unit array`, `unit list`, or `unit Seq.t`. 

You can also return many kinds of tuples directly. See [here](tuples.md).

## Nesting

Note: currently, you're not allowed to have **nested** `array`, `list`, `Seq.t`, or `Or_error.t`. If you need them, you will have to bind those functions by hand :)

E.g., `'a array list` will fail.

You are allowed to nest `'a option` in arrays, lists, and `Seq.t`s (e.g., `'a option list`); however, this will not work with `Or_error.t`.

## Pytypes

Sometimes you may want to deal directly with `Pytypes.pyobject` (a.k.a. `Py.Object.t`). 

Maybe you have a Python function that is truly polymorphic, or you just don't feel like giving a function a specific OCaml type for whatever reason. Regardless, you can use `Pytypes.pyobject` or `Py.Object.t` for this. 

Of course, you will be leaking a bit of the `pyml` implementation into your API, but sometimes that is unavoidable, or just more convenient than dealing with it in another way.

Note that you currently are not allowed to nest `pytypes` in any of the containers or monads.

## Tuples

You can handle many kinds of tuples directly. See [here](tuples.md).

## Dictionaries

See [here](dictionaries.md) and [here](dictionaries-2.md) for examples of binding dictionaries.

Alternatively, you could mark them as `Pytypes.pyobject` or `Py.Object.t` and let the caller deal with them in some way.

## Placeholders

There are two placeholders you can use: `todo` and `not_implemented`.

If you're binding a large library and you aren't planning on implementing a function, but you want it in the signature for whatever reason, you can use `not_implemented`. If you are planning to come back and implement a function later, you can use `todo`.

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

So if a user actually calls these functions, the program will fail at runtime.
