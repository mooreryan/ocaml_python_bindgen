# Handling Python Dictionaries

Let's see how to handle Python `Dictionaries`.  For now, you need to define a module that has a couple of functions.  For now, we will call it `Dict`.  You can use a signature or `mli` file if you want, but to keep it simple, we will leave it out for now.

Stick the following code in a file called `dict.ml`

```ocaml
type t = Pytypes.pyobject

let to_pyobject x = x
let of_pyobject x = x
```

Technically, that would be all you need, but it's not very easy to work with...you would have to create all your own `pyobjects` by hand.  Yuck!

The next thing you need is to decide what kind of interface you want your `Dict.t` to have.  By that I just mean that it would be nice to have a convenient way to get standard "dictionary-like" types into `Dict.t`.  In this tutorial, we will look at three: an association list, and [Base's](https://ocaml.janestreet.com/ocaml-core/latest/doc/base/Base/index.html) `Map` and `Hashtbl`.

Of course, you may want to use something different, and that will work just fine after you see how to do it.

## Write val specs

But first we should look at the Python code we are planning to bind.

`silly_map.py`

```python
def add(d, k, v):
    d[k] = v

def get(d, k):
    return d[k]
```

Just two functions to define a weird little map module: `add` and `get`, both of which take a `dictionary` as their first argument.  The Python dictionary can have pretty much any types for keys and values, but we are going to use it as a `string => string` map.  You should choose whatever types make sense for your particular use case.

Here are the value specs to bind these functions.

```ocaml
val add : d:Dict.t -> k:string -> v:string -> unit -> unit
val get : d:Dict.t -> k:string -> unit -> string
```

## Generate bindings

Now, let's generate our library code.

```
$ pyml_bindgen val_specs.txt silly_map NA \
  --caml-module=Silly_map -a module -r no_check \
  | ocamlformat --enable - --name=x.ml \
  > lib.ml
```

See that weird `NA` in the command?  That's because you currently have to pass in a Python class name, even if you are binding module functions.

The generated OCaml module will be `Silly_map`.  The other flags specify that we want to bind module associated code and not code associated with a class (`-a module`), and that we don't want to check the results of any converting code (`-r no_check`).

*Note:  For more info on `pyml_bindgen` CLI args, see [here](http://localhost:8000/getting-started/#running-pyml_bindgen).

Here's what the generated code looks like:

```ocaml
module Silly_map : sig
  type t

  val of_pyobject : Pytypes.pyobject -> t

  val to_pyobject : t -> Pytypes.pyobject

  val add : d:Dict.t -> k:string -> v:string -> unit -> unit

  val get : d:Dict.t -> k:string -> unit -> string
end = struct
  let filter_opt l = List.filter_map Fun.id l

  let import_module () = Py.Import.import_module "silly_map"

  type t = Pytypes.pyobject

  let of_pyobject pyo = pyo

  let to_pyobject x = x

  let add ~d ~k ~v () =
    let callable = Py.Module.get (import_module ()) "add" in
    let kwargs =
      filter_opt
        [
          Some ("d", Dict.to_pyobject d);
          Some ("k", Py.String.of_string k);
          Some ("v", Py.String.of_string v);
        ]
    in
    ignore @@ Py.Callable.to_function_with_keywords callable [||] kwargs

  let get ~d ~k () =
    let callable = Py.Module.get (import_module ()) "get" in
    let kwargs =
      filter_opt
        [ Some ("d", Dict.to_pyobject d); Some ("k", Py.String.of_string k) ]
    in
    Py.String.to_string
    @@ Py.Callable.to_function_with_keywords callable [||] kwargs
end
```
## Finish the `Dict` module

Okay, now that we know a little more about the Python code and our desired interface for the `Silly_map` module, let's return to the `Dict` module and fill it out.  Here's the whole thing.  Jump down for some explanations.

```ocaml
open! Base

type t = Pytypes.pyobject

let to_pyobject x = x
let of_pyobject x = x

let empty () = Py.Dict.create ()

let of_alist x =
  Py.Dict.of_bindings_map Py.String.of_string Py.String.of_string x
let to_alist x =
  Py.Dict.to_bindings_map Py.String.to_string Py.String.to_string x

let of_map x = of_alist @@ Map.to_alist x
let to_map x = Map.of_alist_exn (module String) @@ to_alist x

let of_hashtbl x = of_alist @@ Hashtbl.to_alist x
let to_hashtbl x = Hashtbl.of_alist_exn (module String) @@ to_alist x

let print_endline x =
  Stdio.print_endline @@ Sexp.to_string_hum
  @@ [%sexp_of: (string * string) list] @@ to_alist x
```

`of_alist` and `to_alist` let us connect the `Dict` module with association lists.

The `Py.Dict.of_bindings_map` function takes two functions used to convert OCaml values to Python values, and the association list.  In this case, we're passing in strings, so we use `Py.String.of_string` to convert an OCaml `string` to a `Pytypes.pyobject`.  The `to_bindings_map` works in an analogous way.

*Note: For more info on writing pyml bindings, check out the [py.mli](https://github.com/thierry-martinez/pyml/blob/master/py.mli) signature file.*

Next, the `of/to_map` and `of/to_hashtbl` functions are pretty simple.  Both `Map` and `Hashtbl` modules have a `of/to_alist` functions.  So, we just call the function to convert to/from an association list, then call the matching `Dict.of/to_alist` function.

Finally, I threw in a printing function that uses [sexp_of](https://github.com/janestreet/ppx_sexp_conv) to convert the `alist` to a sexp, then print it.

## Setup Dune project & run

Now we're ready to set up a Dune project and write a driver to run the generated code.  Save these two files in the same directory in as the other files.

`dune`

```
(executable
 (name run)
 (libraries base pyml stdio)
 (preprocess (pps ppx_jane)))
```

`run.ml`

```ocaml
open! Base
open Lib
open Stdio

let () = Py.initialize ()

let d = Dict.empty ()

let () = Silly_map.add ~d ~k:"apple" ~v:"pie" ()
let () = Silly_map.add ~d ~k:"is" ~v:"good" ()

let () = print_endline @@ Silly_map.get ~d ~k:"apple" ()
let () = print_endline @@ Silly_map.get ~d ~k:"is" ()

(* Another example. *)

let () = print_endline "~~~~~~~~~~~~~~~~~~~~~~~~~~"
let () =
  print_endline
  @@ Silly_map.get ~d:(Dict.of_alist [ ("apple", "pie") ]) ~k:"apple" ()

(* Base.Map *)

let () = print_endline "~~~~~~~~~~~~~~~~~~~~~~~~~~"
let m = Map.of_alist_exn (module String) [ ("apple", "pie") ]
let d = Dict.of_map m
let () = Silly_map.add ~d ~k:"is" ~v:"good" ()
let () = Dict.print_endline d

(* Base.Hashtbl *)

let () = print_endline "~~~~~~~~~~~~~~~~~~~~~~~~~~"
let ht = Hashtbl.of_alist_exn (module String) [ ("apple", "pie") ]
let d = Dict.of_hashtbl ht
let () = Silly_map.add ~d ~k:"is" ~v:"good" ()
let () = Dict.print_endline d
```

Run it like so:

```
$ dune exec ./run.exe
```

If all goes well, you should see some zany output like this:

```
pie
good
~~~~~~~~~~~~~~~~~~~~~~~~~~
pie
~~~~~~~~~~~~~~~~~~~~~~~~~~
((apple pie) (is good))
~~~~~~~~~~~~~~~~~~~~~~~~~~
((apple pie) (is good))
```

## Wrap-up

In this tutorial, we went over a couple of ways to handle Python Dictionaries.  A lot of times, you will need to pass a dictionary to a Python function or return one from a Python function.  Hopefully, you have a good idea of how to do this now!
