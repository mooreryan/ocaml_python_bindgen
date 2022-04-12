# Binding Recursive Classes

You will often run into cases in which you need to bind classes that are cyclical.  Here's an example:

```python
class Foo:
    @staticmethod
    def make_bar():
        return Bar()

class Bar:
    @staticmethod
    def make_foo():
        return Foo()
```

`Foo` has a method that returns a `Bar` object, and `Bar` has a method that returns a `Foo` object.

While this works fine in Python, we have to be more explicit in OCaml in these kinds of situations. 

## Auto-generate bindings

As of version `0.4.0-SNAPSHOT`, `pyml_bindgen` ships two helper scripts for dealing with this type of thing automatically: `gen_multi` and `combine_rec_modules`.  Check out the [Recursive Modules](https://github.com/mooreryan/ocaml_python_bindgen/tree/main/examples/recursive_modules) example on GitHub for how to use them.

## Semi-manually generate bindings

The `pyml_bindgen` itself doesn't handle recursive modules.  But it is simple enough to edit the output by hand.  Let's see how.

### Value specs

Since there are two classes to bind, we will make two val spec files.

`foo_val_specs.txt`

```ocaml
val make_bar : unit -> Bar.t
```

`bar_val_specs.txt`

```ocaml
val make_foo : unit -> Foo.t
```

### Run `pyml_bindgen`

Now, run `pyml_bindgen` with some extra shell commands to make the output look nicer.

```
pyml_bindgen foo_val_specs.txt silly Foo --caml-module Foo -r no_check \
  | ocamlformat --enable --name=a.ml - > lib.ml

printf "\n" >> lib.ml

pyml_bindgen bar_val_specs.txt silly Bar --caml-module Bar -r no_check \
  | ocamlformat --enable --name=a.ml - >> lib.ml
```

### Fix the output

If you were to try and compile that code, you'd get a lot of errors including about unknown`Bar` module.

To fix it, change `module Foo : sig` to `module rec Foo : sig` and `module Bar : sig` to `and Bar : sig`.

Once you do that, everything will compile fine :)

Here is what the output should look like:

```ocaml
module rec Foo : sig

... sig ...

end = struct

... impl ...

end

and Bar : sig

... sig ...

end = struct

... impl ...

end
```

### Using the generated modules

You can use the generated modules as you would any others.

```ocaml
open Lib

let () = Py.initialize ()

let (_bar : Bar.t) = Foo.make_bar ()
let (_foo : Foo.t) = Bar.make_foo ()
```

## Wrap-up

You may come across cyclic classes when binding Python code.  If you want to bind them in OCaml as it, you will need to use recursive module.  This page shows you how to do it semi-manually using `pyml_bindgen`.  If you would like a more automatic way to do this, see the [Recursive Modules](https://github.com/mooreryan/ocaml_python_bindgen/tree/main/examples/recursive_modules) example on GitHub.
