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

While this works fine in Python, we have to be more explicit in OCaml to use recursive modules. Technically, `pyml_bindgen` doesn't handle recursive modules.  But it is simple enough to edit the output by hand.  Let's see.


## Value specs

Since there are two classes to bind, we will make two val spec files.

`foo_val_specs.txt`

```ocaml
val make_bar : unit -> Bar.t
```

`bar_val_specs.txt`

```ocaml
val make_foo : unit -> Foo.t
```

## Run `pyml_bindgen`

Now, run `pyml_bindgen` with some extra shell commands to make the output look nicer.

```
pyml_bindgen foo_val_specs.txt silly Foo --caml-module Foo -r no_check \
  | ocamlformat --enable --name=a.ml - > lib.ml

printf "\n" >> lib.ml

pyml_bindgen bar_val_specs.txt silly Bar --caml-module Bar -r no_check \
  | ocamlformat --enable --name=a.ml - >> lib.ml
```

## Fix the output

If you were to try and compile that code, you'd get a lot of errors including about unknown`Bar` module.

To fix it, change `module Foo : sig` to `module rec Foo : sig` and `module Bar : sig` to `and Bar : sig`.

Once you do that, everything will compile fine :)

Here is what the output should look like:

```ocaml
module rec Foo : sig
  type t

  val of_pyobject : Pytypes.pyobject -> t

  val to_pyobject : t -> Pytypes.pyobject

  val make_bar : unit -> Bar.t
end = struct
  let filter_opt l = List.filter_map Fun.id l

  let import_module () = Py.Import.import_module "silly"

  type t = Pytypes.pyobject

  let of_pyobject pyo = pyo

  let to_pyobject x = x

  let make_bar () =
    let class_ = Py.Module.get (import_module ()) "Foo" in
    let callable = Py.Object.find_attr_string class_ "make_bar" in
    let kwargs = filter_opt [] in
    Bar.of_pyobject
    @@ Py.Callable.to_function_with_keywords callable [||] kwargs
end

and Bar : sig
  type t

  val of_pyobject : Pytypes.pyobject -> t

  val to_pyobject : t -> Pytypes.pyobject

  val make_foo : unit -> Foo.t
end = struct
  let filter_opt l = List.filter_map Fun.id l

  let import_module () = Py.Import.import_module "silly"

  type t = Pytypes.pyobject

  let of_pyobject pyo = pyo

  let to_pyobject x = x

  let make_foo () =
    let class_ = Py.Module.get (import_module ()) "Bar" in
    let callable = Py.Object.find_attr_string class_ "make_foo" in
    let kwargs = filter_opt [] in
    Foo.of_pyobject
    @@ Py.Callable.to_function_with_keywords callable [||] kwargs
end
```

## Using the generated modules

You can use the generated modules as you would any others.

```ocaml
open Lib

let () = Py.initialize ()

let (_bar : Bar.t) = Foo.make_bar ()
let (_foo : Foo.t) = Bar.make_foo ()
```

## Wrap-up

You may come across cyclic classes when binding Python code.  If you want to bind them in OCaml as it, you will need to use recursive module.  For now, `pyml_bindgen` won't generate them for you automatically, but it is not *too* bad to change them by hand :)
