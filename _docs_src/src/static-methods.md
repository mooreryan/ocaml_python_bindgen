# Class & Static Methods

Value specs for class/static methods look like this:

```ocaml
val f : a:'a -> ?b:'b -> ... -> unit -> 'c
```

## Rules

* The final function argument (penultimate type expression) must be `unit`.
* The return type can be any of the types mentioned [above](#allowed-types).
* The remaining function arguments must either be named or optional.  The types of these arguments can be any of the types mentioned [above](#allowed-types).

## Examples

```ocaml
val add_item : fruit:string -> price:float -> unit -> unit
val subtract : x:int -> ?y:int -> unit -> int
```

## Binding `__init__`

TODO
