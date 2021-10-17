# Attributes & Properties

Value specifications that take a single argument `t` will be interpreted as bindings to Python attributes or properties.

Value specs for attributes and properties look like this:

```ocaml
val f : t -> 'a
```

## Rules

* The first and only function argument must be `t`.
* The return type can be any of the types mentioned [above](#allowed-types).

## Examples

```ocaml
val x : t -> int
val name : t -> string
val price : t -> float
```
