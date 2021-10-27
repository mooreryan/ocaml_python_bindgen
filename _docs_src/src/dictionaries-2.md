# Handling Python Dictionaries 2

In the first [article](dictionaries.md) about handling Python dictionaries, we wrote a custom `Dict` module to handle `string => string` dictionaries.

Sometimes when you're binding a large Python project, there will be many different kinds of dictionaries that you need to bind.  Rather than write out a module for each key-value type combination we need, this time let's write some [functors](https://dev.realworldocaml.org/functors.html) to help us cut down on the boilerplate.

*Note:  This isn't an introduction to functors, so I won't be explaining too many of the functor specific details!*

## Python code

First let's check out the Python code we're going to be binding.

`silly.py`

```python
class Inventory:
    def __init__(self, items):
        self.d = items

    def incr(self, item):
        self.d[item] += 1

    def decr(self, item):
        self.d[item] -= 1


class WeirdDict:
    def __init__(self, d):
        self.d = d

    def add(self, k, v):
        self.d[k] = v

    def get(self, k):
        return self.d[k]
```

As you see, both of these classes are polymorphic with respect to the types they can work with.  But for this example, we are going to constrain there types.  We will say `Inventory` is a mapping from strings to integers, and `WeirdDict` is a mapping from integers to string lists.

Here are the value specifications.

`inventory_val_specs.txt`

```
val __init__ : items:String_int_dict.t -> unit -> t option
val d : t -> String_int_dict.t option
val incr : t -> item:string -> unit -> unit
val decr : t -> item:string -> unit -> unit
```

`weird_dict_val_specs.txt`

```
val __init__ : d:Int_string_list_dict.t -> unit -> t option
val d : t -> Int_string_list_dict.t option
val add : t -> k:Int.t -> v:String_list.t -> unit -> unit
val get : t -> k:Int.t -> unit -> String_list.t
```

A couple notable things here.

First, we are putting in some modules that haven't yet been defined: `String_int_dict`, `Int_string_list_dict`, and `String_list`.  We will get to them below.  You may think, yuck, I don't want to have to deal with a custom type `String_list` instead of using `string list`.  Don't worry, it will all work out nicely :)

Second, we're going to be checking the Python class of everything that goes through an `of_pyobject` function.  (Both in the functors we write, and in the `pyml_bindgen` app using `-r option`.)  Most of the previous examples haven't bothered with checking the return types to keep things simple.  Since this example is more involved anyway, let's go ahead and check the types!

## Module types & functors

Now let's write some functors!

*Note that I will be making use of features from [Base](https://ocaml.janestreet.com/ocaml-core/latest/doc/base/Base/index.html) and [ppx_jane](https://github.com/janestreet/ppx_jane) in this example.*

*Put the code in this section into a file called `pyobjectable.ml`.  Don't forget to put `open! Base` at the top!*

### Module types

First we define a module type called `Pyobjectable.S` (`S` for signature), that has a type `t` and two functions, `of_pyobject` and `to_pyobject`.

*Note on naming:  Pyobjectable => Something that can be turned into a pyobject and back.  It's named this way to match the Base naming scheme.*

```ocaml
module type S = sig
  type t

  val of_pyobject : Pytypes.pyobject -> t
  val to_pyobject : t -> Pytypes.pyobject
end
```

We will mint another module type that is specific to lists.

```ocaml
module type S_list = sig
  include module type of List
  type element
  type t = element list
  val of_pyobject : Pytypes.pyobject -> element list
  val to_pyobject : element list -> Pytypes.pyobject
end
```

Next, a module type to describe things that can be used as keys in our dictionaries.

```ocaml
module type S_dict_key = sig
  type t [@@deriving hash, sexp]

  include Comparable.S with type t := t
  include S with type t := t
end
```

The `hash`, `sexp` derives plus including `Comparable.S` allow us to use `S_dict_key` as a key in both `Base.Map` and `Base.Hashtbl` modules.  And of course, we also include `S` because we want it to be pyobjectable.

Finally, we make a `Pydict` module type.  This type will be helpful when converting values into and out of `pyobjects`.

```ocaml
module type Pydict = sig
  type t
  type key
  type value
  type map
  type hashtbl

  val of_pyobject : Pytypes.pyobject -> t option
  val to_pyobject : t -> Pytypes.pyobject

  val of_alist : (key * value) list -> t
  val to_alist : t -> (key * value) list

  val of_map : map -> t
  val to_map : t -> map

  val of_hashtbl : hashtbl -> t
  val to_hashtbl : t -> hashtbl
end
```

In this case, we're saying that we want `Pydicts` to know how to convert to and from `pyobjects`, association lists, `maps`, and `hashtbls`.

Notice how we return `t option` in the `of_pyobject` function.  This way we can be (a little more) sure that the type is correct.  I say a little more because we won't be checking that the types of the keys and values inside the Python dictionary are what we say they are, just that the object is in fact, a Python dictionary.

### Functors

Now let's write two functors that use the above types.

First, a functor to make pyobjectable lists (`S_list`):

```ocaml
module Make_list (Element : S) : S_list with type element := Element.t = struct
  include List
  type t = Element.t list
  let of_pyobject pyo = Py.List.to_list_map Element.of_pyobject pyo
  let to_pyobject l = Py.List.of_list_map Element.to_pyobject l
end
```

Next, a functor to make `Pydicts`.

```ocaml
module Make_pydict (Key : S_dict_key) (Value : S) :
  Pydict
    with type key := Key.t
    with type value := Value.t
    with type map := Value.t Map.M(Key).t
    with type hashtbl := Value.t Hashtbl.M(Key).t = struct
  type t = Pytypes.pyobject

  let of_pyobject x = if Py.Dict.check x then Some x else None
  let to_pyobject x = x

  let of_alist = Py.Dict.of_bindings_map Key.to_pyobject Value.to_pyobject
  let to_alist = Py.Dict.to_bindings_map Key.of_pyobject Value.of_pyobject

  let of_map map = of_alist @@ Map.to_alist map
  let to_map t = Map.of_alist_exn (module Key) @@ to_alist t

  let of_hashtbl ht = of_alist @@ Hashtbl.to_alist ht
  let to_hashtbl t = Hashtbl.of_alist_exn (module Key) @@ to_alist t
end
```

## Making the needed modules

Now that we have our functors, let's make the modules that we specified in the value specs above.

Put the following in a file called `extensions.ml`

```ocaml
open! Base

module Int = struct
  include Int
  let of_pyobject pyo = Py.Int.to_int pyo
  let to_pyobject i = Py.Int.of_int i
end

module String = struct
  include String
  let of_pyobject pyo = Py.String.to_string pyo
  let to_pyobject i = Py.String.of_string i
end

module String_list = Pyobjectable.Make_list (String)
module String_int_dict = Pyobjectable.Make_pydict (String) (Int)
module Int_string_list_dict = Pyobjectable.Make_pydict (Int) (String_list)
```

A couple of notes here:

* We're extending `Int` and `String` modules so that they will be `Pyobjectable`.  This code we need to write by hand because each basic OCaml type has its own special way of converting to and from a `pyobject`.
  * You will note that we didn't have to do anything special to ensure that `Int` was okay to use as a `S_dict_key`.  Since we're using Base, and given the way we wrote the functor, it's all taken care of.
* `String_list` is a "special" list that knows how to turn `string list` values to and from `pyobjects`.
* Finally, we use our extended `Int` and `String` along with `String_list` to make the `*_dict` modules that we put in our val specs.

## Running `pyml_bindgen`

Now that we have all our machinery set up, we're ready to run `pyml_bindgen`.

```
$ printf "open Extensions\n" > lib.ml
$ pyml_bindgen inventory_val_specs.txt silly Inventory --caml-module Inventory \
  | ocamlformat --enable --name=a.ml - >> lib.ml
$ printf "\n" >> lib.ml
$ pyml_bindgen weird_dict_val_specs.txt silly WeirdDict --caml-module Weird_dict \
  | ocamlformat --enable --name=a.ml - >> lib.ml
```

I interspersed some extra code and spaces between the `pyml_bindgen` calls using `printf`.

If you need more explanation of the `pyml_bindgen` options used above, see [here](getting-started.md).

## Set up Dune project & run it

Now we're ready to set up a Dune project and write a driver to run the generated code. Save these two files in the same directory in as the other files.

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
open! Stdio
open! Extensions
open! Lib

let () = Py.initialize ()

let items = String_int_dict.of_alist [ ("apple", 10); ("pie", 3) ]
let items' = String_int_dict.to_alist items
let () = print_s @@ [%sexp_of: (string * int) list] @@ items'

let inventory = Option.value_exn (Inventory.__init__ ~items ())

let () = Inventory.incr inventory ~item:"apple" ()
let () = Inventory.decr inventory ~item:"pie" ()

let () =
  let d = Option.value_exn (Inventory.d inventory) in
  print_s @@ [%sexp_of: (string * int) list] @@ String_int_dict.to_alist d

(* This is the WRONG WAY to do it... *)
let () =
  let pyo = Inventory.to_pyobject inventory in
  match String_int_dict.of_pyobject pyo with
  | Some pyo' ->
      print_s @@ [%sexp_of: (string * int) list]
      @@ String_int_dict.to_alist pyo'
  | None ->
      print_endline
        "Couldn't convert the pyobject to String_int_dict!  Moving on..."


(* Now for the weird dict *)

let d =
  Int_string_list_dict.of_alist
    [ (1, [ "apple"; "pie" ]); (2, [ "is"; "good" ]) ]

let weird = Option.value_exn (Weird_dict.__init__ ~d ())
let () = Weird_dict.add weird ~k:3 ~v:[ "peach"; "cobbler" ] ()

let () =
  assert (
    List.equal String.equal [ "peach"; "cobbler" ]
      (Weird_dict.get weird ~k:3 ()))

let () =
  let d = Option.value_exn (Weird_dict.d weird) in
  let alist = Int_string_list_dict.to_alist d in
  print_s @@ [%sexp_of: (int * string list) list] @@ alist
```

Run it, and if all goes well, you should see something like this:

```
$ dune exec ./run.exe
((apple 10) (pie 3))
((apple 11) (pie 2))
Couldn't convert the pyobject to String_int_dict!  Moving on...
((1 (apple pie)) (2 (is good)) (3 (peach cobbler)))
```

## Wrap-up

In this tutorial, we built upon the [first dictionary tutorial](dictionaries.md) by using functors to avoid having to write the dictionary helper modules by hand.

While you might think functors are overkill for this little example, there are real Python projects that have lots of different dictionaries that you need to use.  For example, [spaCy](https://spacy.io/) has more than 10 different kinds of dictionaries to bind!  Writing all that by hand will get tedious :)
